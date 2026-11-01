package com.example.quan_ly_xe.modules.doixe_c.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.request.GhiNhanBaoDuongRequest;
import com.example.quan_ly_xe.modules.doixe_c.dto.request.GhiNhanDangKiemRequest;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.GhiNhanBaoDuongResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.GhiNhanDangKiemResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.LichBaoDuongResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.MucDoSanSangXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.ThamSoKyThuatResponse;
import com.example.quan_ly_xe.modules.doixe_c.service.KyThuatService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller kỹ thuật xe (MH04 – UC-014, UC-015) và phần xe của Mức độ sẵn sàng (MH01.0 – UC-001).
 */
@RestController
@RequestMapping("/api/v1/doixe")
public class KyThuatController {

    private final KyThuatService kyThuatService;

    public KyThuatController(KyThuatService kyThuatService) {
        this.kyThuatService = kyThuatService;
    }

    /**
     * MH04.1, MH04.4: lịch bảo dưỡng, đăng kiểm của tất cả xe (vw_LichBaoDuong) + tham số.
     */
    @GetMapping("/lich-bao-duong")
    public ApiResponse<LichBaoDuongResponse> layLichBaoDuong() {
        return ApiResponse.ok(kyThuatService.layLichBaoDuong());
    }

    /**
     * Tham số kỹ thuật (chu kỳ bảo dưỡng, đăng kiểm, ngưỡng cảnh báo, hệ số đường khó) – chỉ đọc.
     */
    @GetMapping("/tham-so")
    public ApiResponse<ThamSoKyThuatResponse> layThamSoKyThuat() {
        return ApiResponse.ok(kyThuatService.layThamSoKyThuat());
    }

    /**
     * UC-001: dòng đăng kiểm xe và dòng cảnh báo bảo dưỡng của khung Mức độ sẵn sàng.
     */
    @GetMapping("/muc-do-san-sang")
    public ApiResponse<MucDoSanSangXeResponse> layMucDoSanSang() {
        return ApiResponse.ok(kyThuatService.layMucDoSanSang());
    }

    /**
     * UC-014: Ghi nhận bảo dưỡng.
     */
    @PostMapping("/bao-duong")
    public ApiResponse<GhiNhanBaoDuongResponse> ghiNhanBaoDuong(@Valid @RequestBody GhiNhanBaoDuongRequest req) {
        return ApiResponse.ok(kyThuatService.ghiNhanBaoDuong(req));
    }

    /**
     * UC-015: Gia hạn đăng kiểm.
     */
    @PostMapping("/dang-kiem")
    public ApiResponse<GhiNhanDangKiemResponse> ghiNhanDangKiem(@Valid @RequestBody GhiNhanDangKiemRequest req) {
        return ApiResponse.ok(kyThuatService.ghiNhanDangKiem(req));
    }
}
