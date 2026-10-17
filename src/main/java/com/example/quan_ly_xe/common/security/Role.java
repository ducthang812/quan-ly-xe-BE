package com.example.quan_ly_xe.common.security;

/**
 * Vai trò người dùng theo {@code NhanVien.ChucVu}, tương ứng 4 actor trong SRS.
 * <p>
 * Bản demo không phân quyền chặt (tài liệu đã chốt bỏ đăng nhập/phân quyền), vai
 * trò ở đây chỉ để gợi ý menu/màn hình phù hợp và ghi nhận ai đang thao tác.
 */
public enum Role {

    /** Quản lý chi nhánh – MH01 (Thiết lập) và MH05 (Báo cáo). */
    QUAN_LY("Quản lý chi nhánh"),
    /** Nhân viên điều hành – MH02 (Chuyến xe). */
    NV_DIEU_HANH("Nhân viên điều hành"),
    /** Nhân viên bán vé – MH03 (Bán vé). */
    NV_BAN_VE("Nhân viên bán vé"),
    /** Nhân viên kỹ thuật – MH04 (Kỹ thuật xe). */
    NV_KY_THUAT("Nhân viên kỹ thuật");

    private final String label;

    Role(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    /**
     * Đọc vai trò từ chuỗi (tên enum, không phân biệt hoa thường). Không khớp thì
     * trả về {@code null} để nơi gọi tự quyết định giá trị mặc định.
     */
    public static Role fromCodeOrNull(String code) {
        if (code == null || code.isBlank()) {
            return null;
        }
        try {
            return Role.valueOf(code.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }
}
