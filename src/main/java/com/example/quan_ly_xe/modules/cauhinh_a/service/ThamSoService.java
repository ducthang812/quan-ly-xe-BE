package com.example.quan_ly_xe.modules.cauhinh_a.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThamSoBaoDuongRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.request.ThamSoThuLaoRequest;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.CauHinhTongHopResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoPhucTapResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LichNgayResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.ThamSoResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.DanhMucSpRepository;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.ThamSoSpRepository;
import com.example.quan_ly_xe.shared.routing.BranchContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service xử lý UC-002: Thiết lập tham số hệ thống.
 * Kết nối duy nhất vào database của site tương ứng. Việc đọc dữ liệu dùng chung
 * tại DN/HCM do Stored Procedure gọi Linked Server sang HN.
 * <p>
 * Quyền ghi: Chỉ site Hà Nội (/hn - CN01) mới có quyền cập nhật tham số cấu hình chung.
 */
@Service
public class ThamSoService {

    private final ThamSoSpRepository thamSoRepository;
    private final DanhMucSpRepository danhMucRepository;

    public ThamSoService(ThamSoSpRepository thamSoRepository, DanhMucSpRepository danhMucRepository) {
        this.thamSoRepository = thamSoRepository;
        this.danhMucRepository = danhMucRepository;
    }

    private void checkBranchWritePermission() {
        String branch = BranchContextHolder.getBranch();
        if (branch != null && !"CN01".equalsIgnoreCase(branch)) {
            throw new AppException(ErrorCode.FORBIDDEN,
                    "Chỉ chi nhánh Hà Nội (/hn) mới có quyền cập nhật tham số hệ thống. Chi nhánh " + branch + " chỉ có quyền xem.");
        }
    }

    public List<ThamSoResponse> layDanhSachThamSo() {
        return thamSoRepository.layDanhSachThamSo();
    }

    public List<DoPhucTapResponse> layDanhSachDoPhucTap() {
        return thamSoRepository.layDanhSachDoPhucTap();
    }

    /**
     * Lấy toàn bộ cấu hình phục vụ hiển thị màn hình MH01 Tab 1.
     */
    public CauHinhTongHopResponse layCauHinhTongHop() {
        List<ThamSoResponse> thamSoList = thamSoRepository.layDanhSachThamSo();
        Map<String, Double> mapThamSo = new HashMap<>();
        for (ThamSoResponse ts : thamSoList) {
            mapThamSo.put(ts.getMaThamSo(), ts.getGiaTri());
        }

        List<DoPhucTapResponse> doPhucTapList = thamSoRepository.layDanhSachDoPhucTap();
        List<LichNgayResponse> lichNgayList = danhMucRepository.layDanhSachLichNgay(null, null);

        return CauHinhTongHopResponse.builder()
                .thamSo(mapThamSo)
                .doPhucTap(doPhucTapList)
                .lichNgay(lichNgayList)
                .build();
    }

    /**
     * UC-002: Lưu tham số thù lao (chỉ site /hn mới được phép ghi).
     */
    @Transactional
    public void capNhatThamSoThuLao(ThamSoThuLaoRequest req) {
        checkBranchWritePermission();

        if (req.getDonGiaKm() <= 0 || req.getHsLai() <= 0 || req.getHsPhu() <= 0
                || req.getHsLuongCap1() <= 0 || req.getHsLuongCap2() <= 0 || req.getHsLuongCap3() <= 0) {
            throw new AppException(ErrorCode.E02);
        }

        thamSoRepository.capNhatThamSoThuLao(
                req.getDonGiaKm(),
                req.getHsLai(),
                req.getHsPhu(),
                req.getHsLuongCap1(),
                req.getHsLuongCap2(),
                req.getHsLuongCap3()
        );
    }

    /**
     * UC-002: Lưu tham số bảo dưỡng và đăng kiểm (chỉ site /hn mới được phép ghi).
     */
    @Transactional
    public void capNhatThamSoBaoDuong(ThamSoBaoDuongRequest req) {
        checkBranchWritePermission();

        if (req.getChuKyBd() <= 0 || req.getKmMoiNgayBd() <= 0 || req.getCanhBaoNgay() <= 0
                || req.getChuKyDkCu() <= 0 || req.getChuKyDkMoi() <= 0 || req.getTuoiXeCu() <= 0) {
            throw new AppException(ErrorCode.E02);
        }

        if (req.getHsDuongKhoCap1() < 1.0 || req.getHsDuongKhoCap2() < 1.0 || req.getHsDuongKhoCap3() < 1.0) {
            throw new AppException(ErrorCode.E03);
        }

        thamSoRepository.capNhatThamSoBaoDuongDangKiem(
                req.getChuKyBd(),
                req.getKmMoiNgayBd(),
                req.getCanhBaoNgay(),
                req.getChuKyDkCu(),
                req.getChuKyDkMoi(),
                req.getTuoiXeCu(),
                req.getHsDuongKhoCap1(),
                req.getHsDuongKhoCap2(),
                req.getHsDuongKhoCap3()
        );
    }
}
