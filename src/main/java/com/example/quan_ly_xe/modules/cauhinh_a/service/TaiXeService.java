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
import com.example.quan_ly_xe.shared.routing.BranchContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Service xử lý UC-007: Thêm tài xế & quản lý tài xế theo mô hình CSDL phân tán.
 * <p>
 * Phân quyền & phân mảnh:
 * <ul>
 *   <li>Dữ liệu tài xế phân mảnh ngang theo chi nhánh (MaCN).</li>
 *   <li>Mỗi site (HN / DN / HCM) chỉ được phép thêm mới, sửa, đổi trạng thái với tài xế thuộc site mình.</li>
 *   <li>Mọi site đều có thể xem danh sách tài xế của các site khác (qua SQL Server Linked Server).</li>
 *   <li>Tài xế của site khác trả về cờ coQuyenThaoTac = false để FE chỉ hiển thị dạng xem, vô hiệu hóa chỉnh sửa.</li>
 * </ul>
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

    private String getActiveBranch() {
        String branch = BranchContextHolder.getBranch();
        if (branch != null && !branch.isBlank()) {
            return branch;
        }
        CurrentUser u = currentUserProvider.get();
        if (u != null && u.getBranchCode() != null && !u.getBranchCode().isBlank()) {
            return u.getBranchCode();
        }
        return "CN01";
    }

    public List<TaiXeResponse> layDanhSachTaiXe(String maCN, String trangThai, String thang) {
        String activeBranch = getActiveBranch();
        if (thang == null || thang.isBlank()) {
            thang = currentDateProvider.today().format(DateTimeFormatter.ofPattern("yyyy-MM"));
        }
        if (maCN == null || maCN.isBlank()) {
            maCN = activeBranch;
        }

        List<TaiXeResponse> list = taiXeRepository.layDanhSachTaiXe(maCN, trangThai, thang);
        list.forEach(tx -> tx.setCoQuyenThaoTac(activeBranch.equalsIgnoreCase(tx.getMaCN())));
        return list;
    }

    public TaiXeResponse layChiTietTaiXe(String maTX, String thang) {
        String activeBranch = getActiveBranch();
        if (thang == null || thang.isBlank()) {
            thang = currentDateProvider.today().format(DateTimeFormatter.ofPattern("yyyy-MM"));
        }
        TaiXeResponse res = taiXeRepository.layChiTietTaiXe(maTX, thang)
                .orElseThrow(() -> new ResourceNotFoundException("TaiXe", maTX));
        res.setCoQuyenThaoTac(activeBranch.equalsIgnoreCase(res.getMaCN()));
        return res;
    }

    /**
     * UC-007: Thêm tài xế mới.
     * Chỉ cho phép thêm tài xế cho chi nhánh của site hiện hành.
     */
    @Transactional
    public TaiXeResponse themTaiXe(ThemTaiXeRequest req) {
        LocalDate today = currentDateProvider.today();
        String activeBranch = getActiveBranch();

        // Kiểm tra tuổi >= 21
        int age = Period.between(req.getNgaySinh(), today).getYears();
        if (age < 21) {
            throw new AppException(ErrorCode.E13);
        }

        // Định dạng CCCD 12 số
        if (req.getCccd() == null || !req.getCccd().trim().matches("^\\d{12}$")) {
            throw new AppException(ErrorCode.E11);
        }

        // Chi nhánh: nếu không truyền thì lấy theo site đang thao tác
        String maCN = req.getMaCN();
        if (maCN == null || maCN.isBlank()) {
            maCN = activeBranch;
        } else if (!activeBranch.equalsIgnoreCase(maCN.trim())) {
            throw new AppException(ErrorCode.FORBIDDEN,
                    "Tại site " + activeBranch + " chỉ được phép thêm tài xế của " + activeBranch + ". Không thể thêm tài xế cho " + maCN.trim() + ".");
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
     * Chỉ cho phép sửa tài xế thuộc chi nhánh hiện hành.
     */
    @Transactional
    public TaiXeResponse capNhatTaiXe(String maTX, CapNhatTaiXeRequest req) {
        LocalDate today = currentDateProvider.today();
        String activeBranch = getActiveBranch();

        TaiXeResponse existing = layChiTietTaiXe(maTX, null);
        if (!activeBranch.equalsIgnoreCase(existing.getMaCN())) {
            throw new AppException(ErrorCode.FORBIDDEN,
                    "Tài xế " + maTX + " thuộc chi nhánh " + existing.getMaCN() + ". Bạn chỉ có quyền xem, không được chỉnh sửa.");
        }

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
     * Đổi trạng thái tài xế DangLam <-> NghiViec (Mục 11.2 - [CẦN BỔ SUNG]).
     * Chỉ cho phép đổi trạng thái tài xế thuộc chi nhánh hiện hành.
     */
    @Transactional
    public void doiTrangThaiTaiXe(String maTX, String trangThai) {
        String activeBranch = getActiveBranch();
        TaiXeResponse existing = layChiTietTaiXe(maTX, null);
        if (!activeBranch.equalsIgnoreCase(existing.getMaCN())) {
            throw new AppException(ErrorCode.FORBIDDEN,
                    "Tài xế " + maTX + " thuộc chi nhánh " + existing.getMaCN() + ". Bạn chỉ có quyền xem, không được chỉnh sửa.");
        }

        taiXeRepository.doiTrangThaiTaiXe(maTX, trangThai);
    }
}
