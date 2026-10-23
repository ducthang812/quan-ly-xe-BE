package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Tab 1: Bảng Lương tài xế (MH05 - sp_R01).
 * Cột: Mã TX, Họ tên, Mã CN, Tên CN, Số chuyến lái, Số chuyến phụ, Lương (đ).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LuongTaiXeReportItem {
    private String maTX;
    private String hoDem;
    private String ten;
    private String hoTen;
    private String maCN;
    private String tenCN;
    private Integer soChuyenLai;
    private Integer soChuyenPhu;
    private Double tongLuong;
}

