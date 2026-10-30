package com.example.quan_ly_xe.modules.vanhanh_b.repository;

import com.example.quan_ly_xe.common.util.Constant;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.CreateTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.FinishTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SeatItem;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SeatMapResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TripPreviewResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TripResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Repository
public class TripSpRepository {
    private final JdbcTemplate jdbcTemplate;

    public TripSpRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private static final RowMapper<TripResponse> TRIP_MAPPER = (rs, rowNum) -> TripResponse.builder()
            .maChuyen(rs.getString("MaChuyen")).maTuyen(rs.getString("MaTuyen"))
            .tenTuyen(rs.getString("TenTuyen")).doDaiKm(rs.getBigDecimal("DoDaiKm"))
            .maXe(rs.getString("MaXe")).bienSo(rs.getString("BienSo"))
            .gioKhoiHanhDK(localDateTime(rs.getTimestamp("GioKhoiHanhDK")))
            .gioDenDK(localDateTime(rs.getTimestamp("GioDenDK")))
            .gioKhoiHanhTT(localDateTime(rs.getTimestamp("GioKhoiHanhTT")))
            .gioDenTT(localDateTime(rs.getTimestamp("GioDenTT")))
            .kmThucTe(nullableInteger(rs, "KmThucTe"))
            .chiPhiVanHanh(getDecimalIfPresent(rs, "ChiPhiVanHanh"))
            .maTXLai(rs.getString("MaTXLai")).tenTXLai(rs.getString("TenTXLai"))
            .thuLaoLai(getDecimalIfPresent(rs, "ThuLaoLai"))
            .maTXPhu(rs.getString("MaTXPhu")).tenTXPhu(rs.getString("TenTXPhu"))
            .thuLaoPhu(getDecimalIfPresent(rs, "ThuLaoPhu"))
            .daBan(nullableInteger(rs, "DaBan")).soCho(nullableInteger(rs, "SoCho"))
            .trangThai(rs.getString("TrangThai")).build();

    public List<TripResponse> findAll(String trangThai, String maCN, LocalDate tuNgay, LocalDate denNgay) {
        return jdbcTemplate.query(call(Constant.VanHanh.SP_LAY_DANH_SACH_CHUYEN, 4), TRIP_MAPPER,
                trangThai, maCN, sqlDate(tuNgay), sqlDate(denNgay));
    }

    public Optional<TripResponse> findById(String maChuyen) {
        List<TripResponse> rows = jdbcTemplate.query(call(Constant.VanHanh.SP_LAY_CHI_TIET_CHUYEN, 1),
                TRIP_MAPPER, maChuyen);
        return rows.stream().findFirst();
    }

    public Optional<TripPreviewResponse> preview(String maTuyen, LocalDateTime gioKhoiHanh,
                                                  String maTXLai, String maTXPhu) {
        List<TripPreviewResponse> rows = jdbcTemplate.query(call(Constant.VanHanh.SP_XEM_TRUOC_CHUYEN, 4),
                (rs, rowNum) -> TripPreviewResponse.builder()
                        .maTuyen(rs.getString("MaTuyen")).maLoaiNgay(rs.getString("MaLoaiNgay"))
                        .giaVe(rs.getBigDecimal("GiaVe"))
                        .gioDenGoiY(localDateTime(rs.getTimestamp("GioDenGoiY")))
                        .thuLaoLai(rs.getBigDecimal("ThuLaoLai")).thuLaoPhu(rs.getBigDecimal("ThuLaoPhu"))
                        .build(), maTuyen, timestamp(gioKhoiHanh), maTXLai, maTXPhu);
        return rows.stream().findFirst();
    }

