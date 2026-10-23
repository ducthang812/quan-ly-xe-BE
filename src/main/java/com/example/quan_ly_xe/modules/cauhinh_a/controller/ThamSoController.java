package com.example.quan_ly_xe.modules.cauhinh_a.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThamSoBaoDuongRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThamSoThuLaoRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.CauHinhTongHopResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.service.ThamSoService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller quản lý tham số hệ thống (UC-002 - MH01 Tab 1).
 */
@RestController
@RequestMapping("/api/v1/cauhinh/tham-so")
public class ThamSoController {

    private final ThamSoService thamSoService;

    public ThamSoController(ThamSoService thamSoService) {
        this.thamSoService = thamSoService;
    }

    /**
     * Lấy toàn bộ tham số, hệ số độ phức tạp và lịch ngày phục vụ MH01 Tab 1.
     */
    @GetMapping
    public ApiResponse<CauHinhTongHopResponse> layCauHinhTongHop() {
        return ApiResponse.ok(thamSoService.layCauHinhTongHop());
    }

    /**
     * UC-002: Lưu tham số thù lao (MH01 Tab 1).
     */
    @PutMapping("/thu-lao")
    public ApiResponse<Void> capNhatThamSoThuLao(@Valid @RequestBody ThamSoThuLaoRequest req) {
        thamSoService.capNhatThamSoThuLao(req);
        return ApiResponse.ok();
    }

    /**
     * UC-002: Lưu tham số bảo dưỡng và đăng kiểm (MH01 Tab 1).
     */
    @PutMapping("/bao-duong-dang-kiem")
    public ApiResponse<Void> capNhatThamSoBaoDuong(@Valid @RequestBody ThamSoBaoDuongRequest req) {
        thamSoService.capNhatThamSoBaoDuong(req);
        return ApiResponse.ok();
    }
}

