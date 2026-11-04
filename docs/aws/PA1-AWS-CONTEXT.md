# Ngữ cảnh triển khai PA1 lên AWS (tóm tắt từ phiên làm việc với Claude, 31/10–03/11/2026)

File này để Claude/trợ lý AI trong VS Code nắm được hệ thống đã triển khai trên AWS và các thay đổi so với repo.
Mã nguồn bộ triển khai nằm ở `docs/aws/pa1-deploy/` (đã bỏ mật khẩu; mật khẩu thật chỉ có trên máy chủ, file `env/secrets.env`).

## 1. Mô hình PA1

- 3 site: **HN** (chi nhánh CN01, kiêm Trụ sở), **ĐN** (CN02), **HCM** (CN03).
- Mỗi site: 2 node SQL Server 2019 (Docker, bản Developer) trong 1 **Always On AG** (`CLUSTER_TYPE = NONE`,
  synchronous commit, failover bằng tay) + 1 **listener** giả lập bằng HAProxy.
- **Replication** (transactional, push):
  - `PUB_DANHMUC`: 9 bảng danh mục từ `QLXeKhach_HN` xuống `QLXeKhach_DN`, `QLXeKhach_HCM`
    (ThamSo, DoPhucTap, LoaiXe, LoaiNgay, LichNgay, LichLoaiNgay, TuyenDuong, BangGiaVe, ChiNhanh).
  - `PUB_LEN_CN01/02/03`: 11 bảng nghiệp vụ của từng chi nhánh lên CSDL `TruSo` ở HN, schema `cn01/cn02/cn03`
    (NhanVien, Xe, TaiXe, TaiXe_SDT, ChuyenXe, PhanCong, HanhKhach, Ve, BaoDuong, DangKiem, BangLuong).
  - Distributor đặt local trên node 1 mỗi site. Khi một site chạy trên node 2, replication của site đó tạm dừng.
- **TruSo**: kho tổng hợp chỉ đọc của Trụ sở, view `TruSo.dbo.v_<Bảng>` = UNION ALL 3 schema + cột `CN_Nguon`.
  BE không dùng TruSo.
- **Linked server** full mesh `SERVER_HN`, `SERVER_DN`, `SERVER_HCM` (trỏ tới listener, provider MSOLEDBSQL),
  đăng nhập bên kia bằng `link_user` (đọc + EXECUTE, DENY INSERT/UPDATE/DELETE), `rpc out` bật,
  `remote proc transaction promotion` = false. Tên `SERVER_*` được gọi đích danh trong stored procedure của nhóm.
- **Login**: `sa` (script quản trị, agent), `app_user` (BE: datareader, datawriter, EXECUTE), `link_user`.
  SID cố định giống nhau trên 2 node để không mồ côi user sau failover.

## 2. Hạ tầng AWS

| Thành phần | Giá trị |
|---|---|
| Tài khoản | Free plan, region ap-southeast-2 (Sydney) |
| VPC | `project-vpc` 10.10.0.0/16; public subnet 10.10.1.0/24 (HN), 10.10.2.0/24 (ĐN), 10.10.3.0/24 (HCM) |
| Security Group | `BusManagement`: all traffic trong VPC, SSH 22 từ My IP, HTTP 80 công khai |
| EC2 | `pa1-hn`, `pa1-dn`, `pa1-hcm`: m7i-flex.large, Ubuntu 24.04, gp3 30 GB |
| IP mỗi máy | .10 (máy), .11 (node 1), .12 (node 2), .20 (listener) trong subnet của site |
| Elastic IP | 52.64.31.95 gắn `pa1-hn`; ĐN, HCM dùng IP public tự cấp (đổi khi stop/start) |
| Key | `BusManagement.pem` (giữ ở máy cá nhân, không commit) |

Ứng dụng chạy trên `pa1-hn`: BE Spring Boot (systemd `pa1-be`, cổng 8080, `/opt/pa1-be/app.jar`,
biến môi trường `/opt/pa1-be/be.env`), FE Angular ở `/var/www/pa1`, Nginx cổng 80 chuyển `/(hn|dn|hcm)/api/`
và `/health` sang BE. BE kết nối `lsn-hn`, `lsn-dn`, `lsn-hcm` bằng `app_user`, `FLYWAY_ENABLED=false`,
profile `prototype` (ngày hệ thống 2025-06-02).

## 3. Thứ tự script (trong `pa1-deploy`, chạy trên từng máy)

`00-host-setup.sh <site>` → `10-up.sh` → `20-ag.sh` → `30-repl.sh` (HN trước) → `40-linked.sh` → `50-app-setup.sh` (chỉ HN).
Vận hành: `status.sh`, `failover.sh 1|2 [--force]`, `rejoin.sh <n>`, `toggle.sh repl|linked on|off|status`,
`demo.sh ban-ve|xem-ag|xem-truso|doi-gia|xem-gia|doc-link`.

