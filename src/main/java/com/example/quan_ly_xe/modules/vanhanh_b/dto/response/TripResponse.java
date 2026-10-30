package com.example.quan_ly_xe.modules.vanhanh_b.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TripResponse {
    private String maChuyen;
    private String maTuyen;
    private String tenTuyen;
    private BigDecimal doDaiKm;
    private String maXe;
    private String bienSo;
    private LocalDateTime gioKhoiHanhDK;
    private LocalDateTime gioDenDK;
    private LocalDateTime gioKhoiHanhTT;
    private LocalDateTime gioDenTT;
    private Integer kmThucTe;
    private BigDecimal chiPhiVanHanh;
    private String maTXLai;
    private String tenTXLai;
    private BigDecimal thuLaoLai;
    private String maTXPhu;
    private String tenTXPhu;
    private BigDecimal thuLaoPhu;
    private Integer daBan;
    private Integer soCho;
    private String trangThai;
}
