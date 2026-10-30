package com.example.quan_ly_xe.modules.cauhinh_a.service;

import com.example.quan_ly_xe.common.util.CurrentDateProvider;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.BangLuongResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TrangThaiChotLuongResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.BangLuongSpRepository;
import com.example.quan_ly_xe.shared.routing.BranchContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Service xử lý chốt lương và tra cứu bảng lương (UC-017).
 */
@Service
public class BangLuongService {

    private final BangLuongSpRepository bangLuongSpRepository;
    private final CurrentDateProvider currentDateProvider;

    public BangLuongService(BangLuongSpRepository bangLuongSpRepository, CurrentDateProvider currentDateProvider) {
        this.bangLuongSpRepository = bangLuongSpRepository;
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
     * Kiểm tra trạng thái chốt lương của tháng (MH05).
     */
    public TrangThaiChotLuongResponse kiemTraTrangThaiChotLuong(String thang, String maCN) {
        return bangLuongSpRepository.kiemTraTrangThaiChotLuong(resolveThang(thang), resolveMaCN(maCN));
    }

    /**
     * Thực hiện chốt lương tháng (UC-017).
     */
    public TrangThaiChotLuongResponse chotLuongThang(String thang, String maCN) {
        return bangLuongSpRepository.chotLuongThang(resolveThang(thang), resolveMaCN(maCN));
    }

    /**
     * Lấy danh sách bảng lương đã chốt.
     */
    public List<BangLuongResponse> layDanhSachBangLuong(String thang, String maCN) {
        return bangLuongSpRepository.layDanhSachBangLuong(resolveThang(thang), resolveMaCN(maCN));
    }
}

