package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChiNhanhResponse {
    private String maCN;
    private String TenCN;
    private String diaChi;
    private String soDienThoai;
    private String maTruongCN;
    private String tenTruongCN;
}

