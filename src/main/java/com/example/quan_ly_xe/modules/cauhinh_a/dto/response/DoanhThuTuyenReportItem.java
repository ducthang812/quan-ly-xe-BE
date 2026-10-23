package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Tab 3: Doanh thu theo tuyến (MH05 - sp_R03).
 * Cột: Mã tuyến, Tên tuyến (Điểm đầu - Điểm cuối), Cấp độ, Độ dài (km), Số chuyến, Số vé, Doanh thu (đ), Tỷ lệ (%).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DoanhThuTuyenReportItem {
    private String maTuyen;
    private String tenTuyen;
    private Integer capDo;
    private Double doDaiKm;
    private Integer soChuyen;
    private Integer soVe;
    private Double doanhThu;
    private Double tyLe;
}

