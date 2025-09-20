package com.pahul.ingest.core;

import com.pahul.ingest.api.IngestRequest;
import com.pahul.ingest.api.IngestResponse;
import com.pahul.ingest.support.TransientException;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
public class IngestService {

    private final KafkaTemplate<String, byte[]> kafka;

    /** Default to our Confluent topic; override via env INGEST_TOPIC or application.properties */
    @Value("${ingest.topic:ingestion-events}")
    private String topic;

    public IngestService(KafkaTemplate<String, byte[]> kafka) {
        this.kafka = kafka;
    }

    /**
     * Real ingest: publishes to Kafka.
     * @param req   incoming request
     * @param idKey value to use as the event key (falls back to a random UUID)
     * @param corrId correlation id (optional; currently not sent as a Kafka header)
     */
    public IngestResponse process(IngestRequest req, String idKey, String corrId) {
        String eventId = (idKey != null && !idKey.isBlank()) ? idKey : UUID.randomUUID().toString();

        // TODO: later stream from S3 + map full payload
        byte[] payload = ("{\"eventId\":\"" + eventId + "\",\"partner\":\"" + req.partner() + "\"}")
                .getBytes(StandardCharsets.UTF_8);

        try {
            RecordMetadata md = kafka.send(topic, eventId, payload)
                    .get(10, TimeUnit.SECONDS)
                    .getRecordMetadata();
            // md.topic(), md.partition(), md.offset() available if you want to log/return
            return new IngestResponse("PUBLISHED", eventId);
        } catch (Exception e) {
            // Treat as transient so upstream (Lambda) can retry on 5xx
            throw new TransientException("Kafka publish failed", e);
        }
    }

    /**
     * Dry-run: do not publish to Kafka; just acknowledge.
     * Keep a distinct method so the /ingest/dry-run controller can call this directly.
     */
    public IngestResponse dryRun(IngestRequest req, String idKey, String corrId) {
        String eventId = (idKey != null && !idKey.isBlank()) ? idKey : UUID.randomUUID().toString();
        return new IngestResponse("ACCEPTED", eventId);
    }
}
