// SQS-triggered Lambda that receives S3 event notifications.
// For now: logs what it WOULD send to your backend.
// Later: set BACKEND_URL (Terraform var) and it will POST to /ingest.

const https = require("https");
const crypto = require("crypto");
const BACKEND_URL = process.env.BACKEND_URL || "";

function postJson(urlString, body, headers = {}) {
  if (!urlString) return Promise.resolve({ status: "skipped" });
  const u = new URL(urlString);
  const payload = JSON.stringify(body);
  const opts = {
    method: "POST",
    hostname: u.hostname,
    path: u.pathname + u.search,
    port: u.port || 443,
    headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(payload), ...headers },
  };
  return new Promise((resolve, reject) => {
    const req = https.request(opts, (res) => {
      let data = "";
      res.on("data", (c) => (data += c));
      res.on("end", () => resolve({ statusCode: res.statusCode, body: data }));
    });
    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

exports.handler = async (event) => {
  const failures = [];

  for (const record of event.Records || []) {
    const msgId = record.messageId;
    try {
      const s3Event = JSON.parse(record.body);
      for (const r of s3Event.Records || []) {
        const bucket = r.s3.bucket.name;
        const keyEnc = r.s3.object.key;
        const key = decodeURIComponent(keyEnc.replace(/\+/g, " "));
        const versionId = r.s3.object.versionId || null;
        const etag = r.s3.object.eTag || r.s3.object.etag || "";
        const idemKey = crypto.createHash("sha256").update(`${bucket}|${key}|${versionId ?? etag}`).digest("hex");

        const body = { bucket, key, versionId, partner: "UNKNOWN" }; // later: infer partner from key prefix

        if (!BACKEND_URL) {
          console.log("Would POST to backend:", { body, idemKey });
        } else {
          const res = await postJson(BACKEND_URL, body, {
            "X-Idempotency-Key": idemKey,
            "X-Correlation-Id": `s3-${msgId}`,
          });
          if (!res.statusCode || res.statusCode >= 500) throw new Error(`Transient backend error: ${res.statusCode} ${res.body}`);
          if (res.statusCode >= 400 && res.statusCode < 500) {
            console.warn("Permanent backend failure; acknowledging:", res.statusCode, res.body);
          } else {
            console.log("Backend ok:", res.statusCode, res.body);
          }
        }
      }
    } catch (e) {
      console.error("Failed record", msgId, e);
      failures.push({ itemIdentifier: msgId }); // partial batch failure for this SQS message
    }
  }

  return { batchItemFailures: failures };
};
