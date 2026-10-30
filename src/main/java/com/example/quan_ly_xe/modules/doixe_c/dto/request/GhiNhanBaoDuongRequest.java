package com.example.quan_ly_xe.modules.doixe_c.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** UC-014: Ghi nhận bảo dưỡng (MH04.2). Ngày, chi phí do sp_GhiNhanBaoDuong kiểm tra (E28–E31). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GhiNhanBaoDuongRequest {

    @NotBlank(message = "Vui lòng chọn Xe")
    private String maXe;

    @NotNull(message = "Vui lòng chọn Ngày bảo dưỡng")
    private LocalDate ngayBaoDuong;

    private Double chiPhi;

    @Size(max = 200, message = "Nội dung tối đa 200 ký tự")
    private String noiDung;
}
