package com.example.quan_ly_xe.modules.cauhinh_a.service;

import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.ChiNhanhResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LichNgayResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.MucDoSanSangResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.repository.DanhMucSpRepository;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service cung cấp dữ liệu danh mục dùng chung (Sprint 0) & Mức độ sẵn sàng hệ thống (UC-001).
 * Kết nối duy nhất vào database của site tương ứng. Việc đọc dữ liệu dùng chung
 * tại DN/HCM do Stored Procedure gọi Linked Server sang HN.
 */
@Service
public class DanhMucService {

    private final DanhMucSpRepository danhMucRepository;

    public DanhMucService(DanhMucSpRepository danhMucRepository) {
        this.danhMucRepository = danhMucRepository;
    }

    /**
     * Danh sách chi nhánh toàn chuỗi.
     */
    public List<ChiNhanhResponse> layDanhSachChiNhanh() {
        return danhMucRepository.layDanhSachChiNhanh();
    }

    /**
     * Danh sách lịch loại ngày lấy trực tiếp từ CSDL (bảng LichLoaiNgay).
     */
    public List<LichNgayResponse> layDanhSachLichNgay(Integer nam, Integer thang) {
        return danhMucRepository.layDanhSachLichNgay(nam, thang);
    }

    /**
     * UC-001: Kiểm tra mức độ sẵn sàng hệ thống (MH01.0).
     */
    public MucDoSanSangResponse kiemTraMucDoSanSang() {
        return danhMucRepository.kiemTraMucDoSanSang();
    }
}
