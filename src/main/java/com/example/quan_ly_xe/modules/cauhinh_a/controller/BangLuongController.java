package com.example.quan_ly_xe.modules.cauhinh_a.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ChotLuongRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.BangLuongResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TrangThaiChotLuongResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.service.BangLuongService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller quản lý chốt lương và tra cứu bảng lương (UC-017).
 */
@RestController
@RequestMapping({"/api/v1/cauhinh/bang-luong", "/api/v1/bang-luong"})
public class BangLuongController {

    private final BangLuongService bangLuongService;

    public BangLuongController(BangLuongService bangLuongService) {
        this.bangLuongService = bangLuongService;
    }

    /**
     * Dòng trạng thái chốt lương của tháng (MH05 - sp_KiemTraTrangThaiChotLuong).
     */
    @GetMapping("/trang-thai")
    public ApiResponse<TrangThaiChotLuongResponse> kiemTraTrangThaiChotLuong(
            @RequestParam(required = false) String thang,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(bangLuongService.kiemTraTrangThaiChotLuong(thang, maCN));
    }

    /**
     * Chốt lương tháng (UC-017 - sp_ChotLuongThang).
     */
    @PostMapping("/chot-luong")
    public ApiResponse<TrangThaiChotLuongResponse> chotLuongThang(@Valid @RequestBody ChotLuongRequest request) {
        return ApiResponse.ok(bangLuongService.chotLuongThang(request.getThang(), request.getMaCN()));
    }

    /**
     * Danh sách bảng lương đã chốt.
     */
    @GetMapping
    public ApiResponse<List<BangLuongResponse>> layDanhSachBangLuong(
            @RequestParam(required = false) String thang,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(bangLuongService.layDanhSachBangLuong(thang, maCN));
    }
}

