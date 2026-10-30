package com.example.quan_ly_xe.common.exception;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.common.dto.ErrorResponse;
import com.example.quan_ly_xe.common.util.Constant;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.dao.TransientDataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.CannotCreateTransactionException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.sql.SQLException;
import java.text.MessageFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Bắt mọi ngoại lệ và trả về {@link ApiResponse} + {@link ErrorResponse} thống nhất.
 * <p>
 * Đây là phần "ánh xạ lỗi" dùng chung: service A/B/C chỉ cần ném {@link AppException}
 * hoặc để ràng buộc/thủ tục CSDL phát lỗi, lớp này lo phần còn lại:
 * <ul>
 *   <li>{@link AppException} → mã + câu tiếng Việt theo {@link ErrorCode};</li>
 *   <li>lỗi Bean Validation ({@code @Valid}) → E01, kèm lỗi từng trường;</li>
 *   <li>lỗi CSDL: đọc mã {@code THROW} (vendor error code), rồi dò trong message,
 *       rồi tên ràng buộc CK/UQ/FK/PK, cuối cùng là E32 (mất kết nối) hoặc INTERNAL.</li>
 * </ul>
 * Mã {@code THROW} và tên ràng buộc được ánh xạ tập trung ở {@link ErrorCode}
 * và {@link #CONSTRAINT_MAP}; thêm trigger/ràng buộc mới chỉ cần sửa 1 nơi.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * Ánh xạ tên ràng buộc (CK/UQ/FK/PK) → mã lỗi, cho các lỗi do ràng buộc khai báo
     * phát ra (không qua THROW). Mục cụ thể đặt trước mục chung (dùng {@code contains}).
     */
    private static final Map<String, ErrorCode> CONSTRAINT_MAP = buildConstraintMap();

    private static Map<String, ErrorCode> buildConstraintMap() {
        Map<String, ErrorCode> m = new LinkedHashMap<>();
        m.put(Constant.ConstraintName.CK_DO_PHUC_TAP_HSDK, ErrorCode.E03);
        m.put(Constant.ConstraintName.CK_TUYEN_DIEM_KHAC_NHAU, ErrorCode.E04);
        m.put(Constant.ConstraintName.CK_TUYEN_DO_DAI, ErrorCode.E05);
        m.put(Constant.ConstraintName.UQ_XE_BIEN_SO, ErrorCode.E07);
        m.put(Constant.ConstraintName.CK_XE_NAM_SX, ErrorCode.E08);
        m.put(Constant.ConstraintName.FK_CHUYEN_XE, ErrorCode.E10);
        m.put(Constant.ConstraintName.UQ_TX_CCCD, ErrorCode.E12);
        m.put(Constant.ConstraintName.CK_TX_TUOI, ErrorCode.E13);
        m.put(Constant.ConstraintName.UQ_PC_CHUYEN_VAI_TRO, ErrorCode.E20);
        m.put(Constant.ConstraintName.PK_BAO_DUONG, ErrorCode.E30);
        m.put(Constant.ConstraintName.CK_BD_CHI_PHI, ErrorCode.E31);
        m.put(Constant.ConstraintName.CK_DK_CHI_PHI, ErrorCode.E31);
        m.put(Constant.ConstraintName.CK_CHUYEN_CHI_PHI, ErrorCode.E31);
        // Chung nhất để cuối: mọi CK về giá/độ phức tạp còn lại coi như giá ≤ 0.
        m.put(Constant.ConstraintName.CK_GIA_GIA_VE, ErrorCode.E02);
        m.put(Constant.ConstraintName.CK_DO_PHUC_TAP_PREFIX, ErrorCode.E02);
        return m;
    }

    // ── Ngoại lệ nghiệp vụ ─────────────────────────────────────────────────────
    @ExceptionHandler(AppException.class)
    public ResponseEntity<ApiResponse<Void>> handleApp(AppException ex, HttpServletRequest req) {
        ErrorCode ec = ex.getErrorCode();
        return build(ec, ex.getMessageVi(), ex.getMessageEn(), req, null);
    }

    // ── Lỗi @Valid trên body ───────────────────────────────────────────────────
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleBodyValidation(MethodArgumentNotValidException ex,
                                                                  HttpServletRequest req) {
        List<ErrorResponse.FieldError> details = ex.getBindingResult().getFieldErrors().stream()
                .map(this::toFieldError)
                .toList();
        return build(ErrorCode.E01, Constant.Message.INVALID_INPUT_VI, Constant.Message.INVALID_INPUT_EN, req, details);
    }

    // ── Lỗi ràng buộc trên tham số (@Validated ở query/path) ───────────────────
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleParamValidation(ConstraintViolationException ex,
                                                                   HttpServletRequest req) {
        List<ErrorResponse.FieldError> details = ex.getConstraintViolations().stream()
                .map(this::toFieldError)
                .toList();
        return build(ErrorCode.E01, Constant.Message.INVALID_INPUT_VI, Constant.Message.INVALID_INPUT_EN, req, details);
    }

    // ── Mất kết nối / không mở được giao dịch → E32 ────────────────────────────
    @ExceptionHandler(CannotCreateTransactionException.class)
    public ResponseEntity<ApiResponse<Void>> handleTransaction(CannotCreateTransactionException ex,
                                                               HttpServletRequest req) {
        log.warn("Không mở được giao dịch tại {}", req.getRequestURI(), ex);
        return build(ErrorCode.E32, null, null, req, null);
    }

    // ── Lỗi từ tầng CSDL ───────────────────────────────────────────────────────
    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ApiResponse<Void>> handleDataAccess(DataAccessException ex, HttpServletRequest req) {
        // Mất kết nối / lỗi tạm thời → E32.
        if (ex instanceof DataAccessResourceFailureException
                || ex instanceof TransientDataAccessException) {
            log.warn("Lỗi kết nối CSDL tại {}", req.getRequestURI(), ex);
            return build(ErrorCode.E32, null, null, req, null);
        }

        String raw = rootMessage(ex);

        // 1) Mã lỗi vendor (số của lệnh THROW trong SQL Server), tin cậy nhất.
        ErrorCode mapped = null;
        SQLException sqlEx = findSqlException(ex);
        if (sqlEx != null && sqlEx.getErrorCode() > 0) {
            mapped = ErrorCode.fromSqlCode(String.valueOf(sqlEx.getErrorCode())).orElse(null);
        }

        // 2) Dò mã THROW trong chuỗi message (phòng khi vendor code không có).
        if (mapped == null) {
            mapped = ErrorCode.detectFromMessage(raw).orElse(null);
        }

        // 3) Tên ràng buộc CK/UQ/FK/PK.
        if (mapped == null && raw != null) {
            for (Map.Entry<String, ErrorCode> e : CONSTRAINT_MAP.entrySet()) {
                if (raw.contains(e.getKey())) {
                    mapped = e.getValue();
                    break;
                }
            }
        }

        if (mapped != null) {
            String argument = sqlMessageArgument(raw, mapped);
            String vi = argument == null ? null : MessageFormat.format(mapped.getMessageVi(), argument);
            String en = argument == null ? null : MessageFormat.format(mapped.getMessageEn(), argument);
            return build(mapped, vi, en, req, null);
        }

        log.error("Lỗi CSDL chưa ánh xạ tại {}: {}", req.getRequestURI(), raw, ex);
        return build(ErrorCode.INTERNAL, null, null, req, null);
    }

    // ── Mọi lỗi còn lại ────────────────────────────────────────────────────────
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleOther(Exception ex, HttpServletRequest req) {
        log.error("Lỗi không mong muốn tại {}", req.getRequestURI(), ex);
        return build(ErrorCode.INTERNAL, null, null, req, null);
    }

    // ── Tiện ích ───────────────────────────────────────────────────────────────
    private ResponseEntity<ApiResponse<Void>> build(ErrorCode ec, String overrideVi, String overrideEn,
                                                     HttpServletRequest req,
                                                     List<ErrorResponse.FieldError> details) {
        String vi = overrideVi != null ? overrideVi : ec.getMessageVi();
        String en = overrideEn != null ? overrideEn : ec.getMessageEn();
        ErrorResponse body = new ErrorResponse(ec.name(), vi, en, req.getRequestURI(), details);
        return ResponseEntity.status(ec.getHttpStatus()).body(ApiResponse.fail(body));
    }

    private ErrorResponse.FieldError toFieldError(FieldError fe) {
        return new ErrorResponse.FieldError(fe.getField(), fe.getDefaultMessage());
    }

    private ErrorResponse.FieldError toFieldError(ConstraintViolation<?> cv) {
        return new ErrorResponse.FieldError(cv.getPropertyPath().toString(), cv.getMessage());
    }

    private SQLException findSqlException(Throwable ex) {
        Throwable cur = ex;
        while (cur != null) {
            if (cur instanceof SQLException sqlEx) {
                return sqlEx;
            }
            cur = cur.getCause() == cur ? null : cur.getCause();
        }
        return null;
    }

    private String rootMessage(Throwable ex) {
        Throwable cur = ex;
        String msg = ex.getMessage();
        while (cur.getCause() != null && cur.getCause() != cur) {
            cur = cur.getCause();
            if (cur.getMessage() != null) {
                msg = cur.getMessage();
            }
        }
        return msg;
    }

    /** Lấy giá trị trong quy ước THROW "mã|giá trị"; lỗi cũ không có dấu | giữ nguyên hành vi. */
    private String sqlMessageArgument(String raw, ErrorCode mapped) {
        if (raw == null) {
            return null;
        }
        int separator = -1;
        for (String sqlCode : mapped.getSqlCodes()) {
            int codeStart = raw.indexOf(sqlCode + "|");
            if (codeStart >= 0) {
                separator = codeStart + sqlCode.length();
                break;
            }
        }
        if (separator < 0 || separator == raw.length() - 1) {
            return null;
        }
        String value = raw.substring(separator + 1).trim();
        int lineBreak = Math.min(indexOrLength(value, '\r'), indexOrLength(value, '\n'));
        value = value.substring(0, lineBreak).trim();
        return value.isEmpty() ? null : value;
    }

    private int indexOrLength(String value, char character) {
        int index = value.indexOf(character);
        return index < 0 ? value.length() : index;
    }
}
