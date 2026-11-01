-- ==============================================================================
-- Migration: V202610291000__C_doi_xe.sql
-- Người C: Đội xe và kỹ thuật (LoaiXe, Xe, DangKiem, BaoDuong)
-- UC-001 (phần xe), UC-005, UC-006, UC-014, UC-015
-- View vw_LichBaoDuong (F10, F11, F13), hàm chu kỳ đăng kiểm F12,
-- hàm/thủ tục kiểm tra xe đủ điều kiện chạy (giao tiếp #2 cho TR04 của B).
--
-- Chạy trên cả 3 nút (HN, DN, HCM). Bảng Xe, DangKiem, BaoDuong phân mảnh ngang
-- theo chi nhánh; danh mục (LoaiXe, ThamSo, DoPhucTap, TuyenDuong) đọc qua
-- SYNONYM trỏ về HN ở các nút chi nhánh.
--
-- "Ngày hiện tại" do BE truyền vào (@NgayHienTai, từ CurrentDateProvider) để
-- prototype cố định 02/06/2025; NULL thì dùng ngày của SQL Server.
--
-- Mã THROW của C (BE ánh xạ ở ErrorCode):
--   55001 E28 · 55002 E29 · 55003 E30 · 55004 E31 (bảo dưỡng)
--   58001 E09 · 58002 E07 · 58003 E08 · 58004 E10 (thêm / xóa xe)
--   59001 E09 · 59002 E31 (đăng kiểm)
--   50401 E15 · 50403 E17 · 50404 E18 (kiểm tra xe cho TR04)
-- ==============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ==============================================================================
-- 0. SYNONYM danh mục cho nút chi nhánh (giống migration của A, chạy độc lập được)
-- ==============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'LoaiXe')
   AND NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'LoaiXe')
    EXEC('CREATE SYNONYM dbo.LoaiXe FOR SERVER_HN.QLXeKhach_HN.dbo.LoaiXe');
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ThamSo')
   AND NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'ThamSo')
    EXEC('CREATE SYNONYM dbo.ThamSo FOR SERVER_HN.QLXeKhach_HN.dbo.ThamSo');
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DoPhucTap')
   AND NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'DoPhucTap')
    EXEC('CREATE SYNONYM dbo.DoPhucTap FOR SERVER_HN.QLXeKhach_HN.dbo.DoPhucTap');
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TuyenDuong')
   AND NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'TuyenDuong')
    EXEC('CREATE SYNONYM dbo.TuyenDuong FOR SERVER_HN.QLXeKhach_HN.dbo.TuyenDuong');
GO

-- ==============================================================================
-- 1. Ràng buộc CK_DK_Ngay (SRS 11.2 mục 4): Đạt thì có hạn sau ngày đăng kiểm,
--    Không đạt thì NgayHetHan để trống. NOCHECK để không vỡ dữ liệu cũ (nếu có).
-- ==============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE name = 'CK_DK_Ngay' AND parent_object_id = OBJECT_ID('dbo.DangKiem'))
    ALTER TABLE dbo.DangKiem WITH NOCHECK ADD CONSTRAINT CK_DK_Ngay CHECK (
        (KetQua = 'Dat' AND NgayHetHan IS NOT NULL AND NgayHetHan > NgayDangKiem)
        OR (KetQua = 'KhongDat' AND NgayHetHan IS NULL)
    );
GO

