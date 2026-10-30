package com.example.quan_ly_xe.common.util;

/**
 * Nơi tập trung mọi chuỗi/hằng dùng chung trong tầng base, thay cho việc rải
 * "magic string" khắp code. A/B/C tham chiếu vào đây để đổi một chỗ là đổi
 * mọi nơi, và tránh gõ sai mã lỗi, tên ràng buộc, tên cột...
 * <p>
 * Nhóm theo mục đích bằng các lớp con tĩnh. Các giá trị đều là hằng biên dịch
 * nên dùng được cả trong annotation ({@code @Column}, {@code @RequestMapping},
 * {@code @Value}).
 */
public final class Constant {

    private Constant() {
    }

    /** Hằng số của module vận hành chuyến xe và bán vé. */
    public static final class VanHanh {
        private VanHanh() {
        }

        public static final String TRANG_THAI_KE_HOACH = "KeHoach";
        public static final String TRANG_THAI_DANG_CHAY = "DangChay";
        public static final String TRANG_THAI_HOAN_THANH = "HoanThanh";
        public static final String TRANG_THAI_HUY = "Huy";
        public static final String TRANG_THAI_VE_DA_BAN = "DaBan";
        public static final String TRANG_THAI_VE_DA_HUY = "DaHuy";
        public static final String VAI_TRO_LAI = "LAI";
        public static final String VAI_TRO_PHU = "PHU";
        public static final String REGEX_SO_DIEN_THOAI = "^0\\d{9}$";

        public static final String SP_TAO_CHUYEN = "sp_TaoChuyenVaPhanCong";
        public static final String SP_KET_THUC_CHUYEN = "sp_KetThucChuyen";
        public static final String SP_BAN_VE = "sp_BanVe";
        public static final String SP_HUY_CHUYEN = "sp_HuyChuyen";
        public static final String SP_HUY_VE = "sp_HuyVe";
        public static final String SP_LAY_DANH_SACH_CHUYEN = "sp_LayDanhSachChuyen";
        public static final String SP_LAY_CHI_TIET_CHUYEN = "sp_LayChiTietChuyen";
        public static final String SP_XEM_TRUOC_CHUYEN = "sp_XemTruocChuyen";
        public static final String SP_LAY_SO_DO_GHE = "sp_LaySoDoGhe";
        public static final String SP_LAY_DANH_SACH_VE_THEO_CHUYEN = "sp_LayDanhSachVeTheoChuyen";
        public static final String SP_TRA_CUU_VE_THEO_SDT = "sp_TraCuuVeTheoSDT";
    }

    /** Đường dẫn REST. */
    public static final class Api {
        private Api() {
        }

        /** Endpoint kiểm tra sống. */
        public static final String HEALTH_PATH = "/health";
    }

    /** Tên cột kiểm toán ở {@link com.example.quan_ly_xe.common.entity.BaseEntity}. */
    public static final class Column {
        private Column() {
        }

        public static final String NGAY_TAO = "NgayTao";
        public static final String NGAY_CAP_NHAT = "NgayCapNhat";
    }

    /** Khóa cấu hình trong application.yaml. */
    public static final class ConfigKey {
        private ConfigKey() {
        }

        public static final String CURRENT_DATE = "app.current-date";
        /** Biểu thức dùng cho {@code @Value} (có giá trị mặc định rỗng). */
        public static final String CURRENT_DATE_EXPR = "${app.current-date:}";
    }

    /**
     * Ngữ cảnh "nhân viên hiện hành" cho bản demo (không đăng nhập, không mật khẩu).
     * Client gửi kèm các header dưới đây; thiếu thì dùng nhân viên demo mặc định.
     */
    public static final class Security {
        private Security() {
        }

        public static final String HEADER_MA_NV = "X-MaNV";
        public static final String HEADER_MA_CN = "X-MaCN";
        public static final String HEADER_VAI_TRO = "X-VaiTro";

