package com.example.quan_ly_xe.modules.cauhinh_a.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * DTO phản hồi dữ liệu lịch loại ngày lưu trong cơ sở dữ liệu (bảng LichLoaiNgay).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LichNgayResponse {
    private Integer id;
    private String maLoaiNgay;
    private String tenLoaiNgay;
    private LocalDate tuNgay;
    private LocalDate denNgay;
    private String moTa;
}
