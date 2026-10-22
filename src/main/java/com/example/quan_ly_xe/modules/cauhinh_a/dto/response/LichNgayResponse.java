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
public class LichNgayResponse {
    private LocalDate ngay;
    private String maLoaiNgay;
    private String tenLoaiNgay;
}