        // Biểu thức @Value cho nhân viên demo mặc định khi request không có header.
        public static final String DEFAULT_MA_NV_EXPR = "${app.auth.default-ma-nv:NV001}";
        public static final String DEFAULT_HO_TEN_EXPR = "${app.auth.default-ho-ten:Nhân viên demo}";
        public static final String DEFAULT_MA_CN_EXPR = "${app.auth.default-ma-cn:CN01}";
        public static final String DEFAULT_VAI_TRO_EXPR = "${app.auth.default-vai-tro:QUAN_LY}";
    }

    /** Khóa/giá trị dùng ở {@link com.example.quan_ly_xe.common.web.HealthController}. */
    public static final class Health {
        private Health() {
        }

        public static final String KEY_STATUS = "status";
        public static final String KEY_TODAY = "today";
        public static final String KEY_USER = "user";
        public static final String STATUS_UP = "UP";
    }

    /** Thông điệp chung không gắn với một mã lỗi cụ thể. */
    public static final class Message {
        private Message() {
        }

        public static final String INVALID_INPUT_VI = "Dữ liệu nhập chưa hợp lệ.";
        public static final String INVALID_INPUT_EN = "Invalid input.";
    }

    /**
     * Mã lỗi của lệnh {@code THROW} trong SQL Server (số ≥ 50000), đặt trong
     * {@code MESSAGE_TEXT}/số lỗi để BE ánh xạ về {@link com.example.quan_ly_xe.common.exception.ErrorCode}.
     */
    public static final class ThrowCode {
        private ThrowCode() {
        }

        public static final String N50101 = "50101"; // vượt số chỗ (TR01)
        public static final String N50102 = "50102"; // chuyến không mở bán (TR01)
        public static final String N50103 = "50103"; // vượt số chỗ (TR01)
        public static final String N50201 = "50201"; // tuyến chưa có giá (TR02)
        public static final String N50301 = "50301"; // tài xế không đang làm (TR03)
        public static final String N50302 = "50302"; // tài xế trùng giờ (TR03)
        public static final String N50401 = "50401"; // xe không hoạt động (TR04)
        public static final String N50402 = "50402"; // xe trùng giờ (TR04)
        public static final String N50403 = "50403"; // xe hết hạn đăng kiểm (TR04)
        public static final String N50404 = "50404"; // xe quá hạn bảo dưỡng (TR04)
        public static final String N50601 = "50601"; // kết thúc chuyến thiếu điều kiện (TR06)
        public static final String N51001 = "51001"; // chuyến không mở bán (sp_BanVe)
        public static final String N51002 = "51002"; // chuyến không mở bán (sp_BanVe)
        public static final String N51003 = "51003"; // ghế đã có người (sp_BanVe)
        public static final String N53001 = "53001"; // lái trùng phụ (sp_TaoChuyenVaPhanCong)
        public static final String N54001 = "54001"; // chuyến không thể hủy
        public static final String N54002 = "54002"; // vé đã hủy trước đó
        public static final String N54003 = "54003"; // hết số thứ tự chuyến trong ngày
        public static final String N55001 = "55001"; // ngày bảo dưỡng ở tương lai
        public static final String N55002 = "55002"; // ngày bảo dưỡng trước lần gần nhất
        public static final String N57001 = "57001"; // thiếu giá khi thêm tuyến
        public static final String N58001 = "58001"; // ngày đăng kiểm ở tương lai (thêm xe)
        public static final String N59001 = "59001"; // ngày đăng kiểm ở tương lai (gia hạn)
    }

    /** Tên ràng buộc CK/UQ/FK/PK để ánh xạ lỗi khai báo về mã nghiệp vụ. */
    public static final class ConstraintName {
        private ConstraintName() {
        }

