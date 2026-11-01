package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/** Tham số dùng cho khung xem trước và dòng công thức của MH04 (đọc từ ThamSo, DoPhucTap). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ThamSoKyThuatResponse {
    private Integer chuKyBd;
    private Double kmMoiNgayBd;
    private Integer canhBaoNgay;
    private Integer chuKyDkCu;
    private Integer chuKyDkMoi;
    private Integer tuoiXeCu;
    private Double heSoDuongKho1;
    private Double heSoDuongKho2;
    private Double heSoDuongKho3;
}
