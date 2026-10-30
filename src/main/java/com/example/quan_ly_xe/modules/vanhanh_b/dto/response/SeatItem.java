package com.example.quan_ly_xe.modules.vanhanh_b.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class SeatItem {
    private Integer soGhe;
    private Boolean coTheBan;
    private String maVe;
    private Boolean daBan;
}
