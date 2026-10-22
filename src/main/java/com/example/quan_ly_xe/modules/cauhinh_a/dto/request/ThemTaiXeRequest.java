package com.example.quan_ly_xe.modules.cauhinh_a.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ThemTaiXeRequest {

    @NotBlank(message = "Họ đệm không được để trống")
    private String hoDem;

    @NotBlank(message = "Tên không được để trống")
    private String ten;

    @NotNull(message = "Ngày sinh không được để trống")
    private LocalDate ngaySinh;

    @NotBlank(message = "CCCD không được để trống")
    @Pattern(regexp = "^\\d{12}$", message = "CCCD phải gồm đúng 12 chữ số")
    private String cccd;

    @NotBlank(message = "Số GPLX không được để trống")
    private String soGplx;

    @NotBlank(message = "Hạng GPLX không được để trống")
    @Pattern(regexp = "^(D|E|FC)$", message = "Hạng GPLX phải là D, E hoặc FC")
    private String hangGplx;

    private String soNha;
    private String phuong;
    private String tinh;

    @Pattern(regexp = "^(0\\d{9})?$", message = "Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0")
    private String soDienThoai;

    private String maCN;

    private LocalDate ngayVaoLam;
}

