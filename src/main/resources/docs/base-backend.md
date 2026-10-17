# Tài liệu phần Base Backend — Quản lý chuỗi xe khách

Tài liệu cho người mới tham gia dự án. Mô tả **khung chung (base)** đã viết sẵn
để 3 người làm module A, B, C ghép code vào mà không đụng nhau. Phần base **chưa
chứa** nghiệp vụ của A/B/C, chỉ có hạ tầng dùng chung.

> Tóm tắt 1 câu: mỗi request vào BE đi qua một bộ khung thống nhất — trả kết quả
> bằng `ApiResponse`, lỗi được dịch sang tiếng Việt qua `ErrorCode` +
> `GlobalExceptionHandler`, ngày hiện tại lấy từ `CurrentDateProvider`, người
> thao tác lấy từ `CurrentUserProvider`, và mọi chuỗi hằng nằm trong `Constant`.

---

## 1. Công nghệ

| Hạng mục | Lựa chọn |
|---|---|
| Ngôn ngữ / JDK | Java 17 |
| Framework | Spring Boot 4.1.1 (Web MVC, Data JPA, Validation) |
| CSDL | SQL Server (driver `mssql-jdbc`) |

Quy ước đặt tên: **code viết bằng tiếng Anh**; chỉ giữ tiếng Việt ở những chỗ
ánh xạ trực tiếp CSDL/nghiệp vụ cho dễ trace (tên cột `@Column`, enum `Role`,
tên header demo, nội dung thông báo lỗi).

---

## 2. Cấu trúc thư mục

```
com.example.quan_ly_xe
├── QuanLyXeApplication.java        # điểm khởi động Spring Boot
├── common/                         # KHUNG CHUNG (cả nhóm dùng)
│   ├── config/
│   │   └── JpaAuditingConfig.java      # bật tự điền NgayTao/NgayCapNhat
│   ├── dto/
│   │   ├── ApiResponse.java            # bao bì phản hồi thống nhất
│   │   ├── ErrorResponse.java          # nội dung lỗi (+ FieldError)
│   │   └── PageResponse.java           # kết quả phân trang gọn
│   ├── entity/
│   │   └── BaseEntity.java             # lớp cha cho entity (2 cột kiểm toán)
│   ├── exception/
│   │   ├── ErrorCode.java              # danh mục lỗi E01–E32 (hợp đồng chung)
│   │   ├── AppException.java           # ngoại lệ nghiệp vụ
│   │   ├── ResourceNotFoundException.java
│   │   └── GlobalExceptionHandler.java # bắt mọi lỗi → ApiResponse
│   ├── security/                       # "authen" demo (KHÔNG đăng nhập)
│   │   ├── Role.java                   # 4 vai trò
│   │   ├── CurrentUser.java            # nhân viên đang thao tác
│   │   ├── CurrentUserProvider.java    # interface lấy current user
│   │   └── HeaderCurrentUserProvider.java
│   ├── util/
│   │   ├── Constant.java               # TẤT CẢ chuỗi/hằng dùng chung
│   │   ├── CurrentDateProvider.java    # nguồn "ngày hiện tại" duy nhất
│   │   └── ConfigurableCurrentDateProvider.java
│   └── web/
│       └── HealthController.java       # GET /health (mẫu + kiểm tra sống)
├── shared/                         # giao diện liên module (chốt ở Sprint 0)
└── modules/
    ├── cauhinh_a/                  # Người A — cấu hình, tuyến, tài xế, báo cáo
    ├── vanhanh_b/                  # Người B — chuyến và vé
    └── doixe_c/                    # Người C — đội xe và kỹ thuật
```

Mỗi package `modules/*` hiện chỉ có `package-info.java` ghi rõ chủ sở hữu và bảng
được phép ghi DDL. Quyền sửa khóa trong [`.github/CODEOWNERS`](../../../../.github/CODEOWNERS).

---

## 3. Các thành phần dùng chung

### 3.1 `BaseEntity` — lớp cha của entity

Dùng `@MappedSuperclass`, chứa 2 cột kiểm toán tự điền: `createdAt` → cột
`NgayTao`, `updatedAt` → cột `NgayCapNhat` (nhờ `JpaAuditingConfig`).

Không đặt khóa chính ở đây vì các bảng dùng **khóa tự nhiên** (MaXe, MaTuyen,
MaChuyen...). Entity của A/B/C chỉ cần:

