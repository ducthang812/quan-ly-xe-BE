package com.example.quan_ly_xe.modules.vanhanh_b.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class SellTicketRequest {
    @NotBlank private String maChuyen;
    @NotNull private Integer soGhe;
    @NotBlank @Size(max = 100) private String hoTen;
    @NotBlank @Pattern(regexp = "^0\\d{9}$") private String soDienThoai;
    @Pattern(regexp = "^$|^\\d{12}$") private String cccd;
    @Email @Size(max = 100) private String email;
}
