package com.example.quan_ly_xe.modules.cauhinh_a.repository;

import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TuyenResponse;
import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.List;
import java.util.Optional;

/**
 * Repository thao tác bảng TuyenDuong và BangGiaVe thuần túy bằng Stored Procedures của SQL Server.
 */
@Repository
public class TuyenDuongSpRepository {

    private final JdbcTemplate jdbcTemplate;

    public TuyenDuongSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static final RowMapper<TuyenResponse> TUYEN_MAPPER = (rs, rowNum) -> {
        Double giaThuong = rs.getObject("GiaThuong") != null ? rs.getDouble("GiaThuong") : null;
        Double giaCuoiTuan = rs.getObject("GiaCuoiTuan") != null ? rs.getDouble("GiaCuoiTuan") : null;
        Double giaMuaDL = rs.getObject("GiaMuaDL") != null ? rs.getDouble("GiaMuaDL") : null;
        Double giaLeTet = rs.getObject("GiaLeTet") != null ? rs.getDouble("GiaLeTet") : null;

        return TuyenResponse.builder()
                .maTuyen(rs.getString("MaTuyen"))
                .diemDau(rs.getString("DiemDau"))
                .diemCuoi(rs.getString("DiemCuoi"))
                .doDaiKm(rs.getDouble("DoDaiKm"))
                .capDo(rs.getInt("CapDo"))
                .tenCapDo(rs.getString("TenCapDo"))
                .heSoLuong(rs.getDouble("HeSoLuong"))
                .heSoDuongKho(rs.getDouble("HeSoDuongKho"))
                .giaThuong(giaThuong)
                .giaCuoiTuan(giaCuoiTuan)
                .giaMuaDL(giaMuaDL)
                .giaLeTet(giaLeTet)
                .build();
    };

    /**
     * Gọi SP: sp_ThemTuyenVaGia
     * Nhận đầu vào 4 giá, sinh mã tuyến tự tăng và lưu trong 1 transaction của SQL Server.
     */
    public String themTuyenVaGia(String diemDau, String diemCuoi, Double doDaiKm, Integer capDo,
                                 Double giaThuong, Double giaCuoiTuan, Double giaMuaDL, Double giaLeTet) {
        return jdbcTemplate.execute("{call sp_ThemTuyenVaGia(?, ?, ?, ?, ?, ?, ?, ?, ?)}",
                (CallableStatementCallback<String>) cs -> {
                    cs.setString(1, diemDau);
                    cs.setString(2, diemCuoi);
                    cs.setDouble(3, doDaiKm);
                    cs.setInt(4, capDo);
                    cs.setDouble(5, giaThuong);
                    cs.setDouble(6, giaCuoiTuan);
                    cs.setDouble(7, giaMuaDL);
                    cs.setDouble(8, giaLeTet);
                    cs.registerOutParameter(9, Types.VARCHAR);

                    cs.execute();
                    String generatedCode = cs.getString(9);
                    if (generatedCode == null && cs.getResultSet() != null && cs.getResultSet().next()) {
                        generatedCode = cs.getResultSet().getString("MaTuyen");
                    }
                    return generatedCode;
                });
    }

    /**
     * Gọi SP: sp_UpsertBangGiaVe
     * MERGE giá vé theo tuyến và loại ngày
     */
    public void upsertBangGiaVe(String maTuyen, String maLoaiNgay, Double giaVe) {
        jdbcTemplate.update("{call sp_UpsertBangGiaVe(?, ?, ?)}", maTuyen, maLoaiNgay, giaVe);
    }

    /**
     * Gọi SP: sp_LayDanhSachTuyenVaGia
     */
    public List<TuyenResponse> layDanhSachTuyenVaGia(String maTuyen) {
        return jdbcTemplate.query("{call sp_LayDanhSachTuyenVaGia(?)}", TUYEN_MAPPER, maTuyen);
    }

    public Optional<TuyenResponse> layChiTietTuyen(String maTuyen) {
        List<TuyenResponse> list = layDanhSachTuyenVaGia(maTuyen);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.get(0));
    }

    /**
     * Gọi SP: sp_CapNhatTuyenDuong
     */
    public void capNhatTuyenDuong(String maTuyen, String diemDau, String diemCuoi, Double doDaiKm, Integer capDo) {
        jdbcTemplate.update("{call sp_CapNhatTuyenDuong(?, ?, ?, ?, ?)}", maTuyen, diemDau, diemCuoi, doDaiKm, capDo);
    }

    /**
     * Gọi SP: sp_XoaTuyenDuong
     */
    public void xoaTuyenDuong(String maTuyen) {
        jdbcTemplate.update("{call sp_XoaTuyenDuong(?)}", maTuyen);
    }
}

