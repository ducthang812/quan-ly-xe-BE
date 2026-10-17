package com.example.quan_ly_xe.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

/**
 * Bao bì phản hồi thống nhất cho mọi API.
 * <p>
 * Thành công: {@code success = true}, {@code data} chứa dữ liệu.
 * Lỗi: {@code success = false}, {@code error} chứa {@link ErrorResponse}
 * (do {@link com.example.quan_ly_xe.common.exception.GlobalExceptionHandler} dựng).
 *
 * @param <T> kiểu dữ liệu trả về
 */
@Getter
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private final boolean success;
    private final T data;
    private final ErrorResponse error;
    private final LocalDateTime timestamp;

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null, LocalDateTime.now());
    }

    public static ApiResponse<Void> ok() {
        return new ApiResponse<>(true, null, null, LocalDateTime.now());
    }

    public static ApiResponse<Void> fail(ErrorResponse error) {
        return new ApiResponse<>(false, null, error, LocalDateTime.now());
    }
}
