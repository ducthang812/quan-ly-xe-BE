package com.example.quan_ly_xe.modules.doixe_c.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/** Đổi trạng thái xe (SRS 11.2 mục 5): HoatDong / BaoDuong / NgungHD. */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DoiTrangThaiXeRequest {

    @NotBlank(message = "Vui lòng chọn Trạng thái")
    @Pattern(regexp = "^(HoatDong|BaoDuong|NgungHD)$", message = "Trạng thái phải là HoatDong, BaoDuong hoặc NgungHD")
    private String trangThai;
}
