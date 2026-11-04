package com.example.quan_ly_xe.common.security;

import com.example.quan_ly_xe.common.util.Constant;
import com.example.quan_ly_xe.shared.routing.BranchContextHolder;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/**
 * Lấy nhân viên hiện hành từ header request (demo, không xác thực):
 * {@code X-MaNV}, {@code X-MaCN}, {@code X-VaiTro}. Thiếu header nào thì dùng
 * giá trị demo mặc định trong cấu hình {@code app.auth.*} — đúng tinh thần
 * "nhân viên bán vé đang cố định" của tài liệu.
 * <p>
 * Lưu ý: tin header hoàn toàn, chỉ dùng cho bản demo môn học. Khi cần chặt chẽ
 * hơn, thay bean này bằng bản có đăng nhập mà không phải sửa A/B/C.
 */
@Component
public class HeaderCurrentUserProvider implements CurrentUserProvider {

    private final CurrentUser defaultUser;
    private final String defaultEmployeeCn02;
    private final String defaultEmployeeCn03;

    public HeaderCurrentUserProvider(
            @Value(Constant.Security.DEFAULT_MA_NV_EXPR) String defaultEmployeeCode,
            @Value(Constant.Security.DEFAULT_HO_TEN_EXPR) String defaultFullName,
            @Value(Constant.Security.DEFAULT_MA_CN_EXPR) String defaultBranchCode,
            @Value(Constant.Security.DEFAULT_VAI_TRO_EXPR) String defaultRole,
            @Value(Constant.Security.DEFAULT_MA_NV_CN02_EXPR) String defaultEmployeeCn02,
            @Value(Constant.Security.DEFAULT_MA_NV_CN03_EXPR) String defaultEmployeeCn03) {
        this.defaultEmployeeCn02 = defaultEmployeeCn02;
        this.defaultEmployeeCn03 = defaultEmployeeCn03;
        Role role = Role.fromCodeOrNull(defaultRole);
        this.defaultUser = new CurrentUser(
                defaultEmployeeCode,
                defaultFullName,
                role != null ? role : Role.QUAN_LY,
                defaultBranchCode);
    }

    @Override
    public CurrentUser get() {
        HttpServletRequest request = currentRequest();
        if (request == null) {
            return defaultUser;
        }

        // Site đang gọi (/hn, /dn, /hcm) quyết định nhân viên mặc định: mã NV chỉ có trong CSDL chi nhánh đó.
        String siteBranch = BranchContextHolder.getBranch();
        String employeeCode = header(request, Constant.Security.HEADER_MA_NV, defaultEmployeeFor(siteBranch));
        String branchCode = header(request, Constant.Security.HEADER_MA_CN, defaultUser.getBranchCode());
        Role role = Role.fromCodeOrNull(request.getHeader(Constant.Security.HEADER_VAI_TRO));
        if (role == null) {
            role = defaultUser.getRole();
        }
        // Bản demo chưa tra tên trong NhanVien; dùng mã nhân viên làm nhãn tạm.
        return new CurrentUser(employeeCode, employeeCode, role, branchCode);
    }

    private String defaultEmployeeFor(String siteBranch) {
        if ("CN02".equals(siteBranch)) return defaultEmployeeCn02;
        if ("CN03".equals(siteBranch)) return defaultEmployeeCn03;
        return defaultUser.getEmployeeCode();
    }

    private static String header(HttpServletRequest request, String name, String fallback) {
        String value = request.getHeader(name);
        return (value == null || value.isBlank()) ? fallback : value.trim();
    }

    private static HttpServletRequest currentRequest() {
        if (RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes attrs) {
            return attrs.getRequest();
        }
        return null;
    }
}
