package com.example.quan_ly_xe.modules.doixe_c.service;

import com.example.quan_ly_xe.common.exception.ErrorCode;
import org.springframework.dao.DataAccessException;

import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

/**
 * Đọc mã THROW của thủ tục C từ lỗi CSDL để service gắn tham số cho câu báo lỗi
 * ({@code Biển số {0} đã tồn tại.}, {@code ... lần gần nhất ({0}).}). Lỗi không cần
 * tham số để {@link com.example.quan_ly_xe.common.exception.GlobalExceptionHandler} xử lý như thường.
 */
final class DoiXeLoiSql {

    private static final DateTimeFormatter DD_MM_YYYY = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private DoiXeLoiSql() {
    }

    static Optional<ErrorCode> maLoi(DataAccessException ex) {
        Throwable cur = ex;
        while (cur != null) {
            if (cur instanceof SQLException sqlEx && sqlEx.getErrorCode() > 0) {
                return ErrorCode.fromSqlCode(String.valueOf(sqlEx.getErrorCode()));
            }
            cur = cur.getCause() == cur ? null : cur.getCause();
        }
        return Optional.empty();
    }

    static String ngay(LocalDate d) {
        return d != null ? d.format(DD_MM_YYYY) : "";
    }
}
