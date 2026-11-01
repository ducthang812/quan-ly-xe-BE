package com.example.quan_ly_xe.modules.vanhanh_b.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.SellTicketRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SellTicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.service.TicketService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/vanhanh")
public class TicketController {
    private final TicketService service;

    public TicketController(TicketService service) { this.service = service; }

    @PostMapping("/ve")
    public ApiResponse<SellTicketResponse> sell(@Valid @RequestBody SellTicketRequest request) {
        return ApiResponse.ok(service.sell(request));
    }

    @PostMapping("/ve/{maVe}/huy")
    public ApiResponse<String> cancel(@PathVariable String maVe) {
        return ApiResponse.ok(service.cancel(maVe));
    }

    @GetMapping("/ve/tra-cuu")
    public ApiResponse<List<TicketResponse>> findByPhone(@RequestParam(required = false) String soDienThoai) {
        return ApiResponse.ok(service.findByPhone(soDienThoai));
    }

    @GetMapping("/chuyen-xe/{maChuyen}/ve")
    public ApiResponse<List<TicketResponse>> findByTrip(@PathVariable String maChuyen) {
        return ApiResponse.ok(service.findByTrip(maChuyen));
    }
}
