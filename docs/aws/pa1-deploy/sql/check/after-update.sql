-- =============================================================================
-- Kiem tra sau khi chay scripts/60-update.sh. Chay tren CSDL chi nhanh qua listener
-- (60-update.sh tu goi). Cung noi dung voi database/patches/check_local.sql cua repo.
-- =============================================================================
SET NOCOUNT ON;

-- 1. Thu tuc, trigger, ham cua nhom dang co (A, B, C)
SELECT DB_NAME() AS csdl, type_desc AS loai, COUNT(*) AS so_luong
FROM sys.objects
WHERE is_ms_shipped = 0 AND type IN ('P', 'TR', 'FN', 'IF', 'TF')
GROUP BY type_desc;

-- 2. Ham, thu tuc, trigger cua module B phai co du (13 + 6 dong)
SELECT name AS doi_tuong_B, type_desc, modify_date
FROM sys.objects
WHERE name IN ('fn_LoaiNgay', 'sp_TaoChuyenVaPhanCong', 'sp_XemTruocChuyen', 'sp_LayDanhSachChuyen', 'sp_LayChiTietChuyen', 'sp_LaySoDoGhe',
               'sp_KetThucChuyen', 'sp_HuyChuyen', 'sp_BanVe', 'sp_HuyVe', 'sp_TraCuuVeTheoSDT', 'sp_LayDanhSachVeTheoChuyen', 'sp_KiemTraXeDuDieuKien')
   OR name LIKE 'trg[_]Ve[_]%' OR name LIKE 'trg[_]PhanCong[_]%' OR name LIKE 'trg[_]ChuyenXe[_]%'
ORDER BY type_desc, name;

-- 3. Khong con tham so @Ma... kieu CHAR o module B (ket qua phai RONG)
SELECT OBJECT_NAME(p.object_id) AS thu_tuc, p.name AS tham_so, t.name AS kieu, p.max_length
FROM sys.parameters p
JOIN sys.types t ON t.user_type_id = p.user_type_id
WHERE p.name LIKE '@Ma%' AND t.name IN ('char', 'nchar')
  AND OBJECT_NAME(p.object_id) IN ('fn_LoaiNgay', 'sp_TaoChuyenVaPhanCong', 'sp_XemTruocChuyen', 'sp_LayDanhSachChuyen', 'sp_LayChiTietChuyen', 'sp_LaySoDoGhe',
               'sp_KetThucChuyen', 'sp_HuyChuyen', 'sp_BanVe', 'sp_HuyVe', 'sp_TraCuuVeTheoSDT', 'sp_LayDanhSachVeTheoChuyen', 'sp_KiemTraXeDuDieuKien');

-- 4. Gia tri mac dinh cua Ve, PhanCong (3 dong) va GiaVe cho phep NULL (is_nullable = 1)
SELECT name AS rang_buoc_mac_dinh FROM sys.default_constraints
WHERE name IN ('DF_Ve_MaVe', 'DF_Ve_LanBan', 'DF_PhanCong_ThuLao');
SELECT name AS cot, is_nullable FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.Ve') AND name = 'GiaVe';

-- 5. Danh muc o chi nhanh: tren AWS la bang that (replication), KHONG duoc co SYNONYM
SELECT name, base_object_name FROM sys.synonyms ORDER BY name;
