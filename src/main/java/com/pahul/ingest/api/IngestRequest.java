package com.pahul.ingest.api;

import jakarta.validation.constraints.NotBlank;

public record IngestRequest(
        @NotBlank String bucket,
        @NotBlank String key,
        String versionId,
        @NotBlank String partner,
        String contentType
) {}
