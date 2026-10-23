package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TuyenResponse {
    private String maTuyen;
    private String diemDau;
    private String diemCuoi;
    private Double doDaiKm;
    private Integer capDo;
    private String tenCapDo;
    private Double heSoLuong;
    private Double heSoDuongKho;
    private Double giaThuong;
    private Double giaCuoiTuan;
    private Double giaMuaDL;
    private Double giaLeTet;
}

