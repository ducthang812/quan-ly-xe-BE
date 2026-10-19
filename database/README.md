# Cơ sở dữ liệu Phân Tán Quản Lý Xe Khách (SQL Server)

Thư mục này chứa toàn bộ mã nguồn liên quan đến Cơ sở dữ liệu (Database) của dự án **Quản Lý Xe Khách**, được thiết kế theo kiến trúc **Cơ sở dữ liệu phân tán (Distributed Database)** trên hệ quản trị **Microsoft SQL Server (T-SQL)** với 3 nút (Node): Trụ sở Hà Nội (`QLXeKhach_HN`), Chi nhánh Đà Nẵng (`QLXeKhach_DN`), và Chi nhánh TP.HCM (`QLXeKhach_HCM`).

---

## 1. Thông số kết nối (Connection Parameters)

Dưới đây là thông số kết nối mặc định cho các container Docker và cài đặt trực tiếp:

| Nút / Chi nhánh | Tên Database | Cổng (Port Docker) | Tài khoản (User) | Mật khẩu (Password) | Server / Host |
|-----------------|--------------|-------------------|------------------|---------------------|---------------|
| **Trụ sở Hà Nội** (Node chính) | `QLXeKhach_HN` | `1433` | `sa` | `abc@123` | `localhost,1433` |
| **Chi nhánh Đà Nẵng** | `QLXeKhach_DN` | `1434` | `sa` | `abc@123` | `localhost,1434` |
| **Chi nhánh TP.HCM** | `QLXeKhach_HCM` | `1435` | `sa` | `abc@123` | `localhost,1435` |

---

## 2. Các bước chạy qua Docker (Khuyên dùng)

Cách nhanh nhất và đồng bộ nhất để chạy hệ thống database phân tán là sử dụng `docker-compose`.

### Bước 1: Khởi động 3 container SQL Server
Di chuyển vào thư mục `database/` và chạy lệnh Docker Compose:
```bash
docker-compose up -d
```
Lệnh này sẽ khởi động 3 container:
- `sql_hn` (port `1433`)
- `sql_dn` (port `1434`)
- `sql_hcm` (port `1435`)

### Bước 2: Chạy init database (Khởi tạo CSDL & Linked Server)
Sau khi các container đã khởi động hoàn tất (chờ khoảng 30-60 giây để SQL Server khởi tạo xong), bạn sử dụng các công cụ quản lý cơ sở dữ liệu như **SSMS (SQL Server Management Studio)**, **Azure Data Studio**, hoặc **DBeaver** để kết nối và chạy các file script trong thư mục `init/`:

1. **Khởi tạo Database Hà Nội (`db_hn.sql`)**:
   - Kết nối tới `localhost,1433` (User: `sa`, Pass: `abc@123`).
   - Mở và chạy toàn bộ nội dung file `database/init/db_hn.sql`. File này sẽ tạo database `QLXeKhach_HN`, tạo 19 bảng (bao gồm bảng danh mục dùng chung), insert dữ liệu gốc và cấu hình **Linked Server** trỏ sang Đà Nẵng (`SERVER_DN`) và TP.HCM (`SERVER_HCM`).

2. **Khởi tạo Database Đà Nẵng (`db_dn.sql`)**:
   - Kết nối tới `localhost,1434` (User: `sa`, Pass: `abc@123`).
   - Mở và chạy toàn bộ nội dung file `database/init/db_dn.sql`. File này tạo database `QLXeKhach_DN`, 12 bảng giao dịch cục bộ, dữ liệu mẫu tại Đà Nẵng và cấu hình **Linked Server** trỏ về Hà Nội & TP.HCM.

3. **Khởi tạo Database TP.HCM (`db_hcm.sql`)**:
   - Kết nối tới `localhost,1435` (User: `sa`, Pass: `abc@123`).
   - Mở và chạy toàn bộ nội dung file `database/init/db_hcm.sql`. File này tạo database `QLXeKhach_HCM`, 12 bảng giao dịch cục bộ, dữ liệu mẫu tại TP.HCM và cấu hình **Linked Server** trỏ về Hà Nội.

---

## 3. Lưu ý khi cài đặt trực tiếp không qua Docker

Nếu bạn cài đặt Microsoft SQL Server trực tiếp trên máy (Local Instance) mà không sử dụng Docker, hãy lưu ý các điểm sau:

1. **Cổng kết nối (Port):**
   - Mặc định SQL Server cài trực tiếp chạy trên cổng `1433`. 
   - Bắt buộc phải tạo 3 instance khác nhau thì mới tạo được linked server
   
2. **Cấu hình Linked Server (`sp_addlinkedserver`):**
   - Trong các file `db_hn.sql`, `db_dn.sql`, `db_hcm.sql`, các câu lệnh cấu hình Linked Server đang trỏ tới tên container và port Docker (ví dụ: `@datasrc = N'sql_dn,1433'` hoặc `sql_hn,1433`).
   - Khi chạy trên môi trường **cài trực tiếp không qua Docker**, bạn cần **sửa lại tham số `@datasrc`** thành tên máy tính của bạn (Computer Name), `localhost`, hoặc địa chỉ IP tương ứng kèm theo tên Instance/Port thực tế của SQL Server trên máy bạn.
     *Ví dụ:*
     ```sql
     EXEC sp_addlinkedserver 
         @server = N'SERVER_DN', 
         @srvproduct = N'', 
         @provider = N'MSOLEDBSQL', 
         @datasrc = N'MY-PC\SQLEXPRESS'; -- hoặc 'localhost' / IP cụ thể
     ```

3. **Distributed Transactions (MS DTC):**
   - Vì hệ thống sử dụng Linked Server để thực hiện các truy vấn phân tán và giao dịch giữa các chi nhánh, hãy đảm bảo dịch vụ **Distributed Transaction Coordinator (MS DTC)** trên Windows đã được bật (Start) nếu ứng dụng yêu cầu phân phối transaction chéo server.
