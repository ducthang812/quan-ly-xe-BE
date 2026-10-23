package com.example.quan_ly_xe.modules.cauhinh_a.service;

import com.example.quan_ly_xe.common.util.CurrentDateProvider;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuLoaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuTuyenReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LuongTaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TongHopBaoCaoResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.XeQuaHanBaoDuongReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.BaoCaoSpRepository;
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

    /**
     * Lấy danh sách tháng có chuyến (MH05 Combobox Tháng).
     */
    public List<String> layDanhSachThangCoChuyen() {
        return baoCaoSpRepository.layDanhSachThangCoChuyen();
    }

    /**
     * 3 ô số tổng đầu màn hình MH05.
     */
    public TongHopBaoCaoResponse layTongHopSoLieuThang(String thang, String maCN) {
        return baoCaoSpRepository.layTongHopSoLieuThang(resolveThang(thang), maCN);
    }

    /**
     * Tab 1: Lương tài xế (sp_R01).
     */
    public List<LuongTaiXeReportItem> layBaoCaoLuongTaiXe(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoLuongTaiXe(resolveThang(thang), maCN);
    }

    /**
     * Tab 2: Doanh thu theo xe (sp_R02).
     */
    public List<DoanhThuXeReportItem> layBaoCaoDoanhThuTheoXe(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoDoanhThuTheoXe(resolveThang(thang), maCN);
    }

    /**
     * Tab 3: Doanh thu theo tuyến (sp_R03).
     */
    public List<DoanhThuTuyenReportItem> layBaoCaoDoanhThuTheoTuyen(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoDoanhThuTheoTuyen(resolveThang(thang), maCN);
    }

    /**
     * Tab 4: Doanh thu theo loại xe (sp_R04).
     */
    public List<DoanhThuLoaiXeReportItem> layBaoCaoDoanhThuTheoLoaiXe(String thang, String maCN) {
        return baoCaoSpRepository.layBaoCaoDoanhThuTheoLoaiXe(resolveThang(thang), maCN);
    }

    /**
     * Tab 5: Xe quá hạn bảo dưỡng (sp_R06).
     */
    public List<XeQuaHanBaoDuongReportItem> layBaoCaoXeQuaHanBaoDuong(LocalDate ngayXet, String maCN) {
        return baoCaoSpRepository.layBaoCaoXeQuaHanBaoDuong(resolveNgayXet(ngayXet), maCN);
    }
}

