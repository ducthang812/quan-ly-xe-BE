package com.example.quan_ly_xe.modules.doixe_c.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * UC-005: Thêm xe kèm đăng kiểm lần đầu (MH01 Tab 3).
 * Năm sản xuất, ngày đăng kiểm, biển số trùng do sp_ThemXeVaDangKiem kiểm tra (E07, E08, E09).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ThemXeRequest {

    @NotBlank(message = "Vui lòng nhập Biển số")
    @Size(max = 15, message = "Biển số tối đa 15 ký tự")
    private String bienSo;

    @NotBlank(message = "Vui lòng chọn Loại xe")
    private String maLoaiXe;

    @NotNull(message = "Vui lòng nhập Năm sản xuất")
    private Integer namSanXuat;

    @NotNull(message = "Vui lòng chọn Ngày đăng kiểm đạt lần đầu")
    private LocalDate ngayDangKiem;
}
