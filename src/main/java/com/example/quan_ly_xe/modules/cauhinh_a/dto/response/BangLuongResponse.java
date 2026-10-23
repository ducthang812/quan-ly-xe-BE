package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BangLuongResponse {
    private String maTX;
    private String hoTen;
    private String maCN;
    private String tenCN;
    private String thang;
    private Integer soChuyenLai;
    private Integer soChuyenPhu;
    private Double tongLuong;
    private LocalDateTime ngayChot;
}

