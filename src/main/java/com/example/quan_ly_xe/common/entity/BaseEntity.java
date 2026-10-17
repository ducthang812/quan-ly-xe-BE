package com.example.quan_ly_xe.common.entity;

import com.example.quan_ly_xe.common.util.Constant;
import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * Lớp cơ sở cho mọi entity nghiệp vụ.
 * <p>
 * Chỉ chứa 2 cột kiểm toán kỹ thuật ({@code NgayTao}, {@code NgayCapNhat}) được
 * Spring Data JPA tự điền. Khóa chính KHÔNG đặt ở đây vì hầu hết bảng trong SRS
 * dùng khóa tự nhiên dạng chuỗi do nghiệp vụ sinh (MaXe, MaTuyen, MaChuyen, MaVe...),
 * mỗi người (A/B/C) tự khai báo {@code @Id} cho bảng của mình.
 * <p>
 * Dùng chung: entity của A, B, C chỉ cần {@code extends BaseEntity} là có sẵn
 * cột kiểm toán và cơ chế auditing (đã bật ở {@code JpaAuditingConfig}).
 */
@Getter
@Setter
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {

    @CreatedDate
    @Column(name = Constant.Column.NGAY_TAO, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = Constant.Column.NGAY_CAP_NHAT)
    private LocalDateTime updatedAt;
}