        public static final String CK_DO_PHUC_TAP_HSDK = "CK_DoPhucTap_HSDK";
        public static final String CK_TUYEN_DIEM_KHAC_NHAU = "CK_Tuyen_DiemKhacNhau";
        public static final String CK_TUYEN_DO_DAI = "CK_Tuyen_DoDai";
        public static final String UQ_XE_BIEN_SO = "UQ_Xe_BienSo";
        public static final String CK_XE_NAM_SX = "CK_Xe_NamSX";
        public static final String FK_CHUYEN_XE = "FK_Chuyen_Xe";
        public static final String UQ_TX_CCCD = "UQ_TX_CCCD";
        public static final String CK_TX_TUOI = "CK_TX_Tuoi";
        public static final String UQ_PC_CHUYEN_VAI_TRO = "UQ_PC_ChuyenVaiTro";
        public static final String PK_BAO_DUONG = "PK_BaoDuong";
        public static final String CK_BD_CHI_PHI = "CK_BD_ChiPhi";
        public static final String CK_DK_CHI_PHI = "CK_DK_ChiPhi";
        public static final String CK_CHUYEN_CHI_PHI = "CK_Chuyen_ChiPhi";
        public static final String CK_GIA_GIA_VE = "CK_Gia_GiaVe";
        /** Tiền tố chung cho các CK của bảng DoPhucTap còn lại. */
        public static final String CK_DO_PHUC_TAP_PREFIX = "CK_DoPhucTap_";
    }

    /**
     * Thông báo lỗi song ngữ E01–E32 (mục 10 SRS). {@link com.example.quan_ly_xe.common.exception.ErrorCode}
     * tham chiếu vào đây; {@code {0}} là tham số điền lúc chạy.
     */
    public static final class ErrorMessage {
        private ErrorMessage() {
        }

