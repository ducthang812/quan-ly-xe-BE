package com.example.quan_ly_xe.common.exception;

import com.example.quan_ly_xe.common.util.Constant.ErrorMessage;
import com.example.quan_ly_xe.common.util.Constant.ThrowCode;
import org.springframework.http.HttpStatus;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Danh mục thông báo lỗi E01–E32 theo mục 10 của SRS.
 * <p>
 * Đây là <b>hợp đồng dùng chung</b> (chốt ở Sprint 0) giữa A, B, C: tầng CSDL
 * (SQL Server) phát lỗi bằng ràng buộc (CK/UQ/FK/PK) hoặc {@code THROW} với mã
 * lỗi 5 chữ số ({@literal >=} 50000); tầng BE bắt lại và trả câu tiếng Việt
 * tương ứng, không lộ nguyên văn lỗi SQL (xem {@link GlobalExceptionHandler}).
 * <p>
 * Khi thêm trigger/thủ tục mới sinh mã lỗi, B bổ sung mã SQL vào đây để giữ
 * một nguồn ánh xạ duy nhất. Thông điệp có thể chứa tham số dạng {@code {0}}
 * điền lúc chạy qua {@link AppException}.
 */
public enum ErrorCode {

    // ── Lỗi định dạng / nhập liệu (kiểm ở FE, BE kiểm lại khi cần) ──────────────
    E01(HttpStatus.BAD_REQUEST, ErrorMessage.E01_VI, ErrorMessage.E01_EN),
    E02(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E02_VI, ErrorMessage.E02_EN),
    E03(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E03_VI, ErrorMessage.E03_EN),
    E04(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E04_VI, ErrorMessage.E04_EN),
    E05(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E05_VI, ErrorMessage.E05_EN),
    E06(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E06_VI, ErrorMessage.E06_EN, ThrowCode.N57001),
    E07(HttpStatus.CONFLICT, ErrorMessage.E07_VI, ErrorMessage.E07_EN),
    E08(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E08_VI, ErrorMessage.E08_EN),
    E09(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E09_VI, ErrorMessage.E09_EN, ThrowCode.N58001, ThrowCode.N59001),
    E10(HttpStatus.CONFLICT, ErrorMessage.E10_VI, ErrorMessage.E10_EN),
    E11(HttpStatus.BAD_REQUEST, ErrorMessage.E11_VI, ErrorMessage.E11_EN),
    E12(HttpStatus.CONFLICT, ErrorMessage.E12_VI, ErrorMessage.E12_EN),
    E13(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E13_VI, ErrorMessage.E13_EN),

    // ── Tạo chuyến và phân công (TR03–TR05, sp_TaoChuyenVaPhanCong) ─────────────
    E14(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E14_VI, ErrorMessage.E14_EN, ThrowCode.N53001),
    E15(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E15_VI, ErrorMessage.E15_EN, ThrowCode.N50401),
    E16(HttpStatus.CONFLICT, ErrorMessage.E16_VI, ErrorMessage.E16_EN, ThrowCode.N50402),
    E17(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E17_VI, ErrorMessage.E17_EN, ThrowCode.N50403),
    E18(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E18_VI, ErrorMessage.E18_EN, ThrowCode.N50404),
    E19(HttpStatus.CONFLICT, ErrorMessage.E19_VI, ErrorMessage.E19_EN, ThrowCode.N50302),
    E20(HttpStatus.CONFLICT, ErrorMessage.E20_VI, ErrorMessage.E20_EN),
    E21(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E21_VI, ErrorMessage.E21_EN, ThrowCode.N50601),

