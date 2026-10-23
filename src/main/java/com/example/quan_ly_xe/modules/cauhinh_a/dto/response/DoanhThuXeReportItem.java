package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Tab 2: Doanh thu theo xe (MH05 - sp_R02).
 * Cột: Mã xe, Biển số, Loại xe, Mã CN, Tên CN, Số chuyến, Số vé, Doanh thu (đ), Tỷ lệ (%).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DoanhThuXeReportItem {
    private String maXe;
    private String bienSo;
    private String tenLoaiXe;
    private String maCN;
    private String tenCN;
    private Integer soChuyen;
    private Integer soVe;
    private Double doanhThu;
    private Double tyLe;
}

