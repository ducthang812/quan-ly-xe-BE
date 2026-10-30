package com.example.quan_ly_xe.modules.vanhanh_b.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TripPreviewResponse {
    private String maTuyen;
    private String maLoaiNgay;
    private BigDecimal giaVe;
    private LocalDateTime gioDenGoiY;
    private BigDecimal thuLaoLai;
    private BigDecimal thuLaoPhu;
}
