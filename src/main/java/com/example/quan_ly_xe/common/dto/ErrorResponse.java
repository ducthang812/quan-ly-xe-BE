package com.example.quan_ly_xe.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;
import java.util.Map;

/**
 * Nội dung lỗi trả về cho client.
 * <ul>
 *   <li>{@code code} – mã lỗi E01–E32 (hoặc NOT_FOUND/INTERNAL);</li>
 *   <li>{@code message} – câu tiếng Việt hiển thị cho người dùng;</li>
 *   <li>{@code messageEn} – câu tiếng Anh tương ứng;</li>
 *   <li>{@code path} – đường dẫn request gây lỗi;</li>
 *   <li>{@code details} – lỗi chi tiết theo từng trường (dùng cho lỗi kiểm tra dữ liệu).</li>
 * </ul>
 */
@Getter
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {

    private final String code;
    private final String message;
    private final String messageEn;
    private final String path;
    private final List<FieldError> details;

    public static ErrorResponse of(String code, String message, String messageEn, String path) {
        return new ErrorResponse(code, message, messageEn, path, null);
    }

    public static List<FieldError> fromFieldMap(Map<String, String> fieldMessages) {
        return fieldMessages.entrySet().stream()
                .map(e -> new FieldError(e.getKey(), e.getValue()))
                .toList();
    }

    /** Lỗi gắn với một trường nhập liệu cụ thể. */
    @Getter
    @AllArgsConstructor
    public static class FieldError {
        private final String field;
        private final String message;
    }
}
