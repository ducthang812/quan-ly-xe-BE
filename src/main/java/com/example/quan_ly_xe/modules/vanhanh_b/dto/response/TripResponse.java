package com.example.quan_ly_xe.modules.vanhanh_b.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
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
    @JsonProperty("gioKhoiHanhDK") private LocalDateTime gioKhoiHanhDK;
    @JsonProperty("gioDenDK") private LocalDateTime gioDenDK;
    @JsonProperty("gioKhoiHanhTT") private LocalDateTime gioKhoiHanhTT;
    @JsonProperty("gioDenTT") private LocalDateTime gioDenTT;
    private Integer kmThucTe;
    private BigDecimal chiPhiVanHanh;
    @JsonProperty("maTXLai") private String maTXLai;
    @JsonProperty("tenTXLai") private String tenTXLai;
    private BigDecimal thuLaoLai;
    @JsonProperty("maTXPhu") private String maTXPhu;
    @JsonProperty("tenTXPhu") private String tenTXPhu;
    private BigDecimal thuLaoPhu;
    private Integer daBan;
    private Integer soCho;
    private String trangThai;
}
