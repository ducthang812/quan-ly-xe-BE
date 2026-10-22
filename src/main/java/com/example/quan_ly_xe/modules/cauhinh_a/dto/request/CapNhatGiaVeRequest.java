package com.example.quan_ly_xe.modules.cauhinh_a.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CapNhatGiaVeRequest {

    @NotBlank(message = "Mã tuyến không được để trống")
    private String maTuyen;

    @NotBlank(message = "Mã loại ngày không được để trống")
    private String maLoaiNgay;

    @NotNull(message = "Giá vé không được để trống")
    @Positive(message = "Giá vé phải lớn hơn 0")
    private Double giaVe;
}

