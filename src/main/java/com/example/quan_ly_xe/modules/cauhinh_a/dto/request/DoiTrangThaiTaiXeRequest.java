package com.example.quan_ly_xe.modules.cauhinh_a.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DoiTrangThaiTaiXeRequest {

    @NotBlank(message = "Trạng thái không được để trống")
    @Pattern(regexp = "^(DangLam|NghiViec)$", message = "Trạng thái phải là DangLam hoặc NghiViec")
    private String trangThai;
}

