package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

/** MH04: lịch của tất cả xe tại chi nhánh + tham số + ngày hiện tại của hệ thống. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LichBaoDuongResponse {
    private LocalDate ngayHienTai;
    private ThamSoKyThuatResponse thamSo;
    private List<LichXeResponse> xe;
}
