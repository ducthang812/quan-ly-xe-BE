package com.example.quan_ly_xe.modules.cauhinh_a.service;

import com.example.quan_ly_xe.common.util.CurrentDateProvider;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuLoaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuTuyenReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LuongTaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TongHopBaoCaoResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.XeQuaHanBaoDuongReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.BaoCaoSpRepository;
import com.example.quan_ly_xe.shared.routing.BranchContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Service xử lý logic nghiệp vụ Báo cáo (UC-016 - MH05).
 */
@Service
public class BaoCaoService {

    private final BaoCaoSpRepository baoCaoSpRepository;
    private final CurrentDateProvider currentDateProvider;

    public BaoCaoService(BaoCaoSpRepository baoCaoSpRepository, CurrentDateProvider currentDateProvider) {
        this.baoCaoSpRepository = baoCaoSpRepository;
        this.currentDateProvider = currentDateProvider;
    }

    private String getActiveBranch() {
        String branch = BranchContextHolder.getBranch();
        if (branch != null && !branch.isBlank()) {
            return branch;
        }
        return "CN01";
    }

    private String resolveThang(String thang) {
        if (thang == null || thang.trim().isEmpty()) {
            LocalDate today = currentDateProvider.today();
            return today.format(DateTimeFormatter.ofPattern("yyyy-MM"));
        }
        return thang.trim();
    }

    private LocalDate resolveNgayXet(LocalDate ngayXet) {
        if (ngayXet == null) {
            return currentDateProvider.today();
        }
        return ngayXet;
    }

    private String resolveMaCN(String maCN) {
        if (maCN == null || maCN.trim().isEmpty() || "ALL".equalsIgnoreCase(maCN.trim()) || "TAT_CA".equalsIgnoreCase(maCN.trim())) {
            return getActiveBranch();
        }
        String s = maCN.trim().toUpperCase();
        if ("HN".equals(s) || "CN01".equals(s)) return "CN01";
        if ("DN".equals(s) || "CN02".equals(s)) return "CN02";
        if ("HCM".equals(s) || "CN03".equals(s)) return "CN03";
        return s;
    }

    /**
     * Lấy danh sách tháng có chuyến (MH05 Combobox Tháng).
     * Mặc định đầu tiên lúc nào cũng là tháng hiện tại xong mới đến các tháng có dữ liệu.
     */
    public List<String> layDanhSachThangCoChuyen(String thangHienTai) {
        String resolvedThang = resolveThang(thangHienTai);
        List<String> list = baoCaoSpRepository.layDanhSachThangCoChuyen(resolvedThang);
        if (list == null || list.isEmpty()) {
            return List.of(resolvedThang);
        }
        return list;
    }

    public List<String> layDanhSachThangCoChuyen() {
        return layDanhSachThangCoChuyen(null);
    }

    /**
     * 3 ô số tổng đầu màn hình MH05.
     */
    public TongHopBaoCaoResponse layTongHopSoLieuThang(String thang, String maCN) {
        return baoCaoSpRepository.layTongHopSoLieuThang(resolveThang(thang), resolveMaCN(maCN));
    }

    /**
     * Tab 1: Lương tài xế (sp_R01).
     */
    public List<LuongTaiXeReportItem> layBaoCaoLuongTaiXe(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoLuongTaiXe(resolveThang(thang), resolveMaCN(maCN));
    }

    /**
     * Tab 2: Doanh thu theo xe (sp_R02).
     */
    public List<DoanhThuXeReportItem> layBaoCaoDoanhThuTheoXe(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoDoanhThuTheoXe(resolveThang(thang), resolveMaCN(maCN));
    }

    /**
     * Tab 3: Doanh thu theo tuyến (sp_R03).
     */
    public List<DoanhThuTuyenReportItem> layBaoCaoDoanhThuTheoTuyen(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoDoanhThuTheoTuyen(resolveThang(thang), resolveMaCN(maCN));
    }

    /**
     * Tab 4: Doanh thu theo loại xe (sp_R04).
     */
    public List<DoanhThuLoaiXeReportItem> layBaoCaoDoanhThuTheoLoaiXe(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoDoanhThuTheoLoaiXe(resolveThang(thang), resolveMaCN(maCN));
    }

    /**
     * Tab 5: Xe quá hạn bảo dưỡng (sp_R06).
     */
    public List<XeQuaHanBaoDuongReportItem> layBaoCaoXeQuaHanBaoDuong(LocalDate ngayXet, String maCN) {
        return baoCaoSpRepository.layBaoCaoXeQuaHanBaoDuong(resolveNgayXet(ngayXet), resolveMaCN(maCN));
    }
}

