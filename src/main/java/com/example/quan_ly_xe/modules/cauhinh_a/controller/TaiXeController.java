package com.example.quan_ly_xe.modules.cauhinh_a.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.CapNhatTaiXeRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.DoiTrangThaiTaiXeRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThemTaiXeRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TaiXeResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.service.TaiXeService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller quản lý tài xế (UC-007 - MH01 Tab 4).
 */
@RestController
@RequestMapping("/api/v1/cauhinh/tai-xe")
public class TaiXeController {

    private final TaiXeService taiXeService;

    public TaiXeController(TaiXeService taiXeService) {
        this.taiXeService = taiXeService;
    }

    /**
     * Lấy danh sách tài xế (MH01 Tab 4: Mã TX, Họ tên, Năm sinh, CCCD, Hạng, Số chuyến, Thù lao tháng).
     */
    @GetMapping
    public ApiResponse<List<TaiXeResponse>> layDanhSachTaiXe(
            @RequestParam(required = false) String maCN,
            @RequestParam(required = false) String trangThai,
            @RequestParam(required = false) String thang) {
        return ApiResponse.ok(taiXeService.layDanhSachTaiXe(maCN, trangThai, thang));
    }

    /**
     * Lấy chi tiết 1 tài xế.
     */
    @GetMapping("/{maTX}")
    public ApiResponse<TaiXeResponse> layChiTietTaiXe(
            @PathVariable String maTX,
            @RequestParam(required = false) String thang) {
        return ApiResponse.ok(taiXeService.layChiTietTaiXe(maTX, thang));
    }

    /**
     * UC-007: Thêm tài xế mới (MH01 Tab 4).
     */
    @PostMapping
    public ApiResponse<TaiXeResponse> themTaiXe(@Valid @RequestBody ThemTaiXeRequest req) {
        return ApiResponse.ok(taiXeService.themTaiXe(req));
    }

    /**
     * Sửa thông tin tài xế (Mục 11.2 - [CẦN BỔ SUNG]).
     */
    @PutMapping("/{maTX}")
    public ApiResponse<TaiXeResponse> capNhatTaiXe(
            @PathVariable String maTX,
            @Valid @RequestBody CapNhatTaiXeRequest req) {
        return ApiResponse.ok(taiXeService.capNhatTaiXe(maTX, req));
    }

    /**
     * Đổi trạng thái tài xế DangLam <-> NghiViec (Mục 11.2 - [CẦN BỔ SUNG]).
     */
    @PatchMapping("/{maTX}/trang-thai")
    public ApiResponse<Void> doiTrangThaiTaiXe(
            @PathVariable String maTX,
            @Valid @RequestBody DoiTrangThaiTaiXeRequest req) {
        taiXeService.doiTrangThaiTaiXe(maTX, req.getTrangThai());
        return ApiResponse.ok();
    }
}

