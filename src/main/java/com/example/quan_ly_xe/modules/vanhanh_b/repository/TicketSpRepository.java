package com.example.quan_ly_xe.modules.vanhanh_b.repository;

import com.example.quan_ly_xe.common.util.Constant;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.SellTicketRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SellTicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TicketResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;

@Repository
public class TicketSpRepository {
    private final JdbcTemplate jdbcTemplate;

    public TicketSpRepository(JdbcTemplate jdbcTemplate) { this.jdbcTemplate = jdbcTemplate; }

    public Optional<SellTicketResponse> sell(SellTicketRequest request, String maNVBan) {
        List<SellTicketResponse> rows = jdbcTemplate.query(call(Constant.VanHanh.SP_BAN_VE, 7),
                (rs, rowNum) -> SellTicketResponse.builder().maVe(rs.getString("MaVe"))
                        .giaVe(rs.getBigDecimal("GiaVe")).lanBan(rs.getInt("LanBan")).build(),
                request.getMaChuyen(), request.getSoGhe(), request.getHoTen(), request.getSoDienThoai(),
                request.getCccd(), request.getEmail(), maNVBan);
        return rows.stream().findFirst();
    }

    public Optional<String> cancel(String maVe) {
        List<String> rows = jdbcTemplate.query(call(Constant.VanHanh.SP_HUY_VE, 1),
                (rs, rowNum) -> rs.getString("MaVe"), maVe);
        return rows.stream().findFirst();
    }

    public List<TicketResponse> findByPhone(String soDienThoai) {
        return jdbcTemplate.query(call(Constant.VanHanh.SP_TRA_CUU_VE_THEO_SDT, 1),
                (rs, rowNum) -> {
                    Timestamp ngayBan = rs.getTimestamp("NgayBan");
                    return TicketResponse.builder().maVe(rs.getString("MaVe")).hoTen(rs.getString("HoTen"))
                            .soDienThoai(rs.getString("SoDienThoai")).maChuyen(rs.getString("MaChuyen"))
                            .maTuyen(rs.getString("MaTuyen")).tenTuyen(rs.getString("TenTuyen"))
                            .soGhe(rs.getInt("SoGhe")).giaVe(rs.getBigDecimal("GiaVe"))
                            .ngayBan(ngayBan == null ? null : ngayBan.toLocalDateTime())
                            .trangThai(rs.getString("TrangThai")).build();
                }, soDienThoai);
    }

    private static String call(String procedure, int parameters) {
        return "{call " + procedure + "(" + String.join(",", java.util.Collections.nCopies(parameters, "?")) + ")}";
    }
}
