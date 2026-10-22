package com.example.quan_ly_xe.modules.cauhinh_a.repository;

import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.ChiNhanhResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LichNgayResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.MucDoSanSangResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.time.LocalDate;
import java.util.List;

/**
 * Repository danh mục dùng chung (Chi nhánh, Lịch ngày, Sẵn sàng hệ thống) thuần túy bằng Stored Procedures.
 */
@Repository
public class DanhMucSpRepository {

    private final JdbcTemplate jdbcTemplate;

    public DanhMucSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static final RowMapper<ChiNhanhResponse> CHI_NHANH_MAPPER = (rs, rowNum) -> ChiNhanhResponse.builder()
            .maCN(rs.getString("MaCN"))
            .TenCN(rs.getString("TenCN"))
            .diaChi(rs.getString("DiaChi"))
            .soDienThoai(rs.getString("SoDienThoai"))
            .maTruongCN(rs.getString("MaTruongCN"))
            .tenTruongCN(rs.getString("TenTruongCN"))
            .build();

    private static final RowMapper<LichNgayResponse> LICH_NGAY_MAPPER = (rs, rowNum) -> {
        Date ngaySql = rs.getDate("Ngay");
        LocalDate ngay = ngaySql != null ? ngaySql.toLocalDate() : null;

        return LichNgayResponse.builder()
                .ngay(ngay)
                .maLoaiNgay(rs.getString("MaLoaiNgay"))
                .tenLoaiNgay(rs.getString("TenLoaiNgay"))
                .build();
    };

    /**
     * Gọi SP: sp_LayDanhSachChiNhanh
     */
    public List<ChiNhanhResponse> layDanhSachChiNhanh() {
        return jdbcTemplate.query("{call sp_LayDanhSachChiNhanh}", CHI_NHANH_MAPPER);
    }

    /**
     * Gọi SP: sp_LayDanhSachLichNgay
     */
    public List<LichNgayResponse> layDanhSachLichNgay(Integer nam, Integer thang) {
        return jdbcTemplate.query("{call sp_LayDanhSachLichNgay(?, ?)}", LICH_NGAY_MAPPER, nam, thang);
    }

    /**
     * Gọi SP: sp_KiemTraMucDoSanSang
     */
    public MucDoSanSangResponse kiemTraMucDoSanSang() {
        return jdbcTemplate.queryForObject("{call sp_KiemTraMucDoSanSang}", (rs, rowNum) -> {
            double donGiaKm = rs.getDouble("DonGiaKm");
            double chuKyBd = rs.getDouble("ChuKyBd");
            double chuKyDkCu = rs.getDouble("ChuKyDkCu");
            double chuKyDkMoi = rs.getDouble("ChuKyDkMoi");
            int tongSoTuyen = rs.getInt("TongSoTuyen");
            int soTuyenThieuGia = rs.getInt("SoTuyenThieuGia");
            int soTaiXeDangLam = rs.getInt("SoTaiXeDangLam");

            boolean hopLeTuyen = soTuyenThieuGia == 0;
            String textDong1 = String.format("✓ 1. Tham số: đơn giá %,.0f đ/km, chu kỳ bảo dưỡng %.0f ngày, đăng kiểm %.0f/%.0f tháng",
                    donGiaKm, chuKyBd, chuKyDkCu, chuKyDkMoi);
            String textDong2 = hopLeTuyen
                    ? String.format("✓ 2. %d tuyến đều đủ 4 mức giá", tongSoTuyen)
                    : String.format("⚠ 2. %d tuyến thiếu giá → bấm để nhập giá", soTuyenThieuGia);
            String textDong5 = String.format("✓ 4. %d tài xế", soTaiXeDangLam);

            return MucDoSanSangResponse.builder()
                    .donGiaKm(donGiaKm)
                    .chuKyBd(chuKyBd)
                    .chuKyDkCu(chuKyDkCu)
                    .chuKyDkMoi(chuKyDkMoi)
                    .tongSoTuyen(tongSoTuyen)
                    .soTuyenThieuGia(soTuyenThieuGia)
                    .soTaiXeDangLam(soTaiXeDangLam)
                    .textDong1ThamSo(textDong1)
                    .textDong2Tuyen(textDong2)
                    .hopLeTuyen(hopLeTuyen)
                    .textDong5TaiXe(textDong5)
                    .build();
        });
    }
}

