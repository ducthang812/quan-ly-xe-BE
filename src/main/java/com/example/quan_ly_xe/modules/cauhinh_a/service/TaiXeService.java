package com.example.quan_ly_xe.modules.cauhinh_a.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.common.security.CurrentUser;
import com.example.quan_ly_xe.common.security.CurrentUserProvider;
import com.example.quan_ly_xe.common.util.CurrentDateProvider;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.CapNhatTaiXeRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThemTaiXeRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TaiXeResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.TaiXeSpRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Service xử lý UC-007: Thêm tài xế & quản lý tài xế.
 */
@Service
public class TaiXeService {

    private final TaiXeSpRepository taiXeRepository;
    private final CurrentUserProvider currentUserProvider;
    private final CurrentDateProvider currentDateProvider;

    public TaiXeService(TaiXeSpRepository taiXeRepository,
                        CurrentUserProvider currentUserProvider,
                        CurrentDateProvider currentDateProvider) {
        this.taiXeRepository = taiXeRepository;
        this.currentUserProvider = currentUserProvider;
        this.currentDateProvider = currentDateProvider;
    }

    public List<TaiXeResponse> layDanhSachTaiXe(String maCN, String trangThai, String thang) {
        if (thang == null || thang.isBlank()) {
            thang = currentDateProvider.today().format(DateTimeFormatter.ofPattern("yyyy-MM"));
        }
        return taiXeRepository.layDanhSachTaiXe(maCN, trangThai, thang);
    }

    public TaiXeResponse layChiTietTaiXe(String maTX, String thang) {
        if (thang == null || thang.isBlank()) {
            thang = currentDateProvider.today().format(DateTimeFormatter.ofPattern("yyyy-MM"));
        }
        return taiXeRepository.layChiTietTaiXe(maTX, thang)
                .orElseThrow(() -> new ResourceNotFoundException("TaiXe", maTX));
    }

    /**
     * UC-007: Thêm tài xế mới.
     */
    @Transactional
    public TaiXeResponse themTaiXe(ThemTaiXeRequest req) {
        LocalDate today = currentDateProvider.today();

        // Kiểm tra tuổi >= 21
        int age = Period.between(req.getNgaySinh(), today).getYears();
        if (age < 21) {
            throw new AppException(ErrorCode.E13);
        }

        // Định dạng CCCD 12 số
        if (req.getCccd() == null || !req.getCccd().trim().matches("^\\d{12}$")) {
            throw new AppException(ErrorCode.E11);
        }

        // Chi nhánh: nếu không truyền thì lấy theo nhân viên đang thao tác
        String maCN = req.getMaCN();
        if (maCN == null || maCN.isBlank()) {
            CurrentUser u = currentUserProvider.get();
            if (u != null && u.getBranchCode() != null) {
                maCN = u.getBranchCode();
            }
        }
        if (maCN == null || maCN.isBlank()) {
            maCN = "CN01";
        }

        LocalDate ngayVaoLam = req.getNgayVaoLam() != null ? req.getNgayVaoLam() : today;

        String maTXMoi = taiXeRepository.themTaiXe(
                req.getHoDem().trim(),
                req.getTen().trim(),
                req.getNgaySinh(),
                req.getCccd().trim(),
                req.getSoGplx().trim(),
                req.getHangGplx().trim(),
                req.getSoNha() != null ? req.getSoNha().trim() : null,
                req.getPhuong() != null ? req.getPhuong().trim() : null,
                req.getTinh() != null ? req.getTinh().trim() : null,
                req.getSoDienThoai() != null ? req.getSoDienThoai().trim() : null,
                maCN,
                ngayVaoLam
        );

        return layChiTietTaiXe(maTXMoi, today.format(DateTimeFormatter.ofPattern("yyyy-MM")));
    }

    /**
     * Cập nhật thông tin tài xế (Mục 11.2 - [CẦN BỔ SUNG]).
     */
    @Transactional
    public TaiXeResponse capNhatTaiXe(String maTX, CapNhatTaiXeRequest req) {
        LocalDate today = currentDateProvider.today();
        int age = Period.between(req.getNgaySinh(), today).getYears();
        if (age < 21) {
            throw new AppException(ErrorCode.E13);
        }

        taiXeRepository.capNhatTaiXe(
                maTX,
                req.getHoDem().trim(),
                req.getTen().trim(),
                req.getNgaySinh(),
                req.getSoGplx().trim(),
                req.getHangGplx().trim(),
                req.getSoNha() != null ? req.getSoNha().trim() : null,
                req.getPhuong() != null ? req.getPhuong().trim() : null,
                req.getTinh() != null ? req.getTinh().trim() : null,
                req.getSoDienThoai() != null ? req.getSoDienThoai().trim() : null,
                req.getTrangThai()
        );

        return layChiTietTaiXe(maTX, today.format(DateTimeFormatter.ofPattern("yyyy-MM")));
    }

    /**
     * Đổi trạng thái tài xế (Mục 11.2 - [CẦN BỔ SUNG]).
     */
    @Transactional
    public void doiTrangThaiTaiXe(String maTX, String trangThai) {
        taiXeRepository.doiTrangThaiTaiXe(maTX, trangThai);
    }
}
