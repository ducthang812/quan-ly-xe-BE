package com.example.quan_ly_xe.modules.cauhinh_a.dto.request;

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
public class ThamSoThuLaoRequest {

    @NotNull(message = "Đơn giá mỗi km không được để trống")
    @Positive(message = "Đơn giá mỗi km phải lớn hơn 0")
    private Double donGiaKm;

    @NotNull(message = "Hệ số vai trò lái xe không được để trống")
    @Positive(message = "Hệ số vai trò lái xe phải lớn hơn 0")
    private Double hsLai;

    @NotNull(message = "Hệ số vai trò phụ xe không được để trống")
    @Positive(message = "Hệ số vai trò phụ xe phải lớn hơn 0")
    private Double hsPhu;

    @NotNull(message = "Hệ số lương cấp 1 không được để trống")
    @Positive(message = "Hệ số lương cấp 1 phải lớn hơn 0")
    private Double hsLuongCap1;

    @NotNull(message = "Hệ số lương cấp 2 không được để trống")
    @Positive(message = "Hệ số lương cấp 2 phải lớn hơn 0")
    private Double hsLuongCap2;

    @NotNull(message = "Hệ số lương cấp 3 không được để trống")
    @Positive(message = "Hệ số lương cấp 3 phải lớn hơn 0")
    private Double hsLuongCap3;
}

