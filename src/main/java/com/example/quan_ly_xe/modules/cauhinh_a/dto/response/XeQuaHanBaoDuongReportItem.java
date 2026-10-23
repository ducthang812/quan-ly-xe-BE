package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Tab 5: Xe quá hạn bảo dưỡng (MH05 - sp_R06).
 * Cột: Mã xe, Biển số, Loại xe, Chi nhánh, Ngày Đưa vào SD, Ngày bảo dưỡng gần nhất, Km làm việc (F10), Hạn bảo dưỡng tiếp theo (F11), Số ngày quá hạn.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class XeQuaHanBaoDuongReportItem {
    private String maXe;
    private String bienSo;
    private String tenLoaiXe;
    private String maCN;
    private String tenCN;
    private LocalDate ngayDuaVaoSD;
    private LocalDate ngayBaoDuongGanNhat;
    private Double kmLamViec;
    private LocalDate ngayBaoDuongTiepTheo;
    private Integer soNgayQuaHan;
}

