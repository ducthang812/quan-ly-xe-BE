package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** Kết quả UC-005: mã xe tự sinh và hạn đăng kiểm đầu tiên (F12, F13). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ThemXeResponse {
    private String maXe;
    private String bienSo;
    private LocalDate hanDangKiem;
    private Integer chuKyThang;
    private Integer tuoiXe;
}
