package com.example.quan_ly_xe.modules.doixe_c.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.common.util.CurrentDateProvider;
import com.example.quan_ly_xe.modules.doixe_c.dto.request.ThemXeRequest;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.LoaiXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.ThemXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.XeResponse;
import com.example.quan_ly_xe.modules.doixe_c.repository.DoiXeSpRepository;
import com.example.quan_ly_xe.shared.routing.BranchContextHolder;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * UC-005 Thêm xe kèm đăng kiểm, UC-006 Xóa xe, danh mục xe / loại xe (giao tiếp #3).
 * <p>
 * Xe phân mảnh ngang theo chi nhánh: site nào chỉ thêm, xóa, đổi trạng thái xe của site đó;
 * xem xe chi nhánh khác qua Linked Server (chỉ đọc, coQuyenThaoTac = false).
 */
@Service
public class XeService {

    private final DoiXeSpRepository repository;
    private final CurrentDateProvider currentDateProvider;

    public XeService(DoiXeSpRepository repository, CurrentDateProvider currentDateProvider) {
        this.repository = repository;
        this.currentDateProvider = currentDateProvider;
    }

    private String getActiveBranch() {
        String branch = BranchContextHolder.getBranch();
        return branch != null && !branch.isBlank() ? branch : "CN01";
    }

    public List<LoaiXeResponse> layDanhSachLoaiXe() {
        return repository.layDanhSachLoaiXe();
    }

    public List<XeResponse> layDanhSachXe(String maCN, String trangThai) {
        String activeBranch = getActiveBranch();
        List<XeResponse> list = repository.layDanhSachXe(maCN, trangThai, null);
        list.forEach(x -> x.setCoQuyenThaoTac(activeBranch.equalsIgnoreCase(x.getMaCN())));
        return list;
    }

    /** Xe thuộc phân mảnh của site hiện tại; không có ở nút này thì coi như không tìm thấy. */
    public XeResponse layXeCucBo(String maXe) {
        return repository.layDanhSachXe(null, null, maXe).stream()
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("xe", maXe));
    }

    /**
     * UC-005: sp_ThemXeVaDangKiem lưu xe và lần đăng kiểm đầu trong 1 giao dịch (BR-MH01-07).
     */
    public ThemXeResponse themXe(ThemXeRequest req) {
        String maLoaiXe = req.getMaLoaiXe().trim();
        boolean loaiXeHopLe = repository.layDanhSachLoaiXe().stream()
                .anyMatch(lx -> lx.getMaLoaiXe().equalsIgnoreCase(maLoaiXe));
        if (!loaiXeHopLe) {
            throw new AppException(ErrorCode.E01, "Loại xe");
        }

        String bienSo = req.getBienSo().trim().toUpperCase();
        try {
            return repository.themXeVaDangKiem(bienSo, maLoaiXe, req.getNamSanXuat(),
                    req.getNgayDangKiem(), getActiveBranch(), currentDateProvider.today());
        } catch (DataAccessException ex) {
            if (DoiXeLoiSql.maLoi(ex).orElse(null) == ErrorCode.E07) {
                throw new AppException(ErrorCode.E07, ex, bienSo);
            }
            throw ex;
        }
    }

    /**
     * UC-006: xóa xe chưa có chuyến (BR-MH01-09); đã có chuyến thì E10.
     */
    public void xoaXe(String maXe) {
        layXeCucBo(maXe);
        repository.xoaXe(maXe);
    }

    /**
     * Đổi trạng thái Hoạt động / Bảo dưỡng / Ngừng hoạt động (SRS 11.2 mục 5).
     */
    public void doiTrangThaiXe(String maXe, String trangThai) {
        layXeCucBo(maXe);
        repository.doiTrangThaiXe(maXe, trangThai);
    }
}
