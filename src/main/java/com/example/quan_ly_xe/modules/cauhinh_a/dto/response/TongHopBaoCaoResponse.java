package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 3 ô số tổng đầu màn hình MH05:
 * 1. Doanh thu tháng (chuyến hoàn thành) - tổng F15
 * 2. Số vé tính doanh thu (vé Đã bán của chuyến Hoàn thành)
 * 3. Tổng lương tài xế - tổng F02
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TongHopBaoCaoResponse {
    private String thang;
    private Double doanhThuThang;
    private Integer soVeTinhDoanhThu;
    private Double tongLuongTaiXe;
}

