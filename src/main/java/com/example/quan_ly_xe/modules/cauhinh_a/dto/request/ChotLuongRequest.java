package com.example.quan_ly_xe.modules.cauhinh_a.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChotLuongRequest {

    @NotBlank(message = "Tháng chốt lương không được để trống")
    @Pattern(regexp = "^\\d{4}-(0[1-9]|1[0-2])$", message = "Tháng phải có định dạng yyyy-MM (ví dụ: 2025-06)")
    private String thang;

    private String maCN;
}

