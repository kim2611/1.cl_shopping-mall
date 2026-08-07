package com.shoppingmall.backend.common.exception;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 모든 예외를 RFC 7807 ProblemDetail 형식으로 통일해서 응답한다 - 앱(클라이언트) 쪽에서
 * 에러 파싱 로직이 하나로 고정되도록.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ProblemDetail handleApiException(ApiException ex) {
        ErrorCode code = ex.getErrorCode();
        if (code.getStatus().is5xxServerError()) {
            log.error("ApiException: {}", code, ex);
        }
        return problem(code.getStatus(), code.name(), ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(
                fe -> fieldErrors.put(fe.getField(), fe.getDefaultMessage()));

        ProblemDetail detail = problem(
                ErrorCode.VALIDATION_FAILED.getStatus(),
                ErrorCode.VALIDATION_FAILED.name(),
                ErrorCode.VALIDATION_FAILED.getDefaultMessage());
        detail.setProperty("fieldErrors", fieldErrors);
        return detail;
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ProblemDetail handleUnreadableBody(HttpMessageNotReadableException ex) {
        // 잘못된 JSON(문법 오류, 인코딩 깨짐 등)은 클라이언트 요청 문제라 500이 아니라 400.
        return problem(
                ErrorCode.VALIDATION_FAILED.getStatus(),
                ErrorCode.VALIDATION_FAILED.name(),
                "요청 본문을 읽을 수 없습니다. JSON 형식과 인코딩(UTF-8)을 확인해주세요.");
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return problem(
                ErrorCode.INTERNAL_ERROR.getStatus(),
                ErrorCode.INTERNAL_ERROR.name(),
                ErrorCode.INTERNAL_ERROR.getDefaultMessage());
    }

    private ProblemDetail problem(HttpStatus status, String code, String message) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(status, message);
        detail.setType(URI.create("https://mall.dev/errors/" + code.toLowerCase()));
        detail.setTitle(code);
        return detail;
    }
}