## 4. Khác biệt so với repo của nhóm (cần đưa vào repo)

1. **Module B — tham số `@Ma… CHAR(n)` → `VARCHAR(15)`** (~36 chỗ). Mã chi nhánh dài hơn (`XE_DN01`, `TX_HCM01`,
   `NV_DN01`), CHAR cắt mã làm sai khóa ngoại. Đưa vào bằng migration mới `V202611031000__B_fix_varchar_params.sql`;
   không sửa file `V202610251000__B_…` cũ.
2. **Giá trị mặc định** `Ve.MaVe` (mã tạm `TMP…`), `Ve.LanBan = 0`, `PhanCong.ThuLao = 0`, `Ve.GiaVe` cho phép NULL —
   migration `V202611031001__B_compat_defaults.sql`. Cần chạy trên cả 3 CSDL chi nhánh.
3. **`BranchRoutingFilter.java`**: thêm `isVanHanhEndpoint = rewrittenUri.startsWith("/api/v1/vanhanh/")` vào
   điều kiện cho ghi ở `/dn`, `/hcm`. Trước đó tạo chuyến, bán vé, hủy vé ở ĐN, HCM bị 403.
4. Nên sửa thêm: `app.auth.default-ma-nv: NV001` (mã không tồn tại) → mã có thật, ví dụ `NV_HN02`;
   javadoc/giá trị mặc định trong `BranchRoutingFilter`, `BranchRoutingConfig` còn ghi `localhost:1434/1435`, `sa`;
   có thể thêm `ds.setKeepaliveTime(30000)` trong `createDataSource` để hồi phục nhanh sau failover.
5. FE: thông báo ở site ĐN, HCM ghi danh mục "đồng bộ qua Linked Server"; trên AWS danh mục do replication chép xuống.
6. `database/README.md`: mật khẩu ghi `abc@123` nhưng compose dùng `Abc@123456`; ĐN, HCM có 11 bảng (không phải 12).
   Thêm `database/data_*/` vào `.gitignore` (file vật lý của SQL Server).

## 5. Khác biệt local ↔ AWS (bình thường, không cần đồng bộ)

| | Local (`database/docker-compose.yml`) | AWS |
|---|---|---|
| SQL Server | 2022, 3 instance đơn, cổng 1433/1434/1435 | 2019, 2 node/site + listener, cổng 1433 |
| Danh mục ở ĐN, HCM | SYNONYM tới `SERVER_HN` (do migration A tạo khi chưa có bảng) | Bảng thật do `PUB_DANHMUC` chép xuống |
| TruSo, replication, AG | Không có | Có |
| Linked server | Trỏ tên container, đăng nhập `sa` | Trỏ listener, đăng nhập `link_user` |
| Login ứng dụng | `sa` | `app_user` |

## 6. Tài liệu đã có (trên Claude, dạng doc)

- Runbook triển khai, Tổng hợp triển khai (có Bảng cấu hình chi tiết), Kết nối DBeaver (SSH tunnel qua 52.64.31.95),
  Kịch bản demo 6 cảnh (SQL + thao tác trên giao diện). Bản Word: `Tong-hop-trien-khai-PA1-AWS.docx`, `Ket-noi-DBeaver-PA1.docx`.

## 7. Đồng bộ ngược local → AWS (03/11/2026, chiều)

- Bản AWS được build từ mã **trước** commit `a8512d2` ("chore; fix nghiep vu", module B): thiếu kiểm tra giờ/km trong
  `sp_TaoChuyenVaPhanCong`, `sp_KetThucChuyen`, cột `ThuLaoLai/ThuLaoPhu` của `sp_LayDanhSachChuyen`, thủ tục mới
  `sp_LayDanhSachVeTheoChuyen` và phần Java tương ứng.
- Vì vậy `V202611031000__B_fix_varchar_params.sql` trong repo được tạo bằng 3-way merge: B mới nhất của nhóm + đổi
  `CHAR` → `VARCHAR(15)` của AWS (kể cả `sp_LayDanhSachVeTheoChuyen`), thêm `SET QUOTED_IDENTIFIER ON` đầu file.
- `pa1-deploy/sql/app/` = đúng thư mục migration của repo. Cập nhật hệ thống đang chạy: `pa1-deploy/push-update.ps1`
  (Windows) hoặc `scripts/60-update.sh` trên từng máy, thứ tự DN → HCM → HN (`--jar`).
- Local: `sqlcmd` (ODBC) trong container mặc định `QUOTED_IDENTIFIER OFF` → phải chạy với `-I`
  (`database/patches/apply-local.ps1` đã thêm). `go-sqlcmd` trên EC2 mặc định ON.
