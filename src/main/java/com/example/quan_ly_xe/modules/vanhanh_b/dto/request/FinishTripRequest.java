package com.example.quan_ly_xe.modules.vanhanh_b.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class FinishTripRequest {
    private LocalDateTime gioKhoiHanhTT;
    private LocalDateTime gioDenTT;
    @NotNull private Integer kmThucTe;
    @NotNull private BigDecimal chiPhiVanHanh;
}
