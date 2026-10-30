package com.example.quan_ly_xe.modules.cauhinh_a.repository;

import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuLoaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuTuyenReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.DoanhThuXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.LuongTaiXeReportItem;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.TongHopBaoCaoResponse;
import com.example.quan_ly_xe.modules.cauhinh_a.dto.response.XeQuaHanBaoDuongReportItem;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.time.LocalDate;
import java.util.List;

/**
 * Repository thực hiện các truy vấn Báo cáo (UC-016 - MH05) 100% bằng Stored Procedures.
 */
@Repository
public class BaoCaoSpRepository {

    private final JdbcTemplate jdbcTemplate;

    public BaoCaoSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static final RowMapper<TongHopBaoCaoResponse> TONG_HOP_MAPPER = (rs, rowNum) -> TongHopBaoCaoResponse.builder()
            .thang(rs.getString("Thang"))
            .doanhThuThang(rs.getObject("DoanhThuThang") != null ? rs.getDouble("DoanhThuThang") : 0.0)
            .soVeTinhDoanhThu(rs.getObject("SoVeTinhDoanhThu") != null ? rs.getInt("SoVeTinhDoanhThu") : 0)
            .tongLuongTaiXe(rs.getObject("TongLuongTaiXe") != null ? rs.getDouble("TongLuongTaiXe") : 0.0)
            .build();

    private static final RowMapper<LuongTaiXeReportItem> LUONG_TAI_XE_MAPPER = (rs, rowNum) -> LuongTaiXeReportItem.builder()
            .maTX(rs.getString("MaTX"))
            .hoDem(rs.getString("HoDem"))
            .ten(rs.getString("Ten"))
            .hoTen(rs.getString("HoTen"))
            .maCN(rs.getString("MaCN"))
            .tenCN(rs.getString("TenCN"))
            .soChuyenLai(rs.getObject("SoChuyenLai") != null ? rs.getInt("SoChuyenLai") : 0)
            .soChuyenPhu(rs.getObject("SoChuyenPhu") != null ? rs.getInt("SoChuyenPhu") : 0)
            .tongLuong(rs.getObject("TongLuong") != null ? rs.getDouble("TongLuong") : 0.0)
            .build();

    private static final RowMapper<DoanhThuXeReportItem> DOANH_THU_XE_MAPPER = (rs, rowNum) -> DoanhThuXeReportItem.builder()
            .maXe(rs.getString("MaXe"))
            .bienSo(rs.getString("BienSo"))
            .tenLoaiXe(rs.getString("TenLoaiXe"))
            .maCN(rs.getString("MaCN"))
            .tenCN(rs.getString("TenCN"))
            .soChuyen(rs.getObject("SoChuyen") != null ? rs.getInt("SoChuyen") : 0)
            .soVe(rs.getObject("SoVe") != null ? rs.getInt("SoVe") : 0)
            .doanhThu(rs.getObject("DoanhThu") != null ? rs.getDouble("DoanhThu") : 0.0)
            .tyLe(rs.getObject("TyLe") != null ? rs.getDouble("TyLe") : 0.0)
            .build();

    private static final RowMapper<DoanhThuTuyenReportItem> DOANH_THU_TUYEN_MAPPER = (rs, rowNum) -> DoanhThuTuyenReportItem.builder()
            .maTuyen(rs.getString("MaTuyen"))
            .tenTuyen(rs.getString("TenTuyen"))
            .capDo(rs.getObject("CapDo") != null ? rs.getInt("CapDo") : 1)
            .doDaiKm(rs.getObject("DoDaiKm") != null ? rs.getDouble("DoDaiKm") : 0.0)
            .soChuyen(rs.getObject("SoChuyen") != null ? rs.getInt("SoChuyen") : 0)
            .soVe(rs.getObject("SoVe") != null ? rs.getInt("SoVe") : 0)
            .doanhThu(rs.getObject("DoanhThu") != null ? rs.getDouble("DoanhThu") : 0.0)
            .tyLe(rs.getObject("TyLe") != null ? rs.getDouble("TyLe") : 0.0)
            .build();

    private static final RowMapper<DoanhThuLoaiXeReportItem> DOANH_THU_LOAI_XE_MAPPER = (rs, rowNum) -> DoanhThuLoaiXeReportItem.builder()
            .maLoaiXe(rs.getString("MaLoaiXe"))
            .tenLoaiXe(rs.getString("TenLoaiXe"))
            .soGhe(rs.getObject("SoGhe") != null ? rs.getInt("SoGhe") : 0)
            .soChuyen(rs.getObject("SoChuyen") != null ? rs.getInt("SoChuyen") : 0)
            .soVe(rs.getObject("SoVe") != null ? rs.getInt("SoVe") : 0)
            .doanhThu(rs.getObject("DoanhThu") != null ? rs.getDouble("DoanhThu") : 0.0)
            .tyLe(rs.getObject("TyLe") != null ? rs.getDouble("TyLe") : 0.0)
            .build();

