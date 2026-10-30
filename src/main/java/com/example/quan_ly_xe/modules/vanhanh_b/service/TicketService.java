package com.example.quan_ly_xe.modules.vanhanh_b.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.common.security.CurrentUserProvider;
import com.example.quan_ly_xe.common.util.Constant;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.SellTicketRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SellTicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.repository.TicketSpRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;

@Service
public class TicketService {
    private final TicketSpRepository repository;
    private final CurrentUserProvider currentUserProvider;

    public TicketService(TicketSpRepository repository, CurrentUserProvider currentUserProvider) {
        this.repository = repository;
        this.currentUserProvider = currentUserProvider;
    }

    @Transactional
    public SellTicketResponse sell(SellTicketRequest request) {
        if (request.getSoGhe() == null) throw new AppException(ErrorCode.E22);
        validatePhone(request.getSoDienThoai());
        String employeeCode = currentUserProvider.get().getEmployeeCode();
        return repository.sell(request, employeeCode)
                .orElseThrow(() -> new ResourceNotFoundException("ChuyenXe", request.getMaChuyen()));
    }

    @Transactional
    public String cancel(String maVe) {
        return repository.cancel(maVe)
                .orElseThrow(() -> new ResourceNotFoundException("Ve", maVe));
    }

    public List<TicketResponse> findByPhone(String soDienThoai) {
        if (soDienThoai == null || soDienThoai.isBlank()) return Collections.emptyList();
        validatePhone(soDienThoai);
        return repository.findByPhone(soDienThoai);
    }

    private void validatePhone(String soDienThoai) {
        if (soDienThoai == null || !soDienThoai.matches(Constant.VanHanh.REGEX_SO_DIEN_THOAI)) {
            throw new AppException(ErrorCode.E23);
        }
    }
}
