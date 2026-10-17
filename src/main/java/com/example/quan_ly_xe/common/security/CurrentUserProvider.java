package com.example.quan_ly_xe.common.security;

/**
 * Cổng truy cập nhân viên hiện hành cho A/B/C. Tiêm bean này và gọi {@link #get()}
 * thay vì tự đọc header, để sau này đổi cách lấy người dùng (ví dụ thêm đăng nhập)
 * chỉ cần sửa một nơi.
 */
public interface CurrentUserProvider {

    /** Nhân viên đang thao tác; không bao giờ trả về {@code null} (có user demo mặc định). */
    CurrentUser get();
}