    private static final RowMapper<XeQuaHanBaoDuongReportItem> XE_QUA_HAN_MAPPER = (rs, rowNum) -> {
        Date ngaySdSql = rs.getDate("NgayDuaVaoSD");
        LocalDate ngaySd = ngaySdSql != null ? ngaySdSql.toLocalDate() : null;

        Date ngayBdSql = rs.getDate("NgayBaoDuongGanNhat");
        LocalDate ngayBd = ngayBdSql != null ? ngayBdSql.toLocalDate() : null;

        Date ngayTiepTheoSql = rs.getDate("NgayBaoDuongTiepTheo");
        LocalDate ngayTiepTheo = ngayTiepTheoSql != null ? ngayTiepTheoSql.toLocalDate() : null;

        return XeQuaHanBaoDuongReportItem.builder()
                .maXe(rs.getString("MaXe"))
                .bienSo(rs.getString("BienSo"))
                .tenLoaiXe(rs.getString("TenLoaiXe"))
                .maCN(rs.getString("MaCN"))
                .tenCN(rs.getString("TenCN"))
                .ngayDuaVaoSD(ngaySd)
                .ngayBaoDuongGanNhat(ngayBd)
                .kmLamViec(rs.getObject("KmLamViec") != null ? rs.getDouble("KmLamViec") : 0.0)
                .ngayBaoDuongTiepTheo(ngayTiepTheo)
                .soNgayQuaHan(rs.getObject("SoNgayQuaHan") != null ? rs.getInt("SoNgayQuaHan") : 0)
                .build();
    };

    /**
     * Lấy danh sách các tháng có chuyến (MH05 Combobox Tháng).
     * Mặc định đầu tiên lúc nào cũng là tháng hiện tại xong mới đến các tháng có dữ liệu.
     */
    public List<String> layDanhSachThangCoChuyen(String thangHienTai) {
        return jdbcTemplate.query("{call sp_LayDanhSachThangCoChuyen(?)}", (rs, rowNum) -> rs.getString("Thang"), thangHienTai);
    }

    public List<String> layDanhSachThangCoChuyen() {
        return layDanhSachThangCoChuyen(null);
    }

    /**
     * Lấy 3 ô số tổng (F15 Doanh thu, Số vé, F02 Tổng lương tài xế).
     */
    public TongHopBaoCaoResponse layTongHopSoLieuThang(String thang, String maCN) {
        List<TongHopBaoCaoResponse> list = jdbcTemplate.query("{call sp_TongHopSoLieuThang(?, ?)}", TONG_HOP_MAPPER, thang, maCN);
        if (list.isEmpty()) {
            return TongHopBaoCaoResponse.builder()
                    .thang(thang)
                    .doanhThuThang(0.0)
                    .soVeTinhDoanhThu(0)
                    .tongLuongTaiXe(0.0)
                    .build();
        }
        return list.get(0);
    }

    /**
     * Tab 1: Lương tài xế (sp_R01).
     */
    public List<LuongTaiXeReportItem> layBaoCaoLuongTaiXe(String thang, String maCN) {
        return jdbcTemplate.query("{call sp_R01(?, ?)}", LUONG_TAI_XE_MAPPER, thang, maCN);
    }

    /**
     * Tab 2: Doanh thu theo xe (sp_R02).
     */
    public List<DoanhThuXeReportItem> layBaoCaoDoanhThuTheoXe(String thang, String maCN) {
        return jdbcTemplate.query("{call sp_R02(?, ?)}", DOANH_THU_XE_MAPPER, thang, maCN);
    }

    /**
     * Tab 3: Doanh thu theo tuyến (sp_R03).
     */
    public List<DoanhThuTuyenReportItem> layBaoCaoDoanhThuTheoTuyen(String thang, String maCN) {
        return jdbcTemplate.query("{call sp_R03(?, ?)}", DOANH_THU_TUYEN_MAPPER, thang, maCN);
    }

    /**
     * Tab 4: Doanh thu theo loại xe (sp_R04).
     */
    public List<DoanhThuLoaiXeReportItem> layBaoCaoDoanhThuTheoLoaiXe(String thang, String maCN) {
        return jdbcTemplate.query("{call sp_R04(?, ?)}", DOANH_THU_LOAI_XE_MAPPER, thang, maCN);
    }

    /**
     * Tab 5: Xe quá hạn bảo dưỡng (sp_R06).
     */
    public List<XeQuaHanBaoDuongReportItem> layBaoCaoXeQuaHanBaoDuong(LocalDate ngayXet, String maCN) {
        Date ngayXetSql = ngayXet != null ? Date.valueOf(ngayXet) : null;
        return jdbcTemplate.query("{call sp_R06(?, ?)}", XE_QUA_HAN_MAPPER, ngayXetSql, maCN);
    }
}

