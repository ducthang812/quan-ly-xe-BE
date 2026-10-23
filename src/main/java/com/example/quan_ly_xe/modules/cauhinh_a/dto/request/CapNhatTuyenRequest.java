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
public class CapNhatTuyenRequest {

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
}

