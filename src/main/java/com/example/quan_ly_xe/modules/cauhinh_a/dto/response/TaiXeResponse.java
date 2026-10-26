package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaiXeResponse {
    private String maTX;
    private String hoDem;
    private String ten;
    private String hoTen;
    private LocalDate ngaySinh;
    private Integer namSinh;
    private String cccd;
    private String soGplx;
    private String hangGplx;
    private String soNha;
    private String phuong;
    private String tinh;
    private String soDienThoai;
    private LocalDate ngayVaoLam;
    private String trangThai;
    private String maCN;
    private String tenCN;
    private Integer soChuyen;
    private Double thuLaoThang;
    /** Cờ phân quyền thao tác: true nếu tài xế thuộc chi nhánh hiện tại (được sửa/đổi trạng thái); false nếu chỉ được xem */
    private Boolean coQuyenThaoTac;
}
