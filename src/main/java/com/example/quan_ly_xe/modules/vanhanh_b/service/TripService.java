package com.example.quan_ly_xe.modules.vanhanh_b.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.CreateTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.FinishTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SeatMapResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TripPreviewResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TripResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.repository.TripSpRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class TripService {
    private final TripSpRepository repository;

    public TripService(TripSpRepository repository) { this.repository = repository; }

    public List<TripResponse> findAll(String trangThai, String maCN, LocalDate tuNgay, LocalDate denNgay) {
        return repository.findAll(trangThai, maCN, tuNgay, denNgay);
    }

    public TripResponse findById(String maChuyen) {
        return repository.findById(maChuyen)
                .orElseThrow(() -> new ResourceNotFoundException("ChuyenXe", maChuyen));
    }

    public TripPreviewResponse preview(String maTuyen, LocalDateTime gioKhoiHanh,
                                       String maTXLai, String maTXPhu) {
        return repository.preview(maTuyen, gioKhoiHanh, maTXLai, maTXPhu)
                .orElseThrow(() -> new ResourceNotFoundException("Tuyen", maTuyen));
    }

    @Transactional
    public String create(CreateTripRequest request) {
        if (request.getMaLai() != null && request.getMaLai().equals(request.getMaPhu())) {
            throw new AppException(ErrorCode.E14);
        }
        return repository.create(request)
                .orElseThrow(() -> new ResourceNotFoundException("ChuyenXe"));
    }

    @Transactional
    public String cancel(String maChuyen) {
        return repository.cancel(maChuyen)
                .orElseThrow(() -> new ResourceNotFoundException("ChuyenXe", maChuyen));
    }

    @Transactional
    public String finish(String maChuyen, FinishTripRequest request) {
        if (request.getKmThucTe() == null || request.getKmThucTe() <= 0) {
            throw new AppException(ErrorCode.E21);
        }
        if (request.getChiPhiVanHanh() == null
                || request.getChiPhiVanHanh().compareTo(BigDecimal.ZERO) < 0) {
            throw new AppException(ErrorCode.E31);
        }
        return repository.finish(maChuyen, request)
                .orElseThrow(() -> new ResourceNotFoundException("ChuyenXe", maChuyen));
    }

    public SeatMapResponse seatMap(String maChuyen) {
        return repository.seatMap(maChuyen)
                .orElseThrow(() -> new ResourceNotFoundException("ChuyenXe", maChuyen));
    }
}