        public static final String E01_VI = "Vui lòng nhập {0}.";
        public static final String E01_EN = "Please enter {0}.";
        public static final String E02_VI = "Giá trị phải lớn hơn 0.";
        public static final String E02_EN = "Value must be greater than 0.";
        public static final String E03_VI = "Hệ số đường khó phải từ 1 trở lên.";
        public static final String E03_EN = "Road difficulty factor must be at least 1.";
        public static final String E04_VI = "Điểm đầu và điểm cuối phải khác nhau.";
        public static final String E04_EN = "Origin and destination must be different.";
        public static final String E05_VI = "Độ dài tuyến phải lớn hơn 0 km.";
        public static final String E05_EN = "Route length must be greater than 0 km.";
        public static final String E06_VI = "Nhập đủ 4 mức giá lớn hơn 0. Tuyến chưa được lưu.";
        public static final String E06_EN = "Enter all 4 prices above 0. The route was not saved.";
        public static final String E07_VI = "Biển số {0} đã tồn tại.";
        public static final String E07_EN = "Plate number {0} already exists.";
        public static final String E08_VI = "Năm sản xuất phải từ 2005 đến năm hiện tại.";
        public static final String E08_EN = "Manufacturing year must be between 2005 and this year.";
        public static final String E09_VI = "Ngày đăng kiểm không được sau hôm nay.";
        public static final String E09_EN = "Inspection date cannot be in the future.";
        public static final String E10_VI = "Không xóa được xe đã có chuyến. Hãy đổi trạng thái sang Ngừng hoạt động.";
        public static final String E10_EN = "This vehicle has trips and cannot be deleted. Set it to Inactive instead.";
        public static final String E11_VI = "CCCD phải gồm đúng 12 chữ số.";
        public static final String E11_EN = "Citizen ID must have exactly 12 digits.";
        public static final String E12_VI = "CCCD đã tồn tại.";
        public static final String E12_EN = "Citizen ID already exists.";
        public static final String E13_VI = "Tài xế phải từ 21 tuổi trở lên.";
        public static final String E13_EN = "Driver must be at least 21 years old.";
        public static final String E14_VI = "Lái xe và phụ xe phải là 2 người khác nhau.";
        public static final String E14_EN = "Driver and assistant must be different people.";
        public static final String E15_VI = "Xe không ở trạng thái Hoạt động.";
        public static final String E15_EN = "Vehicle is not active.";
        public static final String E16_VI = "Xe đã có chuyến khác trùng giờ.";
        public static final String E16_EN = "Vehicle already has an overlapping trip.";
        public static final String E17_VI = "Xe chưa đăng kiểm hoặc đã hết hạn tại ngày khởi hành.";
        public static final String E17_EN = "Vehicle inspection is missing or expired on the departure date.";
        public static final String E18_VI = "Xe đã quá hạn bảo dưỡng tại ngày khởi hành.";
        public static final String E18_EN = "Vehicle maintenance is overdue on the departure date.";
        public static final String E19_VI = "Tài xế {0} đã có chuyến trùng giờ. Chuyến chưa được tạo.";
        public static final String E19_EN = "Driver {0} has an overlapping trip. The trip was not created.";
        public static final String E20_VI = "Chuyến đã có đủ lái xe và phụ xe.";
        public static final String E20_EN = "This trip already has a driver and an assistant.";
        public static final String E21_VI = "Cần có số km lớn hơn 0 và đủ 1 lái, 1 phụ để hoàn thành chuyến.";
        public static final String E21_EN = "Enter distance above 0 and assign a driver and an assistant to complete the trip.";
        public static final String E22_VI = "Chọn một ghế trống trên sơ đồ.";
        public static final String E22_EN = "Select an available seat on the map.";
        public static final String E23_VI = "Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0.";
        public static final String E23_EN = "Phone number must be 10 digits starting with 0.";
        public static final String E24_VI = "Ghế đã có người đặt. Vui lòng chọn ghế khác.";
        public static final String E24_EN = "This seat is taken. Please choose another seat.";
        public static final String E25_VI = "Chuyến không còn mở bán.";
        public static final String E25_EN = "This trip is no longer open for sale.";
        public static final String E26_VI = "Chuyến đã hết chỗ.";
        public static final String E26_EN = "This trip is fully booked.";
        public static final String E27_VI = "Tuyến chưa có giá cho loại ngày này. Nhập ở Thiết lập › Tuyến và giá vé.";
        public static final String E27_EN = "No fare set for this route on this day type. Add it in Setup › Routes and fares.";
        public static final String E28_VI = "Ngày bảo dưỡng không được sau hôm nay.";
        public static final String E28_EN = "Maintenance date cannot be in the future.";
        public static final String E29_VI = "Ngày bảo dưỡng phải sau lần gần nhất ({0}).";
        public static final String E29_EN = "Maintenance date must be after the last one ({0}).";
        public static final String E30_VI = "Xe đã có lần bảo dưỡng ngày {0}.";
        public static final String E30_EN = "This vehicle already has a maintenance record on {0}.";
        public static final String E31_VI = "Chi phí phải là số không âm.";
        public static final String E31_EN = "Cost must be zero or greater.";
        public static final String E32_VI = "Không kết nối được cơ sở dữ liệu. Vui lòng thử lại.";
        public static final String E32_EN = "Cannot connect to the database. Please try again.";
        public static final String DRIVER_NOT_ACTIVE_VI = "Tài xế {0} không ở trạng thái Đang làm.";
        public static final String DRIVER_NOT_ACTIVE_EN = "Driver {0} is not active.";
        public static final String TRIP_NOT_CANCELLABLE_VI = "Chỉ hủy được chuyến đang Kế hoạch.";
        public static final String TRIP_NOT_CANCELLABLE_EN = "Only a planned trip can be cancelled.";
        public static final String TICKET_ALREADY_CANCELLED_VI = "Vé đã được hủy trước đó.";
        public static final String TICKET_ALREADY_CANCELLED_EN = "The ticket has already been cancelled.";
        public static final String TRIP_CODE_EXHAUSTED_VI = "Đã hết số thứ tự chuyến trong ngày.";
        public static final String TRIP_CODE_EXHAUSTED_EN = "The daily trip-code sequence has been exhausted.";
        public static final String NOT_FOUND_VI = "Không tìm thấy {0}.";
        public static final String NOT_FOUND_EN = "{0} not found.";
        public static final String FORBIDDEN_VI = "Không có quyền thực hiện thao tác: {0}";
        public static final String FORBIDDEN_EN = "Forbidden operation: {0}";
        public static final String INTERNAL_VI = "Đã xảy ra lỗi không mong muốn.";
        public static final String INTERNAL_EN = "An unexpected error occurred.";
    }
}
