package com.example.quan_ly_xe.modules.cauhinh_a.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
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
public class ThemTuyenRequest {

    @NotBlank(message = "Điểm đầu không được để trống")
    private String diemDau;

    @NotBlank(message = "Điểm cuối không được để trống")
    private String diemCuoi;

    @NotNull(message = "Độ dài tuyến không được để trống")
    @Positive(message = "Độ dài tuyến phải lớn hơn 0 km")
    private Double doDaiKm;

    @NotNull(message = "Cấp độ tuyến không được để trống")
    @Min(value = 1, message = "Cấp độ tuyến từ 1 đến 3")
    @Max(value = 3, message = "Cấp độ tuyến từ 1 đến 3")
    private Integer capDo;

    @NotNull(message = "Giá vé ngày thường không được để trống")
    @Positive(message = "Giá vé ngày thường phải lớn hơn 0")
    private Double giaThuong;

    @NotNull(message = "Giá vé cuối tuần không được để trống")
    @Positive(message = "Giá vé cuối tuần phải lớn hơn 0")
    private Double giaCuoiTuan;

    @NotNull(message = "Giá vé mùa du lịch không được để trống")
    @Positive(message = "Giá vé mùa du lịch phải lớn hơn 0")
    private Double giaMuaDL;

    @NotNull(message = "Giá vé lễ tết không được để trống")
    @Positive(message = "Giá vé lễ tết phải lớn hơn 0")
    private Double giaLeTet;
}

