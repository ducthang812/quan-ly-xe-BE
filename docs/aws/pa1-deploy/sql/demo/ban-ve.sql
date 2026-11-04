-- Demo: ban 1 ve tai chi nhanh bang CHINH thu tuc cua module B (giong BE goi), qua LISTENER cua site.
-- Bien: $(BRANCH_DB), $(MACN)
-- Ngay chuyen dat vao 06/2025 cho khop du lieu mau (dang kiem het han 2026-01-01, profile prototype).
USE [$(BRANCH_DB)];
SET NOCOUNT ON;
DECLARE @cn varchar(10) = '$(MACN)';
DECLARE @tuyen varchar(10), @xe varchar(10), @lai varchar(15), @phu varchar(15), @nv varchar(15),
        @chuyen varchar(15), @gio datetime, @ghe int, @sdt varchar(15);

SELECT TOP 1 @tuyen = MaTuyen FROM dbo.TuyenDuong ORDER BY MaTuyen;
IF @tuyen IS NULL
BEGIN
    RAISERROR(N'Chua co danh muc TuyenDuong: replication danh muc chua chay xong (buoc 5).', 16, 1);
    RETURN;
END
-- Xe 45 cho moi nhat chua co lich bao duong cu (tranh qua han bao duong)
SELECT TOP 1 @xe = MaXe FROM dbo.Xe
WHERE MaCN = @cn AND TrangThai = 'HoatDong' AND NOT EXISTS (SELECT 1 FROM dbo.BaoDuong b WHERE b.MaXe = Xe.MaXe)
ORDER BY MaXe DESC;
SELECT TOP 1 @lai = MaTX FROM dbo.TaiXe WHERE MaCN = @cn AND TrangThai = 'DangLam' AND HangGPLX IN ('E', 'FC') ORDER BY MaTX;
SELECT TOP 1 @phu = MaTX FROM dbo.TaiXe WHERE MaCN = @cn AND TrangThai = 'DangLam' AND MaTX <> @lai ORDER BY MaTX;
SELECT TOP 1 @nv  = MaNV FROM dbo.NhanVien WHERE MaCN = @cn ORDER BY MaNV;

-- Dung lai chuyen demo con 'KeHoach' cua xe nay, chua co thi tao bang sp_TaoChuyenVaPhanCong
SELECT TOP 1 @chuyen = MaChuyen FROM dbo.ChuyenXe
WHERE MaXe = @xe AND TrangThai = 'KeHoach' AND GioKhoiHanhDK >= '2025-06-03' ORDER BY GioKhoiHanhDK;
IF @chuyen IS NULL
BEGIN
    SET @gio = '2025-06-03T08:00:00';
    DECLARE @kq TABLE (MaChuyen varchar(15));
    INSERT @kq EXEC dbo.sp_TaoChuyenVaPhanCong @MaTuyen = @tuyen, @MaXe = @xe,
         @GioKhoiHanh = @gio, @GioDen = '2025-06-03T20:00:00', @MaLai = @lai, @MaPhu = @phu;
    SELECT @chuyen = MaChuyen FROM @kq;
END

-- Ghe 1-2 danh cho lai/phu xe (trigger trg_Ve_KiemTraSoCho chan), khach ngoi tu ghe 3
SELECT @ghe = ISNULL(MAX(SoGhe), 2) + 1 FROM dbo.Ve WHERE MaChuyen = @chuyen AND TrangThai = 'DaBan';
SET @sdt = '0999000' + RIGHT('000' + REPLACE(@cn, 'CN', ''), 3);
EXEC dbo.sp_BanVe @MaChuyen = @chuyen, @SoGhe = @ghe, @HoTen = N'Khách demo', @SoDienThoai = @sdt, @MaNVBan = @nv;

SELECT TOP 1 @@SERVERNAME AS ghi_vao_node, MaVe, MaChuyen, SoGhe, GiaVe, NgayBan
FROM dbo.Ve WHERE MaChuyen = @chuyen AND SoGhe = @ghe AND TrangThai = 'DaBan';
