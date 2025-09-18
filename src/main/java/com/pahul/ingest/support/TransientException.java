package com.pahul.ingest.support;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
public class TransientException extends RuntimeException {
    public TransientException(String message, Throwable cause) { super(message, cause); }
    public TransientException(String message) { super(message); }
}
