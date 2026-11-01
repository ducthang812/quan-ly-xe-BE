package com.example.quan_ly_xe.modules.doixe_c.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.request.DoiTrangThaiXeRequest;
import com.example.quan_ly_xe.modules.doixe_c.dto.request.ThemXeRequest;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.LoaiXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.ThemXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.XeResponse;
import com.example.quan_ly_xe.modules.doixe_c.service.XeService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller xe và loại xe (MH01 Tab 3 – UC-005, UC-006; danh mục dùng chung giao tiếp #3).
 */
@RestController
@RequestMapping("/api/v1/doixe")
public class XeController {

    private final XeService xeService;

    public XeController(XeService xeService) {
        this.xeService = xeService;
    }

    /**
     * Danh mục loại xe.
     */
    @GetMapping("/loai-xe")
    public ApiResponse<List<LoaiXeResponse>> layDanhSachLoaiXe() {
        return ApiResponse.ok(xeService.layDanhSachLoaiXe());
    }

    /**
     * Danh sách xe (MH01 Tab 3: Mã xe, Biển số, Loại xe, Năm SX, Trạng thái, Hạn đăng kiểm, Số chuyến).
     * maCN trống = chi nhánh của site đang gọi.
     */
    @GetMapping("/xe")
    public ApiResponse<List<XeResponse>> layDanhSachXe(
            @RequestParam(required = false) String maCN,
            @RequestParam(required = false) String trangThai) {
        return ApiResponse.ok(xeService.layDanhSachXe(maCN, trangThai));
    }

    /**
     * UC-005: Thêm xe kèm đăng kiểm lần đầu.
     */
    @PostMapping("/xe")
    public ApiResponse<ThemXeResponse> themXe(@Valid @RequestBody ThemXeRequest req) {
        return ApiResponse.ok(xeService.themXe(req));
    }

    /**
     * UC-006: Xóa xe (E10 nếu xe đã có chuyến).
     */
    @DeleteMapping("/xe/{maXe}")
    public ApiResponse<Void> xoaXe(@PathVariable String maXe) {
        xeService.xoaXe(maXe);
        return ApiResponse.ok();
    }

    /**
     * Đổi trạng thái xe (Mục 11.2 - [CẦN BỔ SUNG]).
     */
    @PatchMapping("/xe/{maXe}/trang-thai")
    public ApiResponse<Void> doiTrangThaiXe(
            @PathVariable String maXe,
            @Valid @RequestBody DoiTrangThaiXeRequest req) {
        xeService.doiTrangThaiXe(maXe, req.getTrangThai());
        return ApiResponse.ok();
    }
}
