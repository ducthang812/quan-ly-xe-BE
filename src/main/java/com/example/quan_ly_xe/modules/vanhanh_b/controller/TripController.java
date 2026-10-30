package com.example.quan_ly_xe.modules.vanhanh_b.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.CreateTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.FinishTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SeatMapResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TripPreviewResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TripResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.service.TripService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/vanhanh/chuyen-xe")
public class TripController {
    private final TripService service;

    public TripController(TripService service) { this.service = service; }

    @GetMapping
    public ApiResponse<List<TripResponse>> findAll(@RequestParam(required = false) String trangThai,
            @RequestParam(required = false) String maCN,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate tuNgay,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate denNgay) {
        return ApiResponse.ok(service.findAll(trangThai, maCN, tuNgay, denNgay));
    }

    @GetMapping("/{maChuyen}")
    public ApiResponse<TripResponse> findById(@PathVariable String maChuyen) {
        return ApiResponse.ok(service.findById(maChuyen));
    }

    @GetMapping("/xem-truoc")
    public ApiResponse<TripPreviewResponse> preview(@RequestParam String maTuyen,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime gioKhoiHanh,
            @RequestParam(required = false) String maTXLai,
            @RequestParam(required = false) String maTXPhu) {
        return ApiResponse.ok(service.preview(maTuyen, gioKhoiHanh, maTXLai, maTXPhu));
    }

    @PostMapping
    public ApiResponse<String> create(@Valid @RequestBody CreateTripRequest request) {
        return ApiResponse.ok(service.create(request));
    }

    @PostMapping("/{maChuyen}/huy")
    public ApiResponse<String> cancel(@PathVariable String maChuyen) {
        return ApiResponse.ok(service.cancel(maChuyen));
    }

    @PostMapping("/{maChuyen}/ket-thuc")
    public ApiResponse<String> finish(@PathVariable String maChuyen,
                                      @Valid @RequestBody FinishTripRequest request) {
        return ApiResponse.ok(service.finish(maChuyen, request));
    }

    @GetMapping("/{maChuyen}/so-do-ghe")
    public ApiResponse<SeatMapResponse> seatMap(@PathVariable String maChuyen) {
        return ApiResponse.ok(service.seatMap(maChuyen));
    }
}
