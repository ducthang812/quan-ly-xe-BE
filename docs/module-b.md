# Module B — vận hành chuyến và vé

## Luồng nghiệp vụ

`UC-008` xem trước chuyến → tạo chuyến và phân công lái/phụ. `UC-009` lọc danh sách
chuyến kế hoạch và hủy chuyến. `UC-010` ghi km, chi phí, giờ thực tế để kết thúc chuyến.
`UC-011` xem sơ đồ ghế và bán vé. `UC-012` hủy vé còn hiệu lực. `UC-013` tra cứu
lịch sử vé theo số điện thoại.

## Hợp đồng API và SQL

| SP / hàm chính | API | Mã lỗi nghiệp vụ chính |
|---|---|---|
| `sp_XemTruocChuyen` | `GET /api/v1/vanhanh/chuyen-xe/xem-truoc` | 404 nếu không có tuyến |
| `sp_TaoChuyenVaPhanCong` + TR03–TR05 | `POST /api/v1/vanhanh/chuyen-xe` | E14, E15–E20, `DRIVER_NOT_ACTIVE` (50301), `TRIP_CODE_EXHAUSTED` (54003) |
| `sp_LayDanhSachChuyen`, `sp_LayChiTietChuyen` | `GET /api/v1/vanhanh/chuyen-xe[/{maChuyen}]` | 404 nếu không có chuyến |
| `sp_HuyChuyen` | `POST .../chuyen-xe/{maChuyen}/huy` | `TRIP_NOT_CANCELLABLE` (54001), 404 |
| `sp_KetThucChuyen` + TR06 | `POST .../chuyen-xe/{maChuyen}/ket-thuc` | E21, E25, E31, 404 |
| `sp_LaySoDoGhe`, `fn_LoaiNgay` | `GET .../chuyen-xe/{maChuyen}/so-do-ghe` | E27, 404 |
| `sp_LayDanhSachVeTheoChuyen` + `sp_LayChiTietChuyen` | `GET /api/v1/vanhanh/chuyen-xe/{maChuyen}/ve` | 404 nếu không có chuyến; danh sách rỗng nếu chuyến chưa có vé |
| `sp_BanVe` + TR01–TR02 | `POST /api/v1/vanhanh/ve` | E22–E27, 404 |
| `sp_HuyVe` | `POST /api/v1/vanhanh/ve/{maVe}/huy` | `TICKET_ALREADY_CANCELLED` (54002), `TRIP_NOT_CANCELLABLE` (54001), 404 |
| `sp_TraCuuVeTheoSDT` | `GET /api/v1/vanhanh/ve/tra-cuu` | E23 |

SQL Server `THROW` được `GlobalExceptionHandler` đổi sang E-code và HTTP status. Riêng
`50302|TX0001` thành E19; `50301|TX0001` thành `DRIVER_NOT_ACTIVE`; cả hai đều
điền `TX0001` vào thông báo.

Các điểm nghiệp vụ đã chốt: TR03 kiểm tra set-based và từ chối tài xế không `DangLam`
trước khi kiểm tra trùng giờ; chỉ chuyến `KeHoach` mới được hủy; vé chỉ được hủy khi
đang `DaBan` và chuyến còn `KeHoach` theo SRS 7.3; sinh mã chuyến tự động dừng với
54003 khi số thứ tự trong ngày vượt 999. Mã 51001 chỉ còn thuộc luồng bán vé vào
chuyến không mở bán.

Tab Hủy vé lấy chuyến từ danh sách `KeHoach` của ô “Chuyến đang mở bán”. Danh sách vé theo
chuyến gồm cả `DaBan` và `DaHuy`; FE chỉ hiện nút Hủy ở vé `DaBan` khi chuyến còn `KeHoach`,
đúng SRS 7.3 và giữ được lịch sử vé đã hủy/lần bán lại.

## Chạy kiểm thử

Chạy unit/controller test bằng `./mvnw -o -B test`. Test controller dùng MockMvc
standalone, không khởi động Spring context. Smoke test SQL nằm tại
`src/test/sql/B_smoke_test.sql`; sửa các mã dữ liệu đầu file rồi chạy trên database test.

## Giả định và giới hạn

- Module C hiện cung cấp stub `sp_KiemTraXeDuDieuKien`, luôn coi xe hợp lệ nếu C chưa có bản thật.
- B chạy trên một nút SQL Server; chưa định tuyến ba chi nhánh/linked server.
- Test không boot application context vì lỗi có sẵn: `BranchRoutingConfig` ép SQL ServerDriver.
- Smoke test cần migration A, C (hoặc stub) và B, và chưa được chạy trên máy dev.
