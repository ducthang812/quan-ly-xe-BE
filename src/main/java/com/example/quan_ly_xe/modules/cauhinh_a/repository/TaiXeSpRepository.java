package com.example.quan_ly_xe.modules.cauhinh_a.repository;

import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TaiXeResponse;
import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Date;
import java.sql.Types;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repository thao tác bảng TaiXe và TaiXe_SDT thuần túy bằng Stored Procedures của SQL Server.
 */
@Repository
public class TaiXeSpRepository {

    private final JdbcTemplate jdbcTemplate;

    public TaiXeSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static final RowMapper<TaiXeResponse> TAI_XE_MAPPER = (rs, rowNum) -> {
        Date ngaySinhSql = rs.getDate("NgaySinh");
        LocalDate ngaySinh = ngaySinhSql != null ? ngaySinhSql.toLocalDate() : null;

        Date ngayVaoLamSql = rs.getDate("NgayVaoLam");
        LocalDate ngayVaoLam = ngayVaoLamSql != null ? ngayVaoLamSql.toLocalDate() : null;

        return TaiXeResponse.builder()
                .maTX(rs.getString("MaTX"))
                .hoDem(rs.getString("HoDem"))
                .ten(rs.getString("Ten"))
                .hoTen(rs.getString("HoTen"))
                .ngaySinh(ngaySinh)
                .namSinh(rs.getObject("NamSinh") != null ? rs.getInt("NamSinh") : null)
                .cccd(rs.getString("CCCD"))
                .soGplx(rs.getString("SoGPLX"))
                .hangGplx(rs.getString("HangGPLX"))
                .soNha(rs.getString("SoNha"))
                .phuong(rs.getString("Phuong"))
                .tinh(rs.getString("Tinh"))
                .soDienThoai(rs.getString("SoDienThoai"))
                .ngayVaoLam(ngayVaoLam)
                .trangThai(rs.getString("TrangThai"))
                .maCN(rs.getString("MaCN"))
                .tenCN(rs.getString("TenCN"))
                .soChuyen(rs.getObject("SoChuyen") != null ? rs.getInt("SoChuyen") : 0)
                .thuLaoThang(rs.getObject("ThuLaoThang") != null ? rs.getDouble("ThuLaoThang") : 0.0)
                .build();
    };

    /**
     * Gọi SP: sp_ThemTaiXe
     */
    public String themTaiXe(String hoDem, String ten, LocalDate ngaySinh, String cccd,
                            String soGplx, String hangGplx, String soNha, String phuong,
                            String tinh, String soDienThoai, String maCN, LocalDate ngayVaoLam) {
        return jdbcTemplate.execute("{call sp_ThemTaiXe(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}",
                (CallableStatementCallback<String>) cs -> {
                    cs.setString(1, hoDem);
                    cs.setString(2, ten);
                    cs.setDate(3, Date.valueOf(ngaySinh));
                    cs.setString(4, cccd);
                    cs.setString(5, soGplx);
                    cs.setString(6, hangGplx);
                    cs.setString(7, soNha);
                    cs.setString(8, phuong);
                    cs.setString(9, tinh);
                    cs.setString(10, soDienThoai);
                    cs.setString(11, maCN);
                    if (ngayVaoLam != null) {
                        cs.setDate(12, Date.valueOf(ngayVaoLam));
                    } else {
                        cs.setNull(12, Types.DATE);
                    }
                    cs.registerOutParameter(13, Types.VARCHAR);

                    cs.execute();
                    String generatedCode = cs.getString(13);
                    if (generatedCode == null && cs.getResultSet() != null && cs.getResultSet().next()) {
                        generatedCode = cs.getResultSet().getString("MaTX");
                    }
                    return generatedCode;
                });
    }

    /**
     * Gọi SP: sp_LayDanhSachTaiXe
     */
    public List<TaiXeResponse> layDanhSachTaiXe(String maCN, String trangThai, String thang) {
        return jdbcTemplate.query("{call sp_LayDanhSachTaiXe(?, ?, ?)}", TAI_XE_MAPPER, maCN, trangThai, thang);
    }

    /**
     * Gọi SP: sp_LayChiTietTaiXe
     */
    public Optional<TaiXeResponse> layChiTietTaiXe(String maTX, String thang) {
        List<TaiXeResponse> list = jdbcTemplate.query("{call sp_LayChiTietTaiXe(?, ?)}", TAI_XE_MAPPER, maTX, thang);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.get(0));
    }

    /**
     * Gọi SP: sp_CapNhatTaiXe
     */
    public void capNhatTaiXe(String maTX, String hoDem, String ten, LocalDate ngaySinh,
                             String soGplx, String hangGplx, String soNha, String phuong,
                             String tinh, String soDienThoai, String trangThai) {
        jdbcTemplate.update("{call sp_CapNhatTaiXe(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}",
                maTX, hoDem, ten, Date.valueOf(ngaySinh), soGplx, hangGplx,
                soNha, phuong, tinh, soDienThoai, trangThai);
    }

    /**
     * Gọi SP: sp_DoiTrangThaiTaiXe
     */
    public void doiTrangThaiTaiXe(String maTX, String trangThai) {
        jdbcTemplate.update("{call sp_DoiTrangThaiTaiXe(?, ?)}", maTX, trangThai);
    }
}
