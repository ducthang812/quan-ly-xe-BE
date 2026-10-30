package com.example.quan_ly_xe.modules.doixe_c.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

/**
 * UC-001 phần xe của khung Mức độ sẵn sàng (F16 dòng 3 và dòng cảnh báo bảo dưỡng).
 * Chỉ xét xe khác Ngừng hoạt động.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MucDoSanSangXeResponse {
    private LocalDate ngayHienTai;
    private Integer tongSoXe;
    /** Hạn đăng kiểm trước hôm nay hoặc chưa có. */
    private List<XeCanhBao> xeHetHanDangKiem;
    /** Ngày bảo dưỡng tiếp theo (F11) trước hôm nay. */
    private List<XeCanhBao> xeQuaHanBaoDuong;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class XeCanhBao {
        private String maXe;
        private String bienSo;
        private LocalDate han;
    }
}
