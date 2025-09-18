package com.pahul.ingest.api;

import com.pahul.ingest.core.IngestService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/ingest")
public class IngestController {

    private final IngestService service;

    public IngestController(IngestService service) { this.service = service; }

    @PostMapping
    public ResponseEntity<IngestResponse> ingest(
            @Valid @RequestBody IngestRequest req,
            @RequestHeader(value = "X-Idempotency-Key", required = false) String idKey,
            @RequestHeader(value = "X-Correlation-Id", required = false) String corrId
    ) {
        return ResponseEntity.ok(service.process(req, idKey, corrId));
    }


    @PostMapping("/dry-run")
    public ResponseEntity<IngestResponse> ingestDryRun(
            @Valid @RequestBody IngestRequest req,
            @RequestHeader(value = "X-Idempotency-Key", required = false) String idKey,
            @RequestHeader(value = "X-Correlation-Id", required = false) String corrId
    ) {
        String eventId = java.util.UUID.randomUUID().toString();
        return ResponseEntity.ok(new IngestResponse("ACCEPTED", eventId));
    }
}
