package com.example.quan_ly_xe.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * Bật cơ chế auditing của Spring Data JPA để {@link com.example.quan_ly_xe.common.entity.BaseEntity}
 * tự điền {@code NgayTao} / {@code NgayCapNhat}. Chưa có người dùng (chưa làm
 * authen) nên chỉ audit mốc thời gian, chưa audit người tạo/sửa.
 */
@Configuration
@EnableJpaAuditing
public class JpaAuditingConfig {
}