-- ==============================================================================
-- 2. F12 – Chu kỳ đăng kiểm (tháng) theo tuổi xe
--    Tuổi xe = năm hiện tại − NamSanXuat; tuổi ≥ TUOI_XE_CU → CHU_KY_DK_CU,
--    ngược lại CHU_KY_DK_MOI. Viết một lần, dùng ở mọi thủ tục của C.
-- ==============================================================================
CREATE OR ALTER FUNCTION dbo.fn_ChuKyDangKiem (@NamSanXuat INT, @NgayHienTai DATE)
RETURNS INT
AS
BEGIN
    DECLARE @TuoiXeCu FLOAT, @ChuKyCu FLOAT, @ChuKyMoi FLOAT;

    SELECT
        @TuoiXeCu = MAX(CASE WHEN MaThamSo = 'TUOI_XE_CU' THEN GiaTri END),
        @ChuKyCu = MAX(CASE WHEN MaThamSo = 'CHU_KY_DK_CU' THEN GiaTri END),
        @ChuKyMoi = MAX(CASE WHEN MaThamSo = 'CHU_KY_DK_MOI' THEN GiaTri END)
    FROM ThamSo
    WHERE MaThamSo IN ('TUOI_XE_CU', 'CHU_KY_DK_CU', 'CHU_KY_DK_MOI');

    RETURN CASE
        WHEN YEAR(@NgayHienTai) - @NamSanXuat >= ISNULL(@TuoiXeCu, 5) THEN CAST(ISNULL(@ChuKyCu, 6) AS INT)
        ELSE CAST(ISNULL(@ChuKyMoi, 12) AS INT)
    END;
END;
GO