    // ── Bán vé (TR01, TR02, sp_BanVe) ──────────────────────────────────────────
    E22(HttpStatus.BAD_REQUEST, ErrorMessage.E22_VI, ErrorMessage.E22_EN),
    E23(HttpStatus.BAD_REQUEST, ErrorMessage.E23_VI, ErrorMessage.E23_EN),
    E24(HttpStatus.CONFLICT, ErrorMessage.E24_VI, ErrorMessage.E24_EN, ThrowCode.N51003),
    E25(HttpStatus.CONFLICT, ErrorMessage.E25_VI, ErrorMessage.E25_EN,
            ThrowCode.N51001, ThrowCode.N51002, ThrowCode.N50102),
    E26(HttpStatus.CONFLICT, ErrorMessage.E26_VI, ErrorMessage.E26_EN, ThrowCode.N50101, ThrowCode.N50103),
    E27(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E27_VI, ErrorMessage.E27_EN, ThrowCode.N50201),

    // ── Bảo dưỡng / đăng kiểm (sp_GhiNhanBaoDuong) ─────────────────────────────
    E28(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E28_VI, ErrorMessage.E28_EN, ThrowCode.N55001),
    E29(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E29_VI, ErrorMessage.E29_EN, ThrowCode.N55002),
    E30(HttpStatus.CONFLICT, ErrorMessage.E30_VI, ErrorMessage.E30_EN),
    E31(HttpStatus.UNPROCESSABLE_CONTENT, ErrorMessage.E31_VI, ErrorMessage.E31_EN),

    // ── Hạ tầng ────────────────────────────────────────────────────────────────
    E32(HttpStatus.SERVICE_UNAVAILABLE, ErrorMessage.E32_VI, ErrorMessage.E32_EN),

    // Tài nguyên không tồn tại (không nằm trong bảng SRS nhưng BE cần cho REST).
    NOT_FOUND(HttpStatus.NOT_FOUND, ErrorMessage.NOT_FOUND_VI, ErrorMessage.NOT_FOUND_EN),
    // Lỗi không lường trước.
    INTERNAL(HttpStatus.INTERNAL_SERVER_ERROR, ErrorMessage.INTERNAL_VI, ErrorMessage.INTERNAL_EN);

    private final HttpStatus httpStatus;
    private final String messageVi;
    private final String messageEn;
    private final List<String> sqlCodes;

    ErrorCode(HttpStatus httpStatus, String messageVi, String messageEn, String... sqlCodes) {
        this.httpStatus = httpStatus;
        this.messageVi = messageVi;
        this.messageEn = messageEn;
        this.sqlCodes = List.of(sqlCodes);
    }

    public HttpStatus getHttpStatus() {
        return httpStatus;
    }

    public String getMessageVi() {
        return messageVi;
    }

    public String getMessageEn() {
        return messageEn;
    }

    public List<String> getSqlCodes() {
        return sqlCodes;
    }

    // Tra ngược từ mã SIGNAL (ví dụ "50401") về ErrorCode. Dựng một lần, bất biến.
    private static final Map<String, ErrorCode> BY_SQL_CODE;

    static {
        Map<String, ErrorCode> m = new HashMap<>();
        for (ErrorCode ec : values()) {
            for (String code : ec.sqlCodes) {
                m.put(code, ec);
            }
        }
        BY_SQL_CODE = Collections.unmodifiableMap(m);
    }

    /** Tìm ErrorCode theo mã lỗi 5 chữ số của SQL Server (số của lệnh {@code THROW}). */
    public static Optional<ErrorCode> fromSqlCode(String sqlCode) {
        return Optional.ofNullable(BY_SQL_CODE.get(sqlCode));
    }

    /**
     * Dò bất kỳ mã SQL nào đã đăng ký xuất hiện trong chuỗi lỗi (message của
     * SQLException do {@code THROW}). Trả về mã đầu tiên khớp.
     */
    public static Optional<ErrorCode> detectFromMessage(String rawMessage) {
        if (rawMessage == null) {
            return Optional.empty();
        }
        for (Map.Entry<String, ErrorCode> e : BY_SQL_CODE.entrySet()) {
            if (rawMessage.contains(e.getKey())) {
                return Optional.of(e.getValue());
            }
        }
        return Optional.empty();
    }

    public static List<String> allSqlCodes() {
        return Arrays.stream(values()).flatMap(ec -> ec.sqlCodes.stream()).toList();
    }
}
