package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** Kết quả UC-014: hạn bảo dưỡng mới sau khi ghi nhận (km làm việc về 0). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GhiNhanBaoDuongResponse {
    private String maXe;
    private String bienSo;
    private String trangThai;
    private LocalDate ngayBaoDuong;
    private Double kmLamViec;
    private LocalDate ngayBDTiepTheo;
}
