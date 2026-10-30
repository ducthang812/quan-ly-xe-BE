package com.example.quan_ly_xe.modules.vanhanh_b.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class SellTicketResponse {
    private String maVe;
    private BigDecimal giaVe;
    private Integer lanBan;
}
