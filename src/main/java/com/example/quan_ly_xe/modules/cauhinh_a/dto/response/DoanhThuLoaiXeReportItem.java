package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Tab 4: Doanh thu theo loại xe (MH05 - sp_R04).
 * Cột: Mã loại xe, Tên loại xe, Số ghế, Số chuyến, Số vé, Doanh thu (đ), Tỷ lệ (%).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DoanhThuLoaiXeReportItem {
    private String maLoaiXe;
    private String tenLoaiXe;
    private Integer soGhe;
    private Integer soChuyen;
    private Integer soVe;
    private Double doanhThu;
    private Double tyLe;
}

