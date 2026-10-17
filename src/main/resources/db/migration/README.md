# Migration CSDL (Flyway)

Mỗi người tự quản DDL/migration cho **bảng mình sở hữu** (xem Phân công). Không ai sửa migration của người khác.

## Quy ước đặt tên

```
V<thời điểm><chữ cái người>__<mô tả>.sql
```

Ví dụ: `V202610201030__B_tao_bang_ve.sql`

- Thời điểm `yyyyMMddHHmm` để không trùng số phiên bản khi 3 người làm song song.
- Chữ cái `A` / `B` / `C` ghi rõ chủ sở hữu.

## SQL dùng SQL Server (T-SQL) – đúng như SRS

Hệ dùng **SQL Server**, nên viết trực tiếp T-SQL theo SRS, không cần port:

- Lỗi nghiệp vụ: `THROW 50xxx, N'...', 1;` (mã lỗi ≥ 50000).
- Upsert bảng giá: `MERGE`.
- Ngày hiện tại trong ràng buộc/trigger: `GETDATE()` / `CAST(GETDATE() AS DATE)`.
- Khóa khi bán vé: `WITH (UPDLOCK, HOLDLOCK)`.
- Chỉ mục có điều kiện: `CREATE UNIQUE INDEX ... WHERE ...` (filtered index).

Mã `50xxx` của lệnh `THROW` phải khớp bảng ánh xạ ở
`common/exception/ErrorCode.java` để BE dịch sang câu tiếng Việt
(BE đọc mã này qua `SQLException.getErrorCode()`).

## Bật Flyway

Mặc định tắt (`spring.flyway.enabled=false`) để base chạy được khi chưa có CSDL.
Khi DB sẵn sàng, đặt biến môi trường `FLYWAY_ENABLED=true`.
