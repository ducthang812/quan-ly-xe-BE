package com.example.quan_ly_xe.common.web;

import com.example.quan_ly_xe.common.dto.ApiResponse;
import com.example.quan_ly_xe.common.security.CurrentUser;
import com.example.quan_ly_xe.common.security.CurrentUserProvider;
import com.example.quan_ly_xe.common.util.Constant;
import com.example.quan_ly_xe.common.util.CurrentDateProvider;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.Map;

/**
 * Endpoint kiểm tra sống {@code GET /health}. Vừa để giám sát, vừa làm ví dụ mẫu
 * cho A/B/C về cách trả {@link ApiResponse}, dùng {@link CurrentDateProvider} và
 * đọc nhân viên hiện hành qua {@link CurrentUserProvider}.
 */
@RestController
@RequestMapping(Constant.Api.HEALTH_PATH)
public class HealthController {

    private final CurrentDateProvider currentDate;
    private final CurrentUserProvider currentUser;

    public HealthController(CurrentDateProvider currentDate, CurrentUserProvider currentUser) {
        this.currentDate = currentDate;
        this.currentUser = currentUser;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> health() {
        LocalDate today = currentDate.today();
        CurrentUser user = currentUser.get();
        return ApiResponse.ok(Map.of(
                Constant.Health.KEY_STATUS, Constant.Health.STATUS_UP,
                Constant.Health.KEY_TODAY, today,
                Constant.Health.KEY_USER, Map.of(
                        "maNV", user.getEmployeeCode(),
                        "maCN", user.getBranchCode(),
                        "vaiTro", user.getRole().name()
                )
        ));
    }
}
