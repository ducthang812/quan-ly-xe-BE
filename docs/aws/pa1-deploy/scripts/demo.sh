#!/usr/bin/env bash
# Cac buoc demo nhanh. Chay tren may cua site.
#   bash scripts/demo.sh ban-ve      # ban 1 ve qua listener cua site nay
#   bash scripts/demo.sh xem-ag      # ve vua ban co tren ca 2 node (Always On)
#   bash scripts/demo.sh xem-truso   # so ve cua tung chi nhanh da len TruSo (replication len)
#   bash scripts/demo.sh doi-gia     # (chi HN) tang gia ve ngay thuong o danh muc goc
#   bash scripts/demo.sh xem-gia     # bang gia ngay thuong dang co tai site nay (replication xuong)
#   bash scripts/demo.sh doc-link    # doc du lieu chi nhanh khac qua linked server, thu ghi (bi chan)
source "$(dirname "$0")/lib.sh"

case "${1:-}" in
  ban-ve)
    q "$LSN_IP" -W -i sql/demo/ban-ve.sql ;;
  xem-ag)
    for n in 1 2; do
      q "$(node_ip $n)" -W -Q "SET NOCOUNT ON; SELECT @@SERVERNAME AS node, COUNT(*) AS so_ve, MAX(NgayBan) AS ve_moi_nhat FROM [$BRANCH_DB].dbo.Ve"
    done ;;
  xem-truso)
    sqlcmd -S lsn-hn -U sa -P "$SA_PASSWORD" -C -W -Q "SET NOCOUNT ON; SELECT CN_Nguon, COUNT(*) AS so_ve, MAX(NgayBan) AS moi_nhat FROM TruSo.dbo.v_Ve GROUP BY CN_Nguon" ;;
  doi-gia)
    [[ "$SITE" == "hn" ]] || { echo "Chi sua danh muc o Tru so (may HN)"; exit 1; }
    q "$LSN_IP" -W -Q "SET NOCOUNT ON; UPDATE QLXeKhach_HN.dbo.BangGiaVe SET GiaVe = GiaVe + 10000 WHERE MaLoaiNgay = 'THUONG'; SELECT MaTuyen, MaLoaiNgay, GiaVe FROM QLXeKhach_HN.dbo.BangGiaVe WHERE MaLoaiNgay = 'THUONG'" ;;
  xem-gia)
    q "$LSN_IP" -W -Q "SET NOCOUNT ON; SELECT @@SERVERNAME AS node, MaTuyen, MaLoaiNgay, GiaVe FROM [$BRANCH_DB].dbo.BangGiaVe WHERE MaLoaiNgay = 'THUONG'" ;;
  doc-link)
    if [[ "$SITE" == "hn" ]]; then
      q "$LSN_IP" -W -Q "SELECT * FROM OPENQUERY(SERVER_DN,  'SELECT COUNT(*) AS so_ve_DN  FROM QLXeKhach_DN.dbo.Ve')"
      q "$LSN_IP" -W -Q "SELECT * FROM OPENQUERY(SERVER_HCM, 'SELECT COUNT(*) AS so_ve_HCM FROM QLXeKhach_HCM.dbo.Ve')"
    else
      q "$LSN_IP" -W -Q "SELECT * FROM OPENQUERY(SERVER_HN, 'SELECT CN_Nguon, COUNT(*) AS so_ve FROM TruSo.dbo.v_Ve GROUP BY CN_Nguon')"
      echo "Thu ghi thang vao bang qua linked server (phai bi tu choi, chi duoc doc hoac goi thu tuc):"
      q "$LSN_IP" -Q "DELETE FROM SERVER_HN.QLXeKhach_HN.dbo.ThamSo WHERE MaThamSo = '__khong_co__'" \
        || echo "  -> Bi tu choi: dung, linked server khong ghi thang vao bang."
    fi ;;
  *) sed -n '2,9p' "$0" ;;
esac
