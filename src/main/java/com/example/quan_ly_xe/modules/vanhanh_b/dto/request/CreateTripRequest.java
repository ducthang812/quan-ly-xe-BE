package com.example.quan_ly_xe.modules.vanhanh_b.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class CreateTripRequest {
    @NotBlank private String maTuyen;
    @NotBlank private String maXe;
    @NotNull private LocalDateTime gioKhoiHanh;
    @NotNull private LocalDateTime gioDen;
    @NotBlank private String maLai;
    @NotBlank private String maPhu;
    private String maChuyen;
}
