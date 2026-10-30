package com.example.quan_ly_xe.modules.cauhinh_a.controller;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuLoaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuTuyenReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LuongTaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TongHopBaoCaoResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.XeQuaHanBaoDuongReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.service.BaoCaoService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

/**
 * Controller phục vụ Màn hình MH05 Báo cáo (UC-016).
 * 3 ô số tổng + 5 tab báo cáo:
 * 1. Lương tài xế (sp_R01)
 * 2. Doanh thu theo xe (sp_R02)
 * 3. Doanh thu theo tuyến (sp_R03)
 * 4. Doanh thu theo loại xe (sp_R04)
 * 5. Xe quá hạn bảo dưỡng (sp_R06)
 */
@RestController
@RequestMapping({"/api/v1/cauhinh/bao-cao", "/api/v1/bao-cao"})
public class BaoCaoController {

    private final BaoCaoService baoCaoService;

    public BaoCaoController(BaoCaoService baoCaoService) {
        this.baoCaoService = baoCaoService;
    }

    /**
     * Danh sách các tháng có chuyến (MH05 Combobox Tháng).
     * Mặc định đầu tiên lúc nào cũng là tháng hiện tại xong mới đến các tháng có dữ liệu.
     */
    @GetMapping("/thang-co-chuyen")
    public ApiResponse<List<String>> layDanhSachThangCoChuyen(
            @RequestParam(required = false) String thangHienTai) {
        return ApiResponse.ok(baoCaoService.layDanhSachThangCoChuyen(thangHienTai));
    }

    /**
     * 3 ô số tổng (F15 Doanh thu, Số vé, F02 Tổng lương tài xế).
     */
    @GetMapping("/tong-hop")
    public ApiResponse<TongHopBaoCaoResponse> layTongHopSoLieuThang(
            @RequestParam(required = false) String thang,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(baoCaoService.layTongHopSoLieuThang(thang, maCN));
    }

    /**
     * Tab 1: Lương tài xế (sp_R01).
     */
    @GetMapping("/luong-tai-xe")
    public ApiResponse<List<LuongTaiXeReportItem>> layBaoCaoLuongTaiXe(
            @RequestParam(required = false) String thang,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(baoCaoService.layBaoCaoLuongTaiXe(thang, maCN));
    }

    /**
     * Tab 2: Doanh thu theo xe (sp_R02).
     */
    @GetMapping("/doanh-thu-theo-xe")
    public ApiResponse<List<DoanhThuXeReportItem>> layBaoCaoDoanhThuTheoXe(
            @RequestParam(required = false) String thang,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(baoCaoService.layBaoCaoDoanhThuTheoXe(thang, maCN));
    }

    /**
     * Tab 3: Doanh thu theo tuyến (sp_R03).
     */
    @GetMapping("/doanh-thu-theo-tuyen")
    public ApiResponse<List<DoanhThuTuyenReportItem>> layBaoCaoDoanhThuTheoTuyen(
            @RequestParam(required = false) String thang,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(baoCaoService.layBaoCaoDoanhThuTheoTuyen(thang, maCN));
    }

    /**
     * Tab 4: Doanh thu theo loại xe (sp_R04).
     */
    @GetMapping("/doanh-thu-theo-loai-xe")
    public ApiResponse<List<DoanhThuLoaiXeReportItem>> layBaoCaoDoanhThuTheoLoaiXe(
            @RequestParam(required = false) String thang,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(baoCaoService.layBaoCaoDoanhThuTheoLoaiXe(thang, maCN));
    }

    /**
     * Tab 5: Xe quá hạn bảo dưỡng (sp_R06).
     */
    @GetMapping("/xe-qua-han-bao-duong")
    public ApiResponse<List<XeQuaHanBaoDuongReportItem>> layBaoCaoXeQuaHanBaoDuong(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate ngayXet,
            @RequestParam(required = false) String maCN) {
        return ApiResponse.ok(baoCaoService.layBaoCaoXeQuaHanBaoDuong(ngayXet, maCN));
    }
}

