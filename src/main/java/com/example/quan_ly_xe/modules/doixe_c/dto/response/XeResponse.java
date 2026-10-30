package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/** Dòng danh sách xe (MH01 Tab 3) – cũng là danh mục xe cho A, B (giao tiếp #3). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class XeResponse {
    private String maXe;
    private String bienSo;
    private String maLoaiXe;
    private String tenLoaiXe;
    private Integer soGhe;
    private Integer namSanXuat;
    private LocalDate ngayDuaVaoSD;
    private String trangThai;
    private String maCN;
    private LocalDate hanDangKiem;
    private Integer soChuyen;
    /** Xe thuộc chi nhánh của site đang thao tác thì mới được xóa / đổi trạng thái. */
    private boolean coQuyenThaoTac;
}
