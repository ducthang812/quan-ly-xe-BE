package com.example.quan_ly_xe.modules.doixe_c.repository;

import com.example.quan_ly_xe.modules.doixe_c.dto.response.GhiNhanBaoDuongResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.GhiNhanDangKiemResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.LichXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.LoaiXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.ThamSoKyThuatResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.ThemXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.XeResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;

/**
 * Repository bảng LoaiXe, Xe, DangKiem, BaoDuong (Người C), thuần túy bằng Stored Procedures
 * và view vw_LichBaoDuong trong migration V202610291000__C_doi_xe.sql.
 * Mỗi request chỉ kết nối CSDL của site đang gọi (BranchRoutingDataSource).
 */
@Repository
public class DoiXeSpRepository {

    private final JdbcTemplate jdbcTemplate;

    public DoiXeSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static LocalDate toLocalDate(ResultSet rs, String column) throws SQLException {
        Date d = rs.getDate(column);
        return d != null ? d.toLocalDate() : null;
    }

    private static Integer getInteger(ResultSet rs, String column) throws SQLException {
        int v = rs.getInt(column);
        return rs.wasNull() ? null : v;
    }

    private static Double getDouble(ResultSet rs, String column) throws SQLException {
        double v = rs.getDouble(column);
        return rs.wasNull() ? null : v;
    }

    private static Date toSqlDate(LocalDate d) {
        return d != null ? Date.valueOf(d) : null;
    }

    private static final RowMapper<LoaiXeResponse> LOAI_XE_MAPPER = (rs, rowNum) -> LoaiXeResponse.builder()
            .maLoaiXe(rs.getString("MaLoaiXe"))
            .tenLoaiXe(rs.getString("TenLoaiXe"))
            .soGhe(getInteger(rs, "SoGhe"))
            .build();

    private static final RowMapper<XeResponse> XE_MAPPER = (rs, rowNum) -> XeResponse.builder()
            .maXe(rs.getString("MaXe"))
            .bienSo(rs.getString("BienSo"))
            .maLoaiXe(rs.getString("MaLoaiXe"))
            .tenLoaiXe(rs.getString("TenLoaiXe"))
            .soGhe(getInteger(rs, "SoGhe"))
            .namSanXuat(getInteger(rs, "NamSanXuat"))
            .ngayDuaVaoSD(toLocalDate(rs, "NgayDuaVaoSD"))
            .trangThai(rs.getString("TrangThai"))
            .maCN(rs.getString("MaCN"))
            .hanDangKiem(toLocalDate(rs, "HanDangKiem"))
            .soChuyen(getInteger(rs, "SoChuyen"))
            .build();

    private static final RowMapper<LichXeResponse> LICH_MAPPER = (rs, rowNum) -> LichXeResponse.builder()
            .maXe(rs.getString("MaXe"))
            .bienSo(rs.getString("BienSo"))
            .maLoaiXe(rs.getString("MaLoaiXe"))
            .tenLoaiXe(rs.getString("TenLoaiXe"))
            .maCN(rs.getString("MaCN"))
            .namSanXuat(getInteger(rs, "NamSanXuat"))
            .ngayDuaVaoSD(toLocalDate(rs, "NgayDuaVaoSD"))
            .trangThai(rs.getString("TrangThai"))
            .ngayBDGanNhat(toLocalDate(rs, "NgayBDGanNhat"))
            .ngayMocBD(toLocalDate(rs, "NgayMocBD"))
            .kmLamViec(getDouble(rs, "KmLamViec"))
            .ngayBDTiepTheo(toLocalDate(rs, "NgayBDTiepTheo"))
            .hanDangKiem(toLocalDate(rs, "HanDangKiem"))
            .ngayDKGanNhat(toLocalDate(rs, "NgayDKGanNhat"))
            .build();

    /**
     * Gọi SP: sp_LayDanhSachLoaiXe
     */
    public List<LoaiXeResponse> layDanhSachLoaiXe() {
        return jdbcTemplate.query("{call sp_LayDanhSachLoaiXe}", LOAI_XE_MAPPER);
    }

    /**
     * Gọi SP: sp_LayDanhSachXe (chi nhánh khác thì SP tự hỏi nút đó qua Linked Server)
     */
    public List<XeResponse> layDanhSachXe(String maCN, String trangThai, String maXe) {
        return jdbcTemplate.query("{call sp_LayDanhSachXe(?, ?, ?)}", XE_MAPPER, maCN, trangThai, maXe);
    }

