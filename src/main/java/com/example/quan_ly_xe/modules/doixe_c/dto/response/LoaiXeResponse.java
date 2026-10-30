package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/** Danh mục loại xe (giao tiếp #3). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoaiXeResponse {
    private String maLoaiXe;
    private String tenLoaiXe;
    private Integer soGhe;
}
