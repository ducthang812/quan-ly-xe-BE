package com.example.quan_ly_xe.modules.vanhanh_b.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class SellTicketRequest {
    @NotBlank private String maChuyen;
    private Integer soGhe;
    @NotBlank private String hoTen;
    private String soDienThoai;
    private String cccd;
    private String email;
}
