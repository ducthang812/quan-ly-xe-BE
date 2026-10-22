package com.example.quan_ly_xe.modules.cauhinh_a.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.CapNhatGiaVeRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.CapNhatTuyenRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThemTuyenRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TuyenResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.service.TuyenDuongService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller quản lý tuyến đường và bảng giá vé (UC-003, UC-004 - MH01 Tab 2).
 */
@RestController
@RequestMapping("/api/v1/cauhinh/tuyen-duong")
public class TuyenDuongController {

    private final TuyenDuongService tuyenDuongService;

    public TuyenDuongController(TuyenDuongService tuyenDuongService) {
        this.tuyenDuongService = tuyenDuongService;
    }

    /**
     * Lấy danh sách tuyến đường kèm giá vé (MH01 Tab 2 & Danh mục dùng chung).
     */
    @GetMapping
    public ApiResponse<List<TuyenResponse>> layDanhSachTuyen(@RequestParam(required = false) String maTuyen) {
        return ApiResponse.ok(tuyenDuongService.layDanhSachTuyen(maTuyen));
    }

    /**
     * Lấy chi tiết 1 tuyến đường.
     */
    @GetMapping("/{maTuyen}")
    public ApiResponse<TuyenResponse> layChiTietTuyen(@PathVariable String maTuyen) {
        return ApiResponse.ok(tuyenDuongService.layChiTietTuyen(maTuyen));
    }

    /**
     * UC-003: Thêm tuyến kèm 4 mức giá vé trong cùng 1 transaction (MH01 Tab 2).
     */
    @PostMapping
    public ApiResponse<TuyenResponse> themTuyenVaGia(@Valid @RequestBody ThemTuyenRequest req) {
        return ApiResponse.ok(tuyenDuongService.themTuyenVaGia(req));
    }

    /**
     * UC-004: Sửa giá vé của 1 tuyến theo loại ngày.
     */
    @PutMapping("/{maTuyen}/gia-ve")
    public ApiResponse<Void> capNhatGiaVe(@PathVariable String maTuyen, @Valid @RequestBody CapNhatGiaVeRequest req) {
        req.setMaTuyen(maTuyen);
        tuyenDuongService.upsertBangGiaVe(req);
        return ApiResponse.ok();
    }

    /**
     * UC-004: Lưu thay đổi giá vé hàng loạt (khi bấm 'Lưu thay đổi giá' ở MH01 Tab 2).
     */
    @PutMapping("/gia-ve/hang-loat")
    public ApiResponse<Void> capNhatGiaVeHangLoat(@Valid @RequestBody List<CapNhatGiaVeRequest> requests) {
        tuyenDuongService.capNhatBangGiaVeHangLoat(requests);
        return ApiResponse.ok();
    }

    /**
     * Sửa thông tin tuyến đường (Mục 11.2 - [CẦN BỔ SUNG]).
     */
    @PutMapping("/{maTuyen}")
    public ApiResponse<Void> capNhatTuyenDuong(@PathVariable String maTuyen, @Valid @RequestBody CapNhatTuyenRequest req) {
        tuyenDuongService.capNhatTuyenDuong(maTuyen, req);
        return ApiResponse.ok();
    }

    /**
     * Xóa tuyến đường (Mục 11.2 - [CẦN BỔ SUNG]).
     */
    @DeleteMapping("/{maTuyen}")
    public ApiResponse<Void> xoaTuyenDuong(@PathVariable String maTuyen) {
        tuyenDuongService.xoaTuyenDuong(maTuyen);
        return ApiResponse.ok();
    }
}

