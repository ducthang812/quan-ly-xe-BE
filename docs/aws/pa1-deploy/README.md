# pa1-deploy

Bo script dung he thong PA1 (3 site HN / DN / HCM: SQL Server Always On + Replication + Linked Server)
cho BE Spring Boot cua nhom, tren 3 may EC2 Ubuntu 24.04. Chi tiet tung buoc xem runbook.

| Buoc | Chay o dau | Lenh |
|---|---|---|
| Chuan bi may | ca 3 may | `sudo bash scripts/00-host-setup.sh <hn, dn hoac hcm>` roi SSH lai |
| Chay container | ca 3 may | `bash scripts/10-up.sh` |
| Always On + CSDL + du lieu mau | ca 3 may | `bash scripts/20-ag.sh` |
| Thu tuc BE + Replication | HN -> DN -> HCM | `bash scripts/30-repl.sh` (tu goi 25-sp.sh) |
| Linked server (+ view tong hop o HN) | ca 3 may, sau khi 30 xong o ca 3 | `bash scripts/40-linked.sh` |
| Nginx + Java cho FE/BE | chi HN | `sudo bash scripts/50-app-setup.sh` |
| Trang thai | bat ky | `bash scripts/status.sh` |
| Failover | may cua site | `bash scripts/failover.sh 2 [--force]`, `bash scripts/rejoin.sh 1` |
| Demo | may cua site | `bash scripts/demo.sh` (xem cac lenh con) |
| Cap nhat he thong dang chay (03/11) | DN -> HCM -> HN | `bash scripts/60-update.sh` (HN: `--jar ~/app-new.jar`) |

Nguon cua cac file SQL:
- sql/schema/QLXeKhach_*.sql: database/init/db_*.sql cua nhom (bo phan linked server cuoi file).
- sql/schema/compat-B.sql: them default cho Ve/PhanCong de thu tuc ban ve cua module B chay duoc
  (cung noi dung voi migration V202611031001).
- sql/app/V2026*.sql: GIONG HET thu muc src/main/resources/db/migration cua repo BE (6 file).
  B goc giu kieu CHAR; V202611031000 tao lai module B ban moi nhat cua nhom voi tham so VARCHAR(15)
  (ma XE_DN01, TX_HCM01... dai hon CHAR(5)/CHAR(6)). Khi repo co migration moi: chep vao sql/app/.
- sql/check/after-update.sql: kiem tra sau 60-update.sh (= database/patches/check_local.sql cua repo).

Cap nhat tu may Windows (repo BE): build `.\mvnw.cmd clean package -DskipTests`, roi trong thu muc nay
`.\push-update.ps1 -DnHost <IP pa1-dn> -HcmHost <IP pa1-hcm> [-Run]` - day file + jar len 3 may,
`-Run` thi chay luon 60-update.sh theo thu tu. 60-update.sh: sao luu COPY_ONLY vao shared/, tam tat
replicate_ddl cua PUB_LEN_xx trong luc tao lai trigger, kiem tra, roi (HN) thay jar va thu API.

Truoc khi chay: doi mat khau trong env/secrets.env (giong nhau tren 3 may) va trong app/be.env.example.
