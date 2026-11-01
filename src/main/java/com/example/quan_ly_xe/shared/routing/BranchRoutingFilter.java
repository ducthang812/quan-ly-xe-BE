package com.example.quan_ly_xe.shared.routing;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;

/**
 * Filter định tuyến DataSource chi nhánh theo định dạng URL Dạng A:
 * <pre>
 *   /{site}/api/v1/...
 * </pre>
 * Trong đó:
 * <ul>
 *   <li><b>/hn/...</b>: Kết nối duy nhất vào database Hà Nội (QLXeKhach_HN, port 1433). Được phép đọc và ghi.</li>
 *   <li><b>/dn/...</b>: Kết nối duy nhất vào database Đà Nẵng (QLXeKhach_DN, port 1434). Cho phép đọc và ghi dữ liệu phân mảnh tài xế thuộc Đà Nẵng.</li>
 *   <li><b>/hcm/...</b>: Kết nối duy nhất vào database TP.HCM (QLXeKhach_HCM, port 1435). Cho phép đọc và ghi dữ liệu phân mảnh tài xế thuộc TP.HCM.</li>
 * </ul>
 * Bắt buộc URL phải bắt đầu bằng /hn, /dn hoặc /hcm (Dạng A). Mọi SP đọc dữ liệu dùng chung tại DN và HCM
 * do SQL Server Linked Server tự động truy vấn sang Hà Nội.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class BranchRoutingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String uri = request.getRequestURI();
        String method = request.getMethod().toUpperCase();

        // Bỏ qua các endpoint hệ thống
        if (uri.equals("/health") || uri.startsWith("/health/") || uri.startsWith("/error") || uri.equals("/favicon.ico")) {
            BranchContextHolder.setBranch("CN01");
            try {
                filterChain.doFilter(request, response);
            } finally {
                BranchContextHolder.clear();
            }
            return;
        }

        String branch = null;
        String rewrittenUri = null;

        // CHỈ CHẤP NHẬN DẠNG ĐƯỜNG DẪN A: /{site}/...
        if (uri.startsWith("/hn/") || uri.equals("/hn")) {
            branch = "CN01";
            rewrittenUri = uri.substring(3);
            if (rewrittenUri.isEmpty()) rewrittenUri = "/";
        } else if (uri.startsWith("/dn/") || uri.equals("/dn")) {
            branch = "CN02";
            rewrittenUri = uri.substring(3);
            if (rewrittenUri.isEmpty()) rewrittenUri = "/";
        } else if (uri.startsWith("/hcm/") || uri.equals("/hcm")) {
            branch = "CN03";
            rewrittenUri = uri.substring(4);
            if (rewrittenUri.isEmpty()) rewrittenUri = "/";
        }

        // Bắt buộc phải có tiền tố chi nhánh Dạng A
        if (branch == null) {
            sendJsonError(
                    response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "E01",
                    "URL bắt buộc phải theo định dạng /{site}/api/v1/... (với {site} là hn, dn hoặc hcm).",
                    "URL must follow the format /{site}/api/v1/... (where {site} is hn, dn, or hcm).",
                    uri
            );
            return;
        }

        // Phân quyền ghi:
        // - Dữ liệu phân mảnh tài xế (/api/v1/cauhinh/tai-xe/**): Cho phép ghi ở mọi site (/hn, /dn, /hcm) theo phân mảnh cục bộ.
        // - Dữ liệu phân mảnh đội xe của C (/api/v1/doixe/**: Xe, DangKiem, BaoDuong): Cho phép ghi ở mọi site theo phân mảnh cục bộ.
        // - Dữ liệu dùng chung khác (tham số, tuyến đường, bảng giá vé, bảng lương / chốt lương): Chỉ site Hà Nội (/hn) mới được phép cập nhật.
        boolean isTaiXeEndpoint = rewrittenUri.startsWith("/api/v1/cauhinh/tai-xe");
        boolean isDoiXeEndpoint = rewrittenUri.startsWith("/api/v1/doixe/");
        boolean isWriteOperation = "POST".equals(method) || "PUT".equals(method) || "DELETE".equals(method) || "PATCH".equals(method);
        if (isWriteOperation && !isTaiXeEndpoint && !isDoiXeEndpoint && !"CN01".equals(branch)) {
            sendJsonError(
                    response,
                    HttpServletResponse.SC_FORBIDDEN,
                    "FORBIDDEN",
                    "Chỉ chi nhánh Hà Nội (/hn) mới có quyền cập nhật dữ liệu cấu hình chung. Các chi nhánh khác chỉ có quyền đọc.",
                    "Only /hn site has permission to modify shared configuration data. Other sites are read-only.",
                    uri
            );
            return;
        }

        try {
            // Mỗi site kết nối duy nhất vào database của chính nó
            BranchContextHolder.setBranch(branch);

            final String targetUri = rewrittenUri;
            HttpServletRequest wrappedRequest = new HttpServletRequestWrapper(request) {
                @Override
                public String getRequestURI() {
                    return targetUri;
                }

                @Override
                public String getServletPath() {
                    return targetUri;
                }
            };

            filterChain.doFilter(wrappedRequest, response);
        } finally {
            BranchContextHolder.clear();
        }
    }

    private void sendJsonError(HttpServletResponse response, int status, String code, String message, String messageEn, String path)
            throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        String json = String.format(
                "{\"success\":false,\"error\":{\"code\":\"%s\",\"message\":\"%s\",\"messageEn\":\"%s\",\"path\":\"%s\"},\"timestamp\":\"%s\"}",
                code, message, messageEn, path, LocalDateTime.now()
        );
        response.getWriter().write(json);
    }
}
