package com.example.quan_ly_xe.modules.cauhinh_a.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ThamSoBaoDuongRequest {

    @NotNull(message = "Chu kỳ bảo dưỡng tối đa không được để trống")
    @Positive(message = "Chu kỳ bảo dưỡng tối đa phải lớn hơn 0")
    private Double chuKyBd;

    @NotNull(message = "Số km làm việc giảm 1 ngày không được để trống")
    @Positive(message = "Số km làm việc giảm 1 ngày phải lớn hơn 0")
    private Double kmMoiNgayBd;

    @NotNull(message = "Ngưỡng cảnh báo sắp đến hạn không được để trống")
    @Positive(message = "Ngưỡng cảnh báo sắp đến hạn phải lớn hơn 0")
    private Double canhBaoNgay;

    @NotNull(message = "Chu kỳ đăng kiểm xe cũ không được để trống")
    @Positive(message = "Chu kỳ đăng kiểm xe cũ phải lớn hơn 0")
    private Double chuKyDkCu;

    @NotNull(message = "Chu kỳ đăng kiểm xe mới không được để trống")
    @Positive(message = "Chu kỳ đăng kiểm xe mới phải lớn hơn 0")
    private Double chuKyDkMoi;

    @NotNull(message = "Số năm tuổi tính là xe cũ không được để trống")
    @Positive(message = "Số năm tuổi tính là xe cũ phải lớn hơn 0")
    private Double tuoiXeCu;

    @NotNull(message = "Hệ số đường khó cấp 1 không được để trống")
    @DecimalMin(value = "1.0", message = "Hệ số đường khó phải từ 1 trở lên")
    private Double hsDuongKhoCap1;

    @NotNull(message = "Hệ số đường khó cấp 2 không được để trống")
    @DecimalMin(value = "1.0", message = "Hệ số đường khó phải từ 1 trở lên")
    private Double hsDuongKhoCap2;

    @NotNull(message = "Hệ số đường khó cấp 3 không được để trống")
    @DecimalMin(value = "1.0", message = "Hệ số đường khó phải từ 1 trở lên")
    private Double hsDuongKhoCap3;
}

