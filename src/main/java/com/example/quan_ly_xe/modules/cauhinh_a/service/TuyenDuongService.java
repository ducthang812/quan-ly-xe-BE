package com.example.quan_ly_xe.modules.cauhinh_a.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.CapNhatGiaVeRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.CapNhatTuyenRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThemTuyenRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TuyenResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.TuyenDuongSpRepository;
import com.example.quan_ly_xe.shared.routing.BranchContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Service xử lý UC-003: Thêm tuyến kèm giá vé & UC-004: Sửa bảng giá vé.
 * Kết nối duy nhất vào database của site tương ứng. Việc đọc dữ liệu dùng chung
 * tại DN/HCM do Stored Procedure gọi Linked Server sang HN.
 * <p>
 * Quyền ghi: Chỉ site Hà Nội (/hn - CN01) mới có quyền chỉnh sửa tuyến đường và bảng giá vé.
 */
@Service
public class TuyenDuongService {

    private final TuyenDuongSpRepository tuyenDuongRepository;

    public TuyenDuongService(TuyenDuongSpRepository tuyenDuongRepository) {
        this.tuyenDuongRepository = tuyenDuongRepository;
    }

    private void checkBranchWritePermission() {
        String branch = BranchContextHolder.getBranch();
        if (branch != null && !"CN01".equalsIgnoreCase(branch)) {
            throw new AppException(ErrorCode.FORBIDDEN,
                    "Chỉ chi nhánh Hà Nội (/hn) mới có quyền chỉnh sửa tuyến đường và bảng giá vé. Chi nhánh " + branch + " chỉ có quyền xem.");
        }
    }

    public List<TuyenResponse> layDanhSachTuyen(String maTuyen) {
        return tuyenDuongRepository.layDanhSachTuyenVaGia(maTuyen);
    }

    public TuyenResponse layChiTietTuyen(String maTuyen) {
        return tuyenDuongRepository.layChiTietTuyen(maTuyen)
                .orElseThrow(() -> new ResourceNotFoundException("TuyenDuong", maTuyen));
    }

    /**
     * UC-003: Thêm tuyến kèm 4 mức giá vé trong cùng một transaction (chỉ site /hn mới được phép ghi).
     */
    @Transactional
    public TuyenResponse themTuyenVaGia(ThemTuyenRequest req) {
        checkBranchWritePermission();

        if (req.getDiemDau().trim().equalsIgnoreCase(req.getDiemCuoi().trim())) {
            throw new AppException(ErrorCode.E04);
        }
        if (req.getDoDaiKm() <= 0) {
            throw new AppException(ErrorCode.E05);
        }
        if (req.getGiaThuong() == null || req.getGiaThuong() <= 0
                || req.getGiaCuoiTuan() == null || req.getGiaCuoiTuan() <= 0
                || req.getGiaMuaDL() == null || req.getGiaMuaDL() <= 0
                || req.getGiaLeTet() == null || req.getGiaLeTet() <= 0) {
            throw new AppException(ErrorCode.E06);
        }

        String maTuyenMoi = tuyenDuongRepository.themTuyenVaGia(
                req.getDiemDau().trim(),
                req.getDiemCuoi().trim(),
                req.getDoDaiKm(),
                req.getCapDo(),
                req.getGiaThuong(),
                req.getGiaCuoiTuan(),
                req.getGiaMuaDL(),
                req.getGiaLeTet()
        );

        return layChiTietTuyen(maTuyenMoi);
    }

    /**
     * UC-004: Cập nhật giá vé (upsert từng dòng).
     */
    @Transactional
    public void upsertBangGiaVe(CapNhatGiaVeRequest req) {
        checkBranchWritePermission();

        if (req.getGiaVe() == null || req.getGiaVe() <= 0) {
            throw new AppException(ErrorCode.E02);
        }
        tuyenDuongRepository.upsertBangGiaVe(req.getMaTuyen(), req.getMaLoaiNgay(), req.getGiaVe());
    }

    /**
     * UC-004: Cập nhật bảng giá vé hàng loạt.
     */
    @Transactional
    public void capNhatBangGiaVeHangLoat(List<CapNhatGiaVeRequest> requests) {
        checkBranchWritePermission();

        for (CapNhatGiaVeRequest req : requests) {
            upsertBangGiaVe(req);
        }
    }

    /**
     * Sửa thông tin tuyến đường.
     */
    @Transactional
    public void capNhatTuyenDuong(String maTuyen, CapNhatTuyenRequest req) {
        checkBranchWritePermission();

        if (req.getDiemDau().trim().equalsIgnoreCase(req.getDiemCuoi().trim())) {
            throw new AppException(ErrorCode.E04);
        }
        if (req.getDoDaiKm() <= 0) {
            throw new AppException(ErrorCode.E05);
        }
        tuyenDuongRepository.capNhatTuyenDuong(
                maTuyen,
                req.getDiemDau().trim(),
                req.getDiemCuoi().trim(),
                req.getDoDaiKm(),
                req.getCapDo()
        );
    }

    /**
     * Xóa tuyến đường.
     */
    @Transactional
    public void xoaTuyenDuong(String maTuyen) {
        checkBranchWritePermission();

        tuyenDuongRepository.xoaTuyenDuong(maTuyen);
    }
}
