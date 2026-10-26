package com.example.quan_ly_xe.modules.cauhinh_a.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.ChiNhanhResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LichNgayResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.MucDoSanSangResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.service.DanhMucService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller cung cấp API danh mục dùng chung (Sprint 0) và Mức độ sẵn sàng hệ thống (UC-001 - MH01.0).
 */
@RestController
@RequestMapping("/api/v1/cauhinh/danh-muc")
public class DanhMucController {

    private final DanhMucService danhMucService;

    public DanhMucController(DanhMucService danhMucService) {
        this.danhMucService = danhMucService;
    }

    /**
     * Danh sách chi nhánh (Sprint 0 - Shared Catalog).
     */
    @GetMapping("/chi-nhanh")
    public ApiResponse<List<ChiNhanhResponse>> layDanhSachChiNhanh() {
        return ApiResponse.ok(danhMucService.layDanhSachChiNhanh());
    }

    /**
     * Danh sách lịch loại ngày trực tiếp từ cơ sở dữ liệu.
     */
    @GetMapping("/lich-ngay")
    public ApiResponse<List<LichNgayResponse>> layDanhSachLichNgay(
            @RequestParam(required = false) Integer nam,
            @RequestParam(required = false) Integer thang) {
        return ApiResponse.ok(danhMucService.layDanhSachLichNgay(nam, thang));
    }

    /**
     * UC-001: Mức độ sẵn sàng hệ thống (MH01.0).
     */
    @GetMapping("/muc-do-san-sang")
    public ApiResponse<MucDoSanSangResponse> kiemTraMucDoSanSang() {
        return ApiResponse.ok(danhMucService.kiemTraMucDoSanSang());
    }
}
