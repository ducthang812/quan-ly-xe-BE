package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** Kết quả UC-015: hạn của lần này và hạn hiện hành (MAX các lần Đạt). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GhiNhanDangKiemResponse {
    private String maXe;
    private String bienSo;
    private String ketQua;
    /** Null khi Không đạt. */
    private LocalDate ngayHetHan;
    private LocalDate hanHienHanh;
    private Integer chuKyThang;
    private Integer tuoiXe;
}
