package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MucDoSanSangResponse {
    private Double donGiaKm;
    private Double chuKyBd;
    private Double chuKyDkCu;
    private Double chuKyDkMoi;
    private Integer tongSoTuyen;
    private Integer soTuyenThieuGia;
    private Integer soTaiXeDangLam;

    // Các text hiển thị theo F16
    private String textDong1ThamSo;
    private String textDong2Tuyen;
    private boolean hopLeTuyen;
    private String textDong5TaiXe;
}

