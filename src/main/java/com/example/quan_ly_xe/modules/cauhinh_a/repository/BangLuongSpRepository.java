package com.example.quan_ly_xe.modules.cauhinh_a.repository;

import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.BangLuongResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TrangThaiChotLuongResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository thao tác bảng BangLuong thuần túy bằng Stored Procedures (UC-017).
 */
@Repository
public class BangLuongSpRepository {

    private final JdbcTemplate jdbcTemplate;

    public BangLuongSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static final RowMapper<TrangThaiChotLuongResponse> TRANG_THAI_MAPPER = (rs, rowNum) -> {
        Timestamp ngayChotSql = rs.getTimestamp("NgayChot");
        LocalDateTime ngayChot = ngayChotSql != null ? ngayChotSql.toLocalDateTime() : null;

        return TrangThaiChotLuongResponse.builder()
                .thang(rs.getString("Thang"))
                .daChot(rs.getBoolean("DaChot"))
                .soDong(rs.getObject("SoDong") != null ? rs.getInt("SoDong") : 0)
                .tongLuong(rs.getObject("TongLuong") != null ? rs.getDouble("TongLuong") : 0.0)
                .ngayChot(ngayChot)
                .thongBao(rs.getString("ThongBao"))
                .build();
    };

    private static final RowMapper<BangLuongResponse> BANG_LUONG_MAPPER = (rs, rowNum) -> {
        Timestamp ngayChotSql = rs.getTimestamp("NgayChot");
        LocalDateTime ngayChot = ngayChotSql != null ? ngayChotSql.toLocalDateTime() : null;

        return BangLuongResponse.builder()
                .maTX(rs.getString("MaTX"))
                .hoTen(rs.getString("HoTen"))
                .maCN(rs.getString("MaCN"))
                .tenCN(rs.getString("TenCN"))
                .thang(rs.getString("Thang"))
                .soChuyenLai(rs.getObject("SoChuyenLai") != null ? rs.getInt("SoChuyenLai") : 0)
                .soChuyenPhu(rs.getObject("SoChuyenPhu") != null ? rs.getInt("SoChuyenPhu") : 0)
                .tongLuong(rs.getObject("TongLuong") != null ? rs.getDouble("TongLuong") : 0.0)
                .ngayChot(ngayChot)
                .build();
    };

    /**
     * Kiểm tra trạng thái chốt lương của tháng (MH05 - sp_KiemTraTrangThaiChotLuong).
     */
    public TrangThaiChotLuongResponse kiemTraTrangThaiChotLuong(String thang, String maCN) {
        List<TrangThaiChotLuongResponse> list = jdbcTemplate.query(
                "{call sp_KiemTraTrangThaiChotLuong(?, ?)}", TRANG_THAI_MAPPER, thang, maCN);
        if (list.isEmpty()) {
            return TrangThaiChotLuongResponse.builder()
                    .thang(thang)
                    .daChot(false)
                    .soDong(0)
                    .tongLuong(0.0)
                    .thongBao("Tháng " + thang + " chưa chốt lương")
                    .build();
        }
        return list.get(0);
    }

    /**
     * Chốt lương tháng (UC-017 - sp_ChotLuongThang).
     */
    public TrangThaiChotLuongResponse chotLuongThang(String thang, String maCN) {
        List<TrangThaiChotLuongResponse> list = jdbcTemplate.query(
                "{call sp_ChotLuongThang(?, ?)}",
                (rs, rowNum) -> {
                    Timestamp ngayChotSql = rs.getTimestamp("NgayChot");
                    LocalDateTime ngayChot = ngayChotSql != null ? ngayChotSql.toLocalDateTime() : null;
                    Double tongLuong = null;
                    try {
                        tongLuong = rs.getDouble("TongLuong");
                    } catch (Exception ignored) {
                        try {
                            tongLuong = rs.getDouble("TongTienLuong");
                        } catch (Exception ignored2) {
                            tongLuong = 0.0;
                        }
                    }

                    return TrangThaiChotLuongResponse.builder()
                            .thang(rs.getString("Thang"))
                            .daChot(true)
                            .soDong(rs.getInt("SoDong"))
                            .tongLuong(tongLuong != null ? tongLuong : 0.0)
                            .ngayChot(ngayChot)
                            .thongBao(rs.getString("ThongBao"))
                            .build();
                },
                thang, maCN);
        return list.get(0);
    }

    /**
     * Lấy danh sách các dòng bảng lương đã chốt.
     */
    public List<BangLuongResponse> layDanhSachBangLuong(String thang, String maCN) {
        return jdbcTemplate.query("{call sp_LayDanhSachBangLuong(?, ?)}", BANG_LUONG_MAPPER, thang, maCN);
    }
}