```java
@Entity
@Table(name = "Xe")
public class Xe extends BaseEntity {
    @Id
    @Column(name = "MaXe")
    private String maXe;            // khóa tự nhiên, tự khai báo
    // ...
}
```

Quy ước: **tên field tiếng Anh, `@Column(name=...)` giữ tên cột tiếng Việt**.

### 3.2 `ApiResponse` — phản hồi thống nhất

Mọi API trả cùng một dạng:

```jsonc
// Thành công
{ "success": true, "data": { ... }, "timestamp": "..." }
// Lỗi
{ "success": false, "error": { "code": "E07", "message": "Biển số ... đã tồn tại.", ... }, "timestamp": "..." }
```

Cách dùng trong controller:

```java
return ApiResponse.ok(data);   // 200, có dữ liệu
return ApiResponse.ok();       // 200, không dữ liệu
```

Danh sách dài thì bọc bằng `PageResponse.from(page)` rồi `ApiResponse.ok(...)`.

### 3.3 Xử lý lỗi: `ErrorCode` + `AppException` + `GlobalExceptionHandler`

Đây là phần quan trọng nhất của base. Luồng:

```
Service ném AppException(ErrorCode.Exx)      ┐
   HOẶC CSDL phát lỗi (THROW 50xxx / ràng buộc)  ├──► GlobalExceptionHandler ──► ApiResponse lỗi
   HOẶC @Valid thất bại                      ┘        (câu tiếng Việt, đúng HTTP status)
```

- **`ErrorCode`**: enum liệt kê **E01–E32** theo mục 10 của SRS. Mỗi mã có: HTTP
  status, câu tiếng Việt, câu tiếng Anh, và (nếu có) mã `THROW` của SQL Server.
  Đây là **hợp đồng chung** — thêm mã lỗi mới sửa đúng một chỗ. Nội dung câu chữ
  nằm trong `Constant.ErrorMessage`, `ErrorCode` chỉ tham chiếu.

- **`AppException`**: service ném ra khi gặp lỗi nghiệp vụ.

  ```java
  throw new AppException(ErrorCode.E07, bienSo);   // Biển số {0} đã tồn tại.
  throw new ResourceNotFoundException("xe", maXe); // 404 Không tìm thấy ...
  ```
``
- **`GlobalExceptionHandler`** (`@RestControllerAdvice`): bắt hết và dịch:
  1. `AppException` → mã + câu tiếng Việt theo `ErrorCode`.
  2. Lỗi `@Valid` / ràng buộc tham số → `E01`, kèm lỗi từng trường.
  3. Lỗi CSDL: đọc mã `THROW` (`SQLException.getErrorCode()`) → dò trong message →
     khớp tên ràng buộc (CK/UQ/FK/PK) → cuối cùng `E32` (mất kết nối) hoặc `INTERNAL`.

A/B/C **không cần** tự format lỗi: cứ ném `AppException` hoặc để CSDL phát lỗi,
khung lo phần dịch và HTTP status.

### 3.4 `CurrentDateProvider` — ngày hiện tại dùng chung

SRS yêu cầu mọi nơi đọc "hôm nay" từ một nguồn, prototype cố định **02/06/2025**.
Không ai gọi `LocalDate.now()` rải rác.

```java
private final CurrentDateProvider currentDate;
LocalDate today = currentDate.today();  // dùng cho F11, F12, F13, F14, F17...
```

Cấu hình `app.current-date` (trống = ngày hệ thống). Profile `prototype` đặt sẵn
`2025-06-02`.

### 3.5 `Constant` — gom mọi chuỗi/hằng

Tránh "magic string". Nhóm theo mục đích: `Api`, `Column`, `ConfigKey`,
`Security`, `Health`, `Message`, `ThrowCode`, `ConstraintName`, `ErrorMessage`.
Đổi một chỗ là đổi mọi nơi; dùng được cả trong annotation vì là hằng biên dịch.

---

## 4. "Authen" bản demo (không đăng nhập)

Tài liệu (SRS/BRD/Báo cáo) **cố tình bỏ đăng nhập, phân quyền**. Nhưng hệ thống
vẫn cần biết *ai đang thao tác* để lấy `MaCN` (chi nhánh), `MaNV` (người bán vé)
và vai trò. Vì vậy base chỉ có **ngữ cảnh nhân viên hiện hành**, không mật khẩu.