    public Optional<String> create(CreateTripRequest request) {
        List<String> rows = jdbcTemplate.query(call(Constant.VanHanh.SP_TAO_CHUYEN, 7),
                (rs, rowNum) -> rs.getString("MaChuyen"), request.getMaTuyen(), request.getMaXe(),
                timestamp(request.getGioKhoiHanh()), timestamp(request.getGioDen()), request.getMaLai(),
                request.getMaPhu(), request.getMaChuyen());
        return rows.stream().findFirst();
    }

    public Optional<String> cancel(String maChuyen) {
        return singleCode(Constant.VanHanh.SP_HUY_CHUYEN, "MaChuyen", maChuyen);
    }

    public Optional<String> finish(String maChuyen, FinishTripRequest request) {
        List<String> rows = jdbcTemplate.query(call(Constant.VanHanh.SP_KET_THUC_CHUYEN, 5),
                (rs, rowNum) -> rs.getString("MaChuyen"), maChuyen,
                timestamp(request.getGioKhoiHanhTT()), timestamp(request.getGioDenTT()),
                request.getKmThucTe(), request.getChiPhiVanHanh());
        return rows.stream().findFirst();
    }

    public Optional<SeatMapResponse> seatMap(String maChuyen) {
        return jdbcTemplate.query(call(Constant.VanHanh.SP_LAY_SO_DO_GHE, 1),
                (org.springframework.jdbc.core.ResultSetExtractor<Optional<SeatMapResponse>>) TripSpRepository::mapSeatMap,
                maChuyen);
    }

    private Optional<String> singleCode(String procedure, String column, String value) {
        List<String> rows = jdbcTemplate.query(call(procedure, 1),
                (rs, rowNum) -> rs.getString(column), value);
        return rows.stream().findFirst();
    }

    private static Optional<SeatMapResponse> mapSeatMap(ResultSet rs) throws java.sql.SQLException {
        if (!rs.next()) return Optional.empty();
        SeatMapResponse response = SeatMapResponse.builder()
                .maChuyen(rs.getString("MaChuyen")).maTuyen(rs.getString("MaTuyen"))
                .tenTuyen(rs.getString("TenTuyen")).maXe(rs.getString("MaXe"))
                .bienSo(rs.getString("BienSo"))
                .gioKhoiHanhDK(localDateTime(rs.getTimestamp("GioKhoiHanhDK")))
                .maLoaiNgay(rs.getString("MaLoaiNgay")).giaVe(rs.getBigDecimal("GiaVe"))
                .danhSachGhe(new ArrayList<>()).build();
        do {
            response.getDanhSachGhe().add(SeatItem.builder().soGhe(nullableInteger(rs, "SoGhe"))
                    .coTheBan(nullableBoolean(rs, "CoTheBan")).maVe(rs.getString("MaVe"))
                    .daBan(nullableBoolean(rs, "DaBan")).build());
        } while (rs.next());
        return Optional.of(response);
    }

    private static String call(String procedure, int parameters) {
        return "{call " + procedure + "(" + String.join(",", java.util.Collections.nCopies(parameters, "?")) + ")}";
    }
    private static Date sqlDate(LocalDate value) { return value == null ? null : Date.valueOf(value); }
    private static Timestamp timestamp(LocalDateTime value) { return value == null ? null : Timestamp.valueOf(value); }
    private static LocalDateTime localDateTime(Timestamp value) { return value == null ? null : value.toLocalDateTime(); }
    private static Integer nullableInteger(ResultSet rs, String column) throws java.sql.SQLException {
        try {
            Object value = rs.getObject(column); return value == null ? null : ((Number) value).intValue();
        } catch (java.sql.SQLException ignored) {
            return null;
        }
    }
    private static Boolean nullableBoolean(ResultSet rs, String column) throws java.sql.SQLException {
        Object value = rs.getObject(column); return value == null ? null : rs.getBoolean(column);
    }
    private static java.math.BigDecimal getDecimalIfPresent(ResultSet rs, String column) {
        try { return rs.getBigDecimal(column); } catch (java.sql.SQLException ignored) { return null; }
    }
}
