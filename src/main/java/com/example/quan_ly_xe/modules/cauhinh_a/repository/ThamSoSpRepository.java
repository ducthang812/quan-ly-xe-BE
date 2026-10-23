package com.example.quan_ly_xe.modules.cauhinh_a.repository;

import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoPhucTapResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.ThamSoResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository thao tác bảng ThamSo và DoPhucTap thuần túy bằng Stored Procedures của SQL Server.
 */
@Repository
public class ThamSoSpRepository {

    private final JdbcTemplate jdbcTemplate;

    public ThamSoSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static final RowMapper<ThamSoResponse> THAM_SO_MAPPER = (rs, rowNum) -> ThamSoResponse.builder()
            .maThamSo(rs.getString("MaThamSo"))
            .giaTri(rs.getDouble("GiaTri"))
            .moTa(rs.getString("MoTa"))
            .build();

    private static final RowMapper<DoPhucTapResponse> DO_PHUC_TAP_MAPPER = (rs, rowNum) -> DoPhucTapResponse.builder()
            .capDo(rs.getInt("CapDo"))
            .moTa(rs.getString("MoTa"))
            .heSoLuong(rs.getDouble("HeSoLuong"))
            .heSoDuongKho(rs.getDouble("HeSoDuongKho"))
            .build();

    /**
     * Gọi SP: sp_LayDanhSachThamSo
     */
    public List<ThamSoResponse> layDanhSachThamSo() {
        return jdbcTemplate.query("{call sp_LayDanhSachThamSo}", THAM_SO_MAPPER);
    }

    /**
     * Gọi SP: sp_LayDanhSachDoPhucTap
     */
    public List<DoPhucTapResponse> layDanhSachDoPhucTap() {
        return jdbcTemplate.query("{call sp_LayDanhSachDoPhucTap}", DO_PHUC_TAP_MAPPER);
    }

    /**
     * Gọi SP: sp_CapNhatThamSoThuLao
     */
    public void capNhatThamSoThuLao(Double donGiaKm, Double hsLai, Double hsPhu,
                                    Double hsLuongCap1, Double hsLuongCap2, Double hsLuongCap3) {
        jdbcTemplate.update("{call sp_CapNhatThamSoThuLao(?, ?, ?, ?, ?, ?)}",
                donGiaKm, hsLai, hsPhu, hsLuongCap1, hsLuongCap2, hsLuongCap3);
    }

    /**
     * Gọi SP: sp_CapNhatThamSoBaoDuongDangKiem
     */
    public void capNhatThamSoBaoDuongDangKiem(Double chuKyBd, Double kmMoiNgayBd, Double canhBaoNgay,
                                             Double chuKyDkCu, Double chuKyDkMoi, Double tuoiXeCu,
                                             Double hsDuongKhoCap1, Double hsDuongKhoCap2, Double hsDuongKhoCap3) {
        jdbcTemplate.update("{call sp_CapNhatThamSoBaoDuongDangKiem(?, ?, ?, ?, ?, ?, ?, ?, ?)}",
                chuKyBd, kmMoiNgayBd, canhBaoNgay, chuKyDkCu, chuKyDkMoi, tuoiXeCu,
                hsDuongKhoCap1, hsDuongKhoCap2, hsDuongKhoCap3);
    }
}

