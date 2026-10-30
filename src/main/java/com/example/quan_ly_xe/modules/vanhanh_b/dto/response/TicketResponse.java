package com.example.quan_ly_xe.modules.vanhanh_b.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TicketResponse {
    private String maVe;
    private String hoTen;
    private String soDienThoai;
    private String maChuyen;
    private String maTuyen;
    private String tenTuyen;
    private Integer soGhe;
    private BigDecimal giaVe;
    private LocalDateTime ngayBan;
    private String trangThai;
}
