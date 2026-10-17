package com.example.quan_ly_xe.common.security;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Nhân viên đang thao tác, cung cấp dữ liệu mà nghiệp vụ cần:
 * <ul>
 *   <li>{@code branchCode} – chi nhánh (MaCN), dùng khi INSERT Xe/TaiXe, lọc báo cáo, định tuyến phân tán;</li>
 *   <li>{@code employeeCode} – mã nhân viên (MaNV), ghi vào {@code Ve.MaNVBan} khi bán vé;</li>
 *   <li>{@code role} – vai trò, gợi ý màn hình phù hợp.</li>
 * </ul>
 * Chỉ là ngữ cảnh demo (không xác thực), lấy từ header request hoặc nhân viên mặc định.
 */
@Getter
@AllArgsConstructor
public class CurrentUser {

    private final String employeeCode;
    private final String fullName;
    private final Role role;
    private final String branchCode;

    public boolean isManager() {
        return role == Role.QUAN_LY;
    }

    public boolean hasAnyRole(Role... roles) {
        for (Role r : roles) {
            if (r == role) {
                return true;
            }
        }
        return false;
    }
}
