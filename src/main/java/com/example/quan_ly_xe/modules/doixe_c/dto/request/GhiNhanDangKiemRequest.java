package com.example.quan_ly_xe.modules.doixe_c.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** UC-015: Gia hạn đăng kiểm (MH04.3). Ngày, chi phí do sp_GhiNhanDangKiem kiểm tra (E09, E31). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GhiNhanDangKiemRequest {

    @NotBlank(message = "Vui lòng chọn Xe")
    private String maXe;

    @NotNull(message = "Vui lòng chọn Ngày đăng kiểm")
    private LocalDate ngayDangKiem;

    @NotBlank(message = "Vui lòng chọn Kết quả")
    @Pattern(regexp = "^(Dat|KhongDat)$", message = "Kết quả phải là Dat hoặc KhongDat")
    private String ketQua;

    private Double chiPhi;
}
