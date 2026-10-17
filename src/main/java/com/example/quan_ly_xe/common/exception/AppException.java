package com.example.quan_ly_xe.common.exception;

import lombok.Getter;

import java.text.MessageFormat;

/**
 * Ngoại lệ nghiệp vụ dùng chung cho toàn hệ thống.
 * <p>
 * Service của A, B, C ném {@code AppException} với một {@link ErrorCode} (và
 * tham số nếu thông điệp có chỗ {@code {0}}). {@link GlobalExceptionHandler}
 * sẽ chuyển thành phản hồi HTTP + câu tiếng Việt chuẩn, không cần mỗi người
 * tự định dạng lỗi.
 *
 * <pre>{@code
 * throw new AppException(ErrorCode.E07, bienSo);          // Biển số 29B-777.88 đã tồn tại.
 * throw AppException.of(ErrorCode.NOT_FOUND, "chuyến xe"); // Không tìm thấy chuyến xe.
 * }</pre>
 */
@Getter
public class AppException extends RuntimeException {

    private final ErrorCode errorCode;
    private final transient Object[] args;

    public AppException(ErrorCode errorCode, Object... args) {
        super(format(errorCode.getMessageVi(), args));
        this.errorCode = errorCode;
        this.args = args;
    }

    public AppException(ErrorCode errorCode, Throwable cause, Object... args) {
        super(format(errorCode.getMessageVi(), args), cause);
        this.errorCode = errorCode;
        this.args = args;
    }

    public static AppException of(ErrorCode errorCode, Object... args) {
        return new AppException(errorCode, args);
    }

    /** Thông điệp tiếng Việt đã điền tham số. */
    public String getMessageVi() {
        return format(errorCode.getMessageVi(), args);
    }

    /** Thông điệp tiếng Anh đã điền tham số. */
    public String getMessageEn() {
        return format(errorCode.getMessageEn(), args);
    }

    private static String format(String template, Object[] args) {
        if (args == null || args.length == 0) {
            return template;
        }
        return MessageFormat.format(template, args);
    }
}
