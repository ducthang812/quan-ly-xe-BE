package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** Một dòng vw_LichBaoDuong (MH04.1, MH04.4). Tình trạng F14 do FE tính. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LichXeResponse {
    private String maXe;
    private String bienSo;
    private String maLoaiXe;
    private String tenLoaiXe;
    private String maCN;
    private Integer namSanXuat;
    private LocalDate ngayDuaVaoSD;
    private String trangThai;
    /** Lần bảo dưỡng gần nhất; null nếu chưa bảo dưỡng lần nào. */
    private LocalDate ngayBDGanNhat;
    /** Mốc tính F11: ngày bảo dưỡng gần nhất, chưa có thì ngày đưa vào sử dụng. */
    private LocalDate ngayMocBD;
    private Double kmLamViec;
    private LocalDate ngayBDTiepTheo;
    private LocalDate hanDangKiem;
    private LocalDate ngayDKGanNhat;
}
