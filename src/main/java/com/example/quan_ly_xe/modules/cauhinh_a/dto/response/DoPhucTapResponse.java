package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DoPhucTapResponse {
    private Integer capDo;
    private String moTa;
    private Double heSoLuong;
    private Double heSoDuongKho;
}