-- ==============================================================================
-- 3. vw_LichBaoDuong – lịch bảo dưỡng, đăng kiểm của từng xe (tính khi xem)
--    F10 KmLamViec = Σ KmThucTe × HeSoDuongKho của chuyến Hoàn thành có ngày
--        khởi hành ≥ ngày bảo dưỡng gần nhất (chưa có thì ngày đưa vào sử dụng)
--    F11 NgayBDTiepTheo = mốc + CHU_KY_BD − ⌊KmLamViec ÷ KM_MOI_NGAY_BD⌋
--    F13 HanDangKiem = MAX(NgayHetHan) các lần Đạt
--    Cột chốt cho A (giao tiếp #6): MaXe, BienSo, NgayBDTiepTheo, HanDangKiem.
-- ==============================================================================
CREATE OR ALTER VIEW dbo.vw_LichBaoDuong
AS
WITH ThamSoBD AS (
    SELECT
        CAST(ISNULL(MAX(CASE WHEN MaThamSo = 'CHU_KY_BD' THEN GiaTri END), 360) AS INT) AS ChuKyBD,
        ISNULL(NULLIF(MAX(CASE WHEN MaThamSo = 'KM_MOI_NGAY_BD' THEN GiaTri END), 0), 100) AS KmMoiNgayBD
    FROM ThamSo
    WHERE MaThamSo IN ('CHU_KY_BD', 'KM_MOI_NGAY_BD')
),
XeMoc AS (
    SELECT
        x.MaXe, x.BienSo, x.MaLoaiXe, x.MaCN, x.NamSanXuat, x.NgayDuaVaoSD, x.TrangThai,
        bd.NgayBDGanNhat,
        ISNULL(bd.NgayBDGanNhat, x.NgayDuaVaoSD) AS NgayMocBD
    FROM Xe x
    OUTER APPLY (SELECT MAX(b.NgayBaoDuong) AS NgayBDGanNhat FROM BaoDuong b WHERE b.MaXe = x.MaXe) bd
),
XeKm AS (
    SELECT
        m.MaXe,
        SUM(ISNULL(c.KmThucTe, 0) * ISNULL(dpt.HeSoDuongKho, 1)) AS KmLamViec
    FROM XeMoc m
    JOIN ChuyenXe c ON c.MaXe = m.MaXe
                   AND c.TrangThai = 'HoanThanh'
                   AND CAST(c.GioKhoiHanhDK AS DATE) >= m.NgayMocBD
    LEFT JOIN TuyenDuong t ON t.MaTuyen = c.MaTuyen
    LEFT JOIN DoPhucTap dpt ON dpt.CapDo = t.CapDo
    GROUP BY m.MaXe
)
SELECT
    m.MaXe,
    m.BienSo,
    m.MaLoaiXe,
    lx.TenLoaiXe,
    lx.SoGhe,
    m.MaCN,
    m.NamSanXuat,
    m.NgayDuaVaoSD,
    m.TrangThai,
    m.NgayBDGanNhat,
    m.NgayMocBD,
    CAST(ISNULL(k.KmLamViec, 0) AS FLOAT) AS KmLamViec,
    DATEADD(DAY,
            ts.ChuKyBD - CAST(FLOOR(ISNULL(k.KmLamViec, 0) / ts.KmMoiNgayBD) AS INT),
            m.NgayMocBD) AS NgayBDTiepTheo,
    dk.HanDangKiem,
    dk.NgayDKGanNhat
FROM XeMoc m
CROSS JOIN ThamSoBD ts
LEFT JOIN XeKm k ON k.MaXe = m.MaXe
LEFT JOIN LoaiXe lx ON lx.MaLoaiXe = m.MaLoaiXe
OUTER APPLY (
    SELECT
        MAX(CASE WHEN d.KetQua = 'Dat' THEN d.NgayHetHan END) AS HanDangKiem,
        MAX(d.NgayDangKiem) AS NgayDKGanNhat
    FROM DangKiem d
    WHERE d.MaXe = m.MaXe
) dk;
GO

-- ==============================================================================
-- 4. Hàm kiểm tra xe đủ điều kiện chạy tại ngày khởi hành (giao tiếp #2 → B, TR04)
--    Trả 0 nếu hợp lệ, ngược lại mã THROW: 50401 (E15) xe không Hoạt động,
--    50403 (E17) chưa/hết hạn đăng kiểm, 50404 (E18) quá hạn bảo dưỡng.
--    Kiểm tra xe trùng giờ (50402, E16) vẫn do TR04 của B làm.
-- ==============================================================================
CREATE OR ALTER FUNCTION dbo.fn_KiemTraXeDuDieuKien (@MaXe VARCHAR(10), @NgayKhoiHanh DATE)
RETURNS INT
AS
BEGIN
    DECLARE @TrangThai VARCHAR(20), @HanDangKiem DATE, @NgayBDTiepTheo DATE;

    SELECT @TrangThai = TrangThai, @HanDangKiem = HanDangKiem, @NgayBDTiepTheo = NgayBDTiepTheo
    FROM dbo.vw_LichBaoDuong
    WHERE MaXe = @MaXe;

    IF @TrangThai IS NULL OR @TrangThai <> 'HoatDong' RETURN 50401;
    IF @HanDangKiem IS NULL OR @HanDangKiem < @NgayKhoiHanh RETURN 50403;
    IF @NgayBDTiepTheo < @NgayKhoiHanh RETURN 50404;
    RETURN 0;
END;
GO

-- Bản THROW sẵn để trigger/thủ tục của B gọi một dòng: EXEC sp_KiemTraXeDuDieuKien @MaXe, @Ngay;
CREATE OR ALTER PROCEDURE sp_KiemTraXeDuDieuKien
    @MaXe VARCHAR(10),
    @NgayKhoiHanh DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Ma INT = dbo.fn_KiemTraXeDuDieuKien(@MaXe, @NgayKhoiHanh);

    IF @Ma = 50401 THROW 50401, N'Xe không ở trạng thái Hoạt động.', 1;
    IF @Ma = 50403 THROW 50403, N'Xe chưa đăng kiểm hoặc đã hết hạn tại ngày khởi hành.', 1;
    IF @Ma = 50404 THROW 50404, N'Xe đã quá hạn bảo dưỡng tại ngày khởi hành.', 1;
END;
GO

-- ==============================================================================
-- 5. Danh mục loại xe (giao tiếp #3)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_LayDanhSachLoaiXe
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MaLoaiXe, TenLoaiXe, SoGhe
    FROM LoaiXe
    ORDER BY SoGhe ASC, MaLoaiXe ASC;
END;
GO

-- ==============================================================================
-- 6. Danh sách xe (MH01 Tab 3, giao tiếp #3)
--    @MaCN trống hoặc là chi nhánh của nút này → đọc cục bộ;
--    chi nhánh khác → gọi đúng thủ tục này ở nút đó qua Linked Server (chỉ đọc).
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_LayDanhSachXe
    @MaCN VARCHAR(10) = NULL,
    @TrangThai VARCHAR(20) = NULL,
    @MaXe VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalBranch VARCHAR(10) =
        CASE WHEN DB_NAME() LIKE '%DN%' THEN 'CN02' WHEN DB_NAME() LIKE '%HCM%' THEN 'CN03' ELSE 'CN01' END;

    IF @MaCN = '' SET @MaCN = NULL;
    IF @TrangThai = '' SET @TrangThai = NULL;
    IF @MaXe = '' SET @MaXe = NULL;

    IF @MaCN IS NOT NULL AND @MaCN <> @LocalBranch
    BEGIN
        DECLARE @Remote NVARCHAR(100) = CASE @MaCN
            WHEN 'CN01' THEN N'SERVER_HN.QLXeKhach_HN'
            WHEN 'CN02' THEN N'SERVER_DN.QLXeKhach_DN'
            WHEN 'CN03' THEN N'SERVER_HCM.QLXeKhach_HCM'
        END;
        IF @Remote IS NULL RETURN;

        DECLARE @Sql NVARCHAR(400) = N'EXEC ' + @Remote
            + N'.dbo.sp_LayDanhSachXe @MaCN = @pMaCN, @TrangThai = @pTrangThai, @MaXe = @pMaXe;';
        EXEC sp_executesql @Sql,
            N'@pMaCN VARCHAR(10), @pTrangThai VARCHAR(20), @pMaXe VARCHAR(10)',
            @pMaCN = @MaCN, @pTrangThai = @TrangThai, @pMaXe = @MaXe;
        RETURN;
    END;

    SELECT
        v.MaXe,
        v.BienSo,
        v.MaLoaiXe,
        v.TenLoaiXe,
        v.SoGhe,
        v.NamSanXuat,
        v.NgayDuaVaoSD,
        v.TrangThai,
        v.MaCN,
        v.HanDangKiem,
        (SELECT COUNT(*) FROM ChuyenXe c WHERE c.MaXe = v.MaXe) AS SoChuyen
    FROM dbo.vw_LichBaoDuong v
    WHERE (@TrangThai IS NULL OR v.TrangThai = @TrangThai)
      AND (@MaXe IS NULL OR v.MaXe = @MaXe)
    ORDER BY v.MaXe ASC;
END;
GO

-- ==============================================================================
-- 7. Lịch bảo dưỡng, đăng kiểm của xe thuộc nút này (MH04.1, MH04.4, MH01.0)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_LayLichBaoDuong
    @MaXe VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        MaXe, BienSo, MaLoaiXe, TenLoaiXe, MaCN, NamSanXuat, NgayDuaVaoSD, TrangThai,
        NgayBDGanNhat, NgayMocBD, KmLamViec, NgayBDTiepTheo, HanDangKiem, NgayDKGanNhat
    FROM dbo.vw_LichBaoDuong
    WHERE (@MaXe IS NULL OR MaXe = @MaXe)
    ORDER BY MaXe ASC;
END;
GO

-- Tham số kỹ thuật dùng cho khung xem trước và dòng công thức MH04.4 (chỉ đọc)
CREATE OR ALTER PROCEDURE sp_LayThamSoKyThuat
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        CAST(ISNULL(MAX(CASE WHEN MaThamSo = 'CHU_KY_BD' THEN GiaTri END), 360) AS INT) AS ChuKyBD,
        CAST(ISNULL(MAX(CASE WHEN MaThamSo = 'KM_MOI_NGAY_BD' THEN GiaTri END), 100) AS FLOAT) AS KmMoiNgayBD,
        CAST(ISNULL(MAX(CASE WHEN MaThamSo = 'CANH_BAO_NGAY' THEN GiaTri END), 15) AS INT) AS CanhBaoNgay,
        CAST(ISNULL(MAX(CASE WHEN MaThamSo = 'CHU_KY_DK_CU' THEN GiaTri END), 6) AS INT) AS ChuKyDkCu,
        CAST(ISNULL(MAX(CASE WHEN MaThamSo = 'CHU_KY_DK_MOI' THEN GiaTri END), 12) AS INT) AS ChuKyDkMoi,
        CAST(ISNULL(MAX(CASE WHEN MaThamSo = 'TUOI_XE_CU' THEN GiaTri END), 5) AS INT) AS TuoiXeCu,
        (SELECT HeSoDuongKho FROM DoPhucTap WHERE CapDo = 1) AS HeSoDuongKho1,
        (SELECT HeSoDuongKho FROM DoPhucTap WHERE CapDo = 2) AS HeSoDuongKho2,
        (SELECT HeSoDuongKho FROM DoPhucTap WHERE CapDo = 3) AS HeSoDuongKho3
    FROM ThamSo;
END;
GO

-- ==============================================================================
-- 8. UC-005 – Thêm xe kèm đăng kiểm lần đầu (BR-MH01-07, BR-MH01-08)
--    Một giao dịch: INSERT Xe + INSERT DangKiem (Đạt). Lỗi bất kỳ → không lưu gì.
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_ThemXeVaDangKiem
    @BienSo VARCHAR(15),
    @MaLoaiXe VARCHAR(10),
    @NamSanXuat INT,
    @NgayDangKiem DATE,
    @MaCN VARCHAR(10) = NULL,
    @NgayHienTai DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalBranch VARCHAR(10) =
        CASE WHEN DB_NAME() LIKE '%DN%' THEN 'CN02' WHEN DB_NAME() LIKE '%HCM%' THEN 'CN03' ELSE 'CN01' END;

    IF @NgayHienTai IS NULL SET @NgayHienTai = CAST(GETDATE() AS DATE);
    IF @MaCN IS NULL OR LTRIM(RTRIM(@MaCN)) = '' SET @MaCN = @LocalBranch;
    SET @BienSo = UPPER(LTRIM(RTRIM(@BienSo)));

    -- Phân mảnh ngang: mỗi nút chỉ thêm xe của chi nhánh mình
    IF @MaCN <> @LocalBranch
        THROW 50000, N'Không thể thêm xe cho chi nhánh khác. Chi nhánh hiện tại chỉ thêm được xe của chính mình.', 1;

    IF @NamSanXuat < 2005 OR @NamSanXuat > YEAR(@NgayHienTai)
        THROW 58003, N'Năm sản xuất phải từ 2005 đến năm hiện tại.', 1;

    IF @NgayDangKiem > @NgayHienTai
        THROW 58001, N'Ngày đăng kiểm không được sau hôm nay.', 1;

    -- Biển số duy nhất toàn chuỗi: kiểm tra nút này rồi hỏi 2 nút còn lại.
    -- Nút khác không kết nối được thì bỏ qua (UNIQUE cục bộ vẫn chặn trùng tại nút).
    IF EXISTS (SELECT 1 FROM Xe WHERE BienSo = @BienSo)
        THROW 58002, N'Biển số đã tồn tại.', 1;

    DECLARE @Trung BIT = 0, @Remote NVARCHAR(100), @Sql NVARCHAR(400);
    DECLARE @Nut TABLE (MaCN VARCHAR(10), TenNut NVARCHAR(100));
    INSERT INTO @Nut VALUES
        ('CN01', N'SERVER_HN.QLXeKhach_HN'),
        ('CN02', N'SERVER_DN.QLXeKhach_DN'),
        ('CN03', N'SERVER_HCM.QLXeKhach_HCM');

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT TenNut FROM @Nut WHERE MaCN <> @LocalBranch;
    OPEN cur;
    FETCH NEXT FROM cur INTO @Remote;
    WHILE @@FETCH_STATUS = 0 AND @Trung = 0
    BEGIN
        BEGIN TRY
            SET @Sql = N'IF EXISTS (SELECT 1 FROM ' + @Remote + N'.dbo.Xe WHERE BienSo = @b) SET @t = 1;';
            EXEC sp_executesql @Sql, N'@b VARCHAR(15), @t BIT OUTPUT', @b = @BienSo, @t = @Trung OUTPUT;
        END TRY
        BEGIN CATCH
        END CATCH;
        FETCH NEXT FROM cur INTO @Remote;
    END;
    CLOSE cur;
    DEALLOCATE cur;

    IF @Trung = 1
        THROW 58002, N'Biển số đã tồn tại ở chi nhánh khác.', 1;

    DECLARE @MaXe VARCHAR(10), @MaxNum INT, @ChuKy INT, @HanDangKiem DATE;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Mã tự sinh tăng dần theo chi nhánh, không dùng lại (BR-MH01-11)
        IF @LocalBranch = 'CN02'
        BEGIN
            SELECT @MaxNum = ISNULL(MAX(TRY_CAST(SUBSTRING(MaXe, 6, 10) AS INT)), 0)
            FROM Xe WITH (UPDLOCK, HOLDLOCK) WHERE MaXe LIKE 'XE[_]DN%';
            SET @MaXe = 'XE_DN' + FORMAT(@MaxNum + 1, '00');
        END
        ELSE IF @LocalBranch = 'CN03'
        BEGIN
            SELECT @MaxNum = ISNULL(MAX(TRY_CAST(SUBSTRING(MaXe, 7, 10) AS INT)), 0)
            FROM Xe WITH (UPDLOCK, HOLDLOCK) WHERE MaXe LIKE 'XE[_]HCM%';
            SET @MaXe = 'XE_HCM' + FORMAT(@MaxNum + 1, '00');
        END
        ELSE
        BEGIN
            SELECT @MaxNum = ISNULL(MAX(TRY_CAST(SUBSTRING(MaXe, 3, 10) AS INT)), 0)
            FROM Xe WITH (UPDLOCK, HOLDLOCK) WHERE MaXe LIKE 'XE[0-9]%';
            SET @MaXe = 'XE' + FORMAT(@MaxNum + 1, '000');
        END;

        INSERT INTO Xe (MaXe, BienSo, MaLoaiXe, MaCN, NamSanXuat, NgayDuaVaoSD, TrangThai)
        VALUES (@MaXe, @BienSo, @MaLoaiXe, @MaCN, @NamSanXuat, @NgayHienTai, 'HoatDong');

        -- F12, F13: hạn = ngày đăng kiểm + chu kỳ theo tuổi xe
        SET @ChuKy = dbo.fn_ChuKyDangKiem(@NamSanXuat, @NgayHienTai);
        SET @HanDangKiem = DATEADD(MONTH, @ChuKy, @NgayDangKiem);

        INSERT INTO DangKiem (MaXe, NgayDangKiem, NgayHetHan, KetQua, ChiPhi)
        VALUES (@MaXe, @NgayDangKiem, @HanDangKiem, 'Dat', NULL);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT
        @MaXe AS MaXe,
        @BienSo AS BienSo,
        @HanDangKiem AS HanDangKiem,
        @ChuKy AS ChuKyThang,
        YEAR(@NgayHienTai) - @NamSanXuat AS TuoiXe;
END;
GO

-- ==============================================================================
-- 9. UC-006 – Xóa xe (BR-MH01-09). Xe đã có chuyến → 58004 (E10).
--    Lịch sử bảo dưỡng, đăng kiểm của xe xóa cùng trong 1 giao dịch.
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_XoaXe
    @MaXe VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM ChuyenXe WHERE MaXe = @MaXe)
        THROW 58004, N'Không xóa được xe đã có chuyến. Hãy đổi trạng thái sang Ngừng hoạt động.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM BaoDuong WHERE MaXe = @MaXe;
        DELETE FROM DangKiem WHERE MaXe = @MaXe;
        DELETE FROM Xe WHERE MaXe = @MaXe;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Đổi trạng thái xe (SRS 11.2 mục 5: Ngừng hoạt động thay cho xóa xe đã có chuyến)
CREATE OR ALTER PROCEDURE sp_DoiTrangThaiXe
    @MaXe VARCHAR(10),
    @TrangThai VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Xe SET TrangThai = @TrangThai WHERE MaXe = @MaXe;
END;
GO

-- ==============================================================================
-- 10. UC-014 – Ghi nhận bảo dưỡng (BR-MH04-04, BR-MH04-05)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_GhiNhanBaoDuong
    @MaXe VARCHAR(10),
    @NgayBaoDuong DATE,
    @ChiPhi FLOAT = NULL,
    @NoiDung NVARCHAR(255) = NULL,
    @NgayHienTai DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @NgayHienTai IS NULL SET @NgayHienTai = CAST(GETDATE() AS DATE);

    IF @NgayBaoDuong > @NgayHienTai
        THROW 55001, N'Ngày bảo dưỡng không được sau hôm nay.', 1;

    IF @ChiPhi < 0
        THROW 55004, N'Chi phí phải là số không âm.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @NgayGanNhat DATE;
        SELECT @NgayGanNhat = MAX(NgayBaoDuong) FROM BaoDuong WITH (UPDLOCK, HOLDLOCK) WHERE MaXe = @MaXe;

        IF @NgayGanNhat = @NgayBaoDuong
            THROW 55003, N'Xe đã có lần bảo dưỡng ngày này.', 1;

        IF @NgayGanNhat > @NgayBaoDuong
            THROW 55002, N'Ngày bảo dưỡng phải sau lần gần nhất.', 1;

        INSERT INTO BaoDuong (MaXe, NgayBaoDuong, NoiDung, ChiPhi)
        VALUES (@MaXe, @NgayBaoDuong, NULLIF(LTRIM(RTRIM(@NoiDung)), N''), @ChiPhi);

        -- Bảo dưỡng xong: xe đang chờ bảo dưỡng quay về Hoạt động; km làm việc tính lại từ 0
        UPDATE Xe SET TrangThai = 'HoatDong' WHERE MaXe = @MaXe AND TrangThai = 'BaoDuong';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT MaXe, BienSo, TrangThai, NgayBDGanNhat, KmLamViec, NgayBDTiepTheo
    FROM dbo.vw_LichBaoDuong
    WHERE MaXe = @MaXe;
END;
GO

-- ==============================================================================
-- 11. UC-015 – Gia hạn đăng kiểm (BR-MH04-06, BR-MH04-07)
--     Đạt: hạn = ngày + F12; hạn hiện hành = MAX các lần Đạt (đăng kiểm sớm không
--     làm ngắn hạn). Không đạt: NgayHetHan NULL, hạn hiện hành giữ nguyên.
--     Cùng ngày đã có kết quả (VD sáng Không đạt, chiều Đạt) → ghi đè kết quả trong ngày.
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_GhiNhanDangKiem
    @MaXe VARCHAR(10),
    @NgayDangKiem DATE,
    @KetQua VARCHAR(20),
    @ChiPhi FLOAT = NULL,
    @NgayHienTai DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @NgayHienTai IS NULL SET @NgayHienTai = CAST(GETDATE() AS DATE);

    IF @NgayDangKiem > @NgayHienTai
        THROW 59001, N'Ngày đăng kiểm không được sau hôm nay.', 1;

    IF @ChiPhi < 0
        THROW 59002, N'Chi phí phải là số không âm.', 1;

    DECLARE @NamSanXuat INT, @ChuKy INT, @NgayHetHan DATE;
    SELECT @NamSanXuat = NamSanXuat FROM Xe WHERE MaXe = @MaXe;

    SET @ChuKy = dbo.fn_ChuKyDangKiem(@NamSanXuat, @NgayHienTai);
    SET @NgayHetHan = CASE WHEN @KetQua = 'Dat' THEN DATEADD(MONTH, @ChuKy, @NgayDangKiem) END;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM DangKiem WITH (UPDLOCK, HOLDLOCK)
                   WHERE MaXe = @MaXe AND NgayDangKiem = @NgayDangKiem)
            UPDATE DangKiem
            SET NgayHetHan = @NgayHetHan, KetQua = @KetQua, ChiPhi = @ChiPhi
            WHERE MaXe = @MaXe AND NgayDangKiem = @NgayDangKiem;
        ELSE
            INSERT INTO DangKiem (MaXe, NgayDangKiem, NgayHetHan, KetQua, ChiPhi)
            VALUES (@MaXe, @NgayDangKiem, @NgayHetHan, @KetQua, @ChiPhi);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT
        v.MaXe,
        v.BienSo,
        @KetQua AS KetQua,
        @NgayHetHan AS NgayHetHan,
        v.HanDangKiem AS HanHienHanh,
        @ChuKy AS ChuKyThang,
        YEAR(@NgayHienTai) - @NamSanXuat AS TuoiXe
    FROM dbo.vw_LichBaoDuong v
    WHERE v.MaXe = @MaXe;
END;
GO
