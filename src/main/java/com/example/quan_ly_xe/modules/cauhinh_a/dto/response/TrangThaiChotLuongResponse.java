package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Dòng trạng thái chốt lương ở MH05 (sp_KiemTraTrangThaiChotLuong).
 * "BangLuong đang có {n} dòng của tháng {yyyy-MM} (đã chốt)" hoặc "Tháng {yyyy-MM} chưa chốt lương".
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrangThaiChotLuongResponse {
    private String thang;
    private Boolean daChot;
    private Integer soDong;
    private Double tongLuong;
    private LocalDateTime ngayChot;
    private String thongBao;
}

