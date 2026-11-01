package com.example.quan_ly_xe.modules.vanhanh_b.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class SeatMapResponse {
    private String maChuyen;
    private String maTuyen;
    private String tenTuyen;
    private String maXe;
    private String bienSo;
    @JsonProperty("gioKhoiHanhDK") private LocalDateTime gioKhoiHanhDK;
    private String maLoaiNgay;
    private BigDecimal giaVe;
    private List<SeatItem> danhSachGhe;
}