    /**
     * Gọi SP: sp_ThemXeVaDangKiem (một giao dịch Xe + DangKiem)
     */
    public ThemXeResponse themXeVaDangKiem(String bienSo, String maLoaiXe, Integer namSanXuat,
                                           LocalDate ngayDangKiem, String maCN, LocalDate ngayHienTai) {
        return jdbcTemplate.queryForObject("{call sp_ThemXeVaDangKiem(?, ?, ?, ?, ?, ?)}",
                (rs, rowNum) -> ThemXeResponse.builder()
                        .maXe(rs.getString("MaXe"))
                        .bienSo(rs.getString("BienSo"))
                        .hanDangKiem(toLocalDate(rs, "HanDangKiem"))
                        .chuKyThang(getInteger(rs, "ChuKyThang"))
                        .tuoiXe(getInteger(rs, "TuoiXe"))
                        .build(),
                bienSo, maLoaiXe, namSanXuat, toSqlDate(ngayDangKiem), maCN, toSqlDate(ngayHienTai));
    }

    /**
     * Gọi SP: sp_XoaXe (xe đã có chuyến → THROW 58004)
     */
    public void xoaXe(String maXe) {
        jdbcTemplate.update("{call sp_XoaXe(?)}", maXe);
    }

    /**
     * Gọi SP: sp_DoiTrangThaiXe
     */
    public void doiTrangThaiXe(String maXe, String trangThai) {
        jdbcTemplate.update("{call sp_DoiTrangThaiXe(?, ?)}", maXe, trangThai);
    }

    /**
     * Gọi SP: sp_LayLichBaoDuong (đọc vw_LichBaoDuong)
     */
    public List<LichXeResponse> layLichBaoDuong(String maXe) {
        return jdbcTemplate.query("{call sp_LayLichBaoDuong(?)}", LICH_MAPPER, maXe);
    }

    /**
     * Gọi SP: sp_LayThamSoKyThuat
     */
    public ThamSoKyThuatResponse layThamSoKyThuat() {
        return jdbcTemplate.queryForObject("{call sp_LayThamSoKyThuat}", (rs, rowNum) -> ThamSoKyThuatResponse.builder()
                .chuKyBd(getInteger(rs, "ChuKyBD"))
                .kmMoiNgayBd(getDouble(rs, "KmMoiNgayBD"))
                .canhBaoNgay(getInteger(rs, "CanhBaoNgay"))
                .chuKyDkCu(getInteger(rs, "ChuKyDkCu"))
                .chuKyDkMoi(getInteger(rs, "ChuKyDkMoi"))
                .tuoiXeCu(getInteger(rs, "TuoiXeCu"))
                .heSoDuongKho1(getDouble(rs, "HeSoDuongKho1"))
                .heSoDuongKho2(getDouble(rs, "HeSoDuongKho2"))
                .heSoDuongKho3(getDouble(rs, "HeSoDuongKho3"))
                .build());
    }

    /**
     * Gọi SP: sp_GhiNhanBaoDuong
     */
    public GhiNhanBaoDuongResponse ghiNhanBaoDuong(String maXe, LocalDate ngayBaoDuong, Double chiPhi,
                                                   String noiDung, LocalDate ngayHienTai) {
        return jdbcTemplate.queryForObject("{call sp_GhiNhanBaoDuong(?, ?, ?, ?, ?)}",
                (rs, rowNum) -> GhiNhanBaoDuongResponse.builder()
                        .maXe(rs.getString("MaXe"))
                        .bienSo(rs.getString("BienSo"))
                        .trangThai(rs.getString("TrangThai"))
                        .ngayBaoDuong(toLocalDate(rs, "NgayBDGanNhat"))
                        .kmLamViec(getDouble(rs, "KmLamViec"))
                        .ngayBDTiepTheo(toLocalDate(rs, "NgayBDTiepTheo"))
                        .build(),
                maXe, toSqlDate(ngayBaoDuong), chiPhi, noiDung, toSqlDate(ngayHienTai));
    }

    /**
     * Gọi SP: sp_GhiNhanDangKiem
     */
    public GhiNhanDangKiemResponse ghiNhanDangKiem(String maXe, LocalDate ngayDangKiem, String ketQua,
                                                   Double chiPhi, LocalDate ngayHienTai) {
        return jdbcTemplate.queryForObject("{call sp_GhiNhanDangKiem(?, ?, ?, ?, ?)}",
                (rs, rowNum) -> GhiNhanDangKiemResponse.builder()
                        .maXe(rs.getString("MaXe"))
                        .bienSo(rs.getString("BienSo"))
                        .ketQua(rs.getString("KetQua"))
                        .ngayHetHan(toLocalDate(rs, "NgayHetHan"))
                        .hanHienHanh(toLocalDate(rs, "HanHienHanh"))
                        .chuKyThang(getInteger(rs, "ChuKyThang"))
                        .tuoiXe(getInteger(rs, "TuoiXe"))
                        .build(),
                maXe, toSqlDate(ngayDangKiem), ketQua, chiPhi, toSqlDate(ngayHienTai));
    }
}
