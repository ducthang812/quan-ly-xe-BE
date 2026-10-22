package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CauHinhTongHopResponse {
    private Map<String, Double> thamSo;
    private List<DoPhucTapResponse> doPhucTap;
    private List<LichNgayResponse> lichNgay;
}

