package com.example.quan_ly_xe.modules.vanhanh_b.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
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
    @NotNull @Positive private Integer kmThucTe;
    @NotNull @PositiveOrZero private BigDecimal chiPhiVanHanh;
}
