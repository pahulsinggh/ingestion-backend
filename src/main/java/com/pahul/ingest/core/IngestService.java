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
    @Value("${ingest.topic:cde.wellness.behavioral}")
    private String topic;

    public IngestService(KafkaTemplate<String, byte[]> kafka) {
        this.kafka = kafka;
    }

    public IngestResponse process(IngestRequest req, String idKey, String corrId) {
        String eventId = (idKey != null && !idKey.isBlank()) ? idKey : UUID.randomUUID().toString();

        // TODO: later stream from S3 + map; placeholder payload for now
        byte[] payload = ("{\"eventId\":\"" + eventId + "\",\"partner\":\"" + req.partner() + "\"}")
                .getBytes(StandardCharsets.UTF_8);

        try {
            RecordMetadata md = kafka.send(topic, eventId, payload)
                    .get(10, TimeUnit.SECONDS)
                    .getRecordMetadata();
            return new IngestResponse("PUBLISHED", eventId);
        } catch (Exception e) {
            throw new TransientException("Kafka publish failed", e);
        }
    }
}
