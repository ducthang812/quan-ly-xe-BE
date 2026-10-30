package com.example.quan_ly_xe.modules.vanhanh_b.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TripPreviewRequest {
    private String maTuyen;
    private LocalDateTime gioKhoiHanh;
    private String maTXLai;
    private String maTXPhu;
}
