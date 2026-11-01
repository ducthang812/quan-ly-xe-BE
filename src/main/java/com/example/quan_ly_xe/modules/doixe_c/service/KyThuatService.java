package com.example.quan_ly_xe.modules.doixe_c.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.common.util.CurrentDateProvider;
import com.example.quan_ly_xe.modules.doixe_c.dto.request.GhiNhanBaoDuongRequest;
import com.example.quan_ly_xe.modules.doixe_c.dto.request.GhiNhanDangKiemRequest;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.GhiNhanBaoDuongResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.GhiNhanDangKiemResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.LichBaoDuongResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.LichXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.MucDoSanSangXeResponse;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.MucDoSanSangXeResponse.XeCanhBao;
import com.example.quan_ly_xe.modules.doixe_c.dto.response.ThamSoKyThuatResponse;
import com.example.quan_ly_xe.modules.doixe_c.repository.DoiXeSpRepository;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

/**
 * MH04 Kỹ thuật xe (UC-014, UC-015) và phần xe của khung Mức độ sẵn sàng MH01.0 (UC-001).
 * Lịch tính trong vw_LichBaoDuong (F10, F11, F13); tình trạng F14 do FE tô màu.
 */
@Service
public class KyThuatService {

    private static final String NGUNG_HOAT_DONG = "NgungHD";

    private final DoiXeSpRepository repository;
    private final CurrentDateProvider currentDateProvider;

    public KyThuatService(DoiXeSpRepository repository, CurrentDateProvider currentDateProvider) {
        this.repository = repository;
        this.currentDateProvider = currentDateProvider;
    }

    /**
     * MH04.1, MH04.4: lịch của tất cả xe tại chi nhánh + tham số hiện hành.
     */
    public LichBaoDuongResponse layLichBaoDuong() {
        return LichBaoDuongResponse.builder()
                .ngayHienTai(currentDateProvider.today())
                .thamSo(repository.layThamSoKyThuat())
                .xe(repository.layLichBaoDuong(null))
                .build();
    }

    /**
     * Tham số kỹ thuật cho khung xem trước (MH01 Tab 3: F12, F13).
     */
    public ThamSoKyThuatResponse layThamSoKyThuat() {
        return repository.layThamSoKyThuat();
    }

    /**
     * UC-001 (F16 dòng 3 và dòng cảnh báo bảo dưỡng): xe khác Ngừng hoạt động có hạn
     * đăng kiểm trước hôm nay hoặc chưa có; xe có ngày bảo dưỡng tiếp theo trước hôm nay.
     */
    public MucDoSanSangXeResponse layMucDoSanSang() {
        LocalDate homNay = currentDateProvider.today();
        List<LichXeResponse> xeDangDung = repository.layLichBaoDuong(null).stream()
                .filter(x -> !NGUNG_HOAT_DONG.equals(x.getTrangThai()))
                .toList();

        List<XeCanhBao> hetHanDangKiem = xeDangDung.stream()
                .filter(x -> x.getHanDangKiem() == null || x.getHanDangKiem().isBefore(homNay))
                .map(x -> new XeCanhBao(x.getMaXe(), x.getBienSo(), x.getHanDangKiem()))
                .toList();

        List<XeCanhBao> quaHanBaoDuong = xeDangDung.stream()
                .filter(x -> x.getNgayBDTiepTheo() != null && x.getNgayBDTiepTheo().isBefore(homNay))
                .map(x -> new XeCanhBao(x.getMaXe(), x.getBienSo(), x.getNgayBDTiepTheo()))
                .toList();

        return MucDoSanSangXeResponse.builder()
                .ngayHienTai(homNay)
                .tongSoXe(xeDangDung.size())
                .xeHetHanDangKiem(hetHanDangKiem)
                .xeQuaHanBaoDuong(quaHanBaoDuong)
                .build();
    }

    /**
     * UC-014: sp_GhiNhanBaoDuong (E28 tương lai, E29 trước lần gần nhất, E30 trùng ngày, E31 chi phí âm).
     */
    public GhiNhanBaoDuongResponse ghiNhanBaoDuong(GhiNhanBaoDuongRequest req) {
        LichXeResponse xe = layLichXe(req.getMaXe());
        try {
            return repository.ghiNhanBaoDuong(xe.getMaXe(), req.getNgayBaoDuong(), req.getChiPhi(),
                    req.getNoiDung(), currentDateProvider.today());
        } catch (DataAccessException ex) {
            ErrorCode ec = DoiXeLoiSql.maLoi(ex).orElse(null);
            if (ec == ErrorCode.E29) {
                throw new AppException(ErrorCode.E29, ex, DoiXeLoiSql.ngay(xe.getNgayBDGanNhat()));
            }
            if (ec == ErrorCode.E30) {
                throw new AppException(ErrorCode.E30, ex, DoiXeLoiSql.ngay(req.getNgayBaoDuong()));
            }
            throw ex;
        }
    }

    /**
     * UC-015: sp_GhiNhanDangKiem (E09 tương lai, E31 chi phí âm).
     */
    public GhiNhanDangKiemResponse ghiNhanDangKiem(GhiNhanDangKiemRequest req) {
        LichXeResponse xe = layLichXe(req.getMaXe());
        return repository.ghiNhanDangKiem(xe.getMaXe(), req.getNgayDangKiem(), req.getKetQua(),
                req.getChiPhi(), currentDateProvider.today());
    }

    private LichXeResponse layLichXe(String maXe) {
        return repository.layLichBaoDuong(maXe.trim()).stream()
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("xe", maXe));
    }
}
