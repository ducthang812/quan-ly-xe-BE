package com.example.quan_ly_xe.common.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Hiện thực {@link CurrentDateProvider} điều khiển bằng cấu hình.
 * <p>
 * Đặt {@code app.current-date} trong cấu hình (ví dụ {@code 2025-06-02} cho
 * prototype) để cố định ngày; để trống thì dùng ngày hệ thống thật. Nhờ vậy
 * chuyển giữa prototype và bản thật chỉ cần đổi cấu hình, không sửa code.
 */
@Component
public class ConfigurableCurrentDateProvider implements CurrentDateProvider {

    private static final Logger log = LoggerFactory.getLogger(ConfigurableCurrentDateProvider.class);

    private final LocalDate fixedDate;

    public ConfigurableCurrentDateProvider(
            @Value(Constant.ConfigKey.CURRENT_DATE_EXPR) String configuredDate) {
        this.fixedDate = parse(configuredDate);
        if (fixedDate != null) {
            log.info("Ngày hiện tại được CỐ ĐỊNH ở {} (chế độ prototype).", fixedDate);
        }
    }

    @Override
    public LocalDate today() {
        return fixedDate != null ? fixedDate : LocalDate.now();
    }

    @Override
    public LocalDateTime now() {
        return fixedDate != null ? fixedDate.atTime(LocalTime.now()) : LocalDateTime.now();
    }

    private static LocalDate parse(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return LocalDate.parse(value.trim());
    }
}
