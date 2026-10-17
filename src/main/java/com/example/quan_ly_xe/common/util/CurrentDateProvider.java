package com.example.quan_ly_xe.common.util;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Nguồn "ngày hiện tại" duy nhất của hệ thống.
 * <p>
 * SRS yêu cầu mọi nơi đọc ngày hiện tại từ một hàm chung; prototype cố định
 * {@code 02/06/2025} để khớp dữ liệu mẫu, bản thật dùng ngày hệ thống. A/B/C
 * KHÔNG gọi {@link LocalDate#now()} hay {@code CURDATE()} rải rác, mà tiêm
 * {@code CurrentDateProvider} và gọi {@link #today()} để mọi công thức
 * (F11, F12, F13, F14, F17...) nhất quán và dễ kiểm thử.
 */
public interface CurrentDateProvider {

    /** Ngày hiện tại của hệ thống (đã trừ phần giờ). */
    LocalDate today();

    /** Thời điểm hiện tại (ngày + giờ). */
    LocalDateTime now();
}