| Lớp | Vai trò |
|---|---|
| `Role` | enum 4 vai trò: `QUAN_LY`, `NV_DIEU_HANH`, `NV_BAN_VE`, `NV_KY_THUAT` (khớp `NhanVien.ChucVu`) |
| `CurrentUser` | `employeeCode` (MaNV), `fullName`, `role`, `branchCode` (MaCN) |
| `CurrentUserProvider` | interface: `CurrentUser get()` |
| `HeaderCurrentUserProvider` | đọc header `X-MaNV` / `X-MaCN` / `X-VaiTro`; thiếu thì dùng nhân viên demo trong `app.auth.*` |

Cách A/B/C dùng:

```java
private final CurrentUserProvider currentUser;

var u = currentUser.get();
ve.setMaNVBan(u.getEmployeeCode());   // ghi Ve.MaNVBan
// lọc / định tuyến phân tán theo u.getBranchCode()
if (u.isManager()) { ... }            // gợi ý theo vai trò
```

> ⚠️ Provider này **tin header hoàn toàn**, không xác thực — chỉ dùng cho demo
> môn học. Muốn có đăng nhập thật, chỉ cần thay `CurrentUserProvider` bằng bản
> khác, **không phải sửa code A/B/C**.

Đổi chi nhánh/vai trò khi test:

```bash
curl http://localhost:8080/health -H "X-MaCN: CN02" -H "X-VaiTro: NV_BAN_VE"
```

---

## 5. Cấu hình & chạy

### 5.1 Cấu hình (`application.yaml`)

```yaml
spring:
  datasource:
    url: ${DB_URL:jdbc:sqlserver://localhost:1433;databaseName=quan_ly_xe;encrypt=true;trustServerCertificate=true}
    username: ${DB_USERNAME:sa}
    password: ${DB_PASSWORD:}
  jpa:
    hibernate:
      ddl-auto: none        # schema do migration quản, KHÔNG để Hibernate tự tạo
  flyway:
    enabled: ${FLYWAY_ENABLED:false}   # bật khi CSDL đã sẵn sàng
app:
  current-date: ${APP_CURRENT_DATE:}   # trống = ngày hệ thống
  auth:                                # nhân viên demo mặc định
    default-ma-nv: NV001
    default-ma-cn: CN01
    default-vai-tro: QUAN_LY
```

Có thể ghi đè bằng biến môi trường (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`,
`FLYWAY_ENABLED`, `APP_CURRENT_DATE`).

### 5.2 Lệnh thường dùng

```bash
./mvnw test        # chạy test (dùng H2, không cần SQL Server)
./mvnw spring-boot:run                              # chạy với ngày hệ thống
./mvnw spring-boot:run -Dspring-boot.run.profiles=prototype   # cố định 02/06/2025
```

Kiểm tra sống: `GET http://localhost:8080/health`.

---

## 6. Dành cho người mới ghép module (A/B/C)

1. Code của bạn đặt trong `modules/<của-bạn>/` (ví dụ `cauhinh_a`). **Không** sửa
   package của người khác; chỉ đọc dữ liệu qua API/giao diện đã chốt ở Sprint 0.
2. Entity `extends BaseEntity`, field tiếng Anh, `@Column` giữ tên cột tiếng Việt.
3. Controller trả `ApiResponse.ok(...)`; lỗi thì ném `AppException(ErrorCode.Exx)`.
4. Cần "hôm nay" → tiêm `CurrentDateProvider`. Cần người thao tác → tiêm
   `CurrentUserProvider`.
5. Mọi chuỗi/hằng mới → thêm vào `Constant`, đừng viết thẳng trong code.
6. Migration CSDL đặt trong `src/main/resources/db/migration/` theo quy ước
   `V<thời điểm>__<chữ cái người>_*.sql` (xem README trong thư mục đó). Mã `THROW
   50xxx` trong SQL phải khớp `ErrorCode` để báo lỗi tiếng Việt đúng.

---

## 7. Những gì base CHƯA làm (chủ đích)

- Nghiệp vụ A/B/C (entity, service, controller từng bảng).
- Đăng nhập/phân quyền thật (tài liệu đã chốt bỏ).
- Lớp định tuyến cụm SQL Server 3 chi nhánh và sinh mã toàn chuỗi — là việc chung
  của A, để trong `shared/` khi triển khai.
