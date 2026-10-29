-- ==============================================================================
-- Migration: V202610231000__A_sprint2_reports_and_salary.sql
-- Người A: Báo cáo thống kê (UC-016), Chốt lương tháng (UC-017)
-- Sprint 2: Toàn bộ truy vấn thông qua Stored Procedures (T-SQL)
-- ==============================================================================

-- ==============================================================================
-- 0. TỰ ĐỘNG KHỞI TẠO SYNONYM TRỎ VỀ HÀ NỘI CHO CÁC SITE CHI NHÁNH (ĐÀ NẴNG / HCM)
-- ==============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ThamSo')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'ThamSo')
        EXEC('CREATE SYNONYM dbo.ThamSo FOR SERVER_HN.QLXeKhach_HN.dbo.ThamSo');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'DoPhucTap')
        EXEC('CREATE SYNONYM dbo.DoPhucTap FOR SERVER_HN.QLXeKhach_HN.dbo.DoPhucTap');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'LoaiXe')
        EXEC('CREATE SYNONYM dbo.LoaiXe FOR SERVER_HN.QLXeKhach_HN.dbo.LoaiXe');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'LoaiNgay')
        EXEC('CREATE SYNONYM dbo.LoaiNgay FOR SERVER_HN.QLXeKhach_HN.dbo.LoaiNgay');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'LichNgay')
        EXEC('CREATE SYNONYM dbo.LichNgay FOR SERVER_HN.QLXeKhach_HN.dbo.LichNgay');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'TuyenDuong')
        EXEC('CREATE SYNONYM dbo.TuyenDuong FOR SERVER_HN.QLXeKhach_HN.dbo.TuyenDuong');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'BangGiaVe')
        EXEC('CREATE SYNONYM dbo.BangGiaVe FOR SERVER_HN.QLXeKhach_HN.dbo.BangGiaVe');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'ChiNhanh')
        EXEC('CREATE SYNONYM dbo.ChiNhanh FOR SERVER_HN.QLXeKhach_HN.dbo.ChiNhanh');
END;
GO

-- ==============================================================================
-- 1. SP: Lấy danh sách các tháng có chuyến (phục vụ Combobox Tháng ở MH05)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_LayDanhSachThangCoChuyen
    @ThangHienTai VARCHAR(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ThangHienTai IS NULL OR @ThangHienTai = ''
        SET @ThangHienTai = FORMAT(GETDATE(), 'yyyy-MM');

    CREATE TABLE #DanhSachThang (
        Thang VARCHAR(7),
        ThuTu INT
    );

    -- 1. Luôn đưa tháng hiện tại vào đầu danh sách (ThuTu = 0)
    INSERT INTO #DanhSachThang (Thang, ThuTu)
    VALUES (@ThangHienTai, 0);

    -- 2. Thêm các tháng có chuyến từ bảng cục bộ (ThuTu = 1)
    INSERT INTO #DanhSachThang (Thang, ThuTu)
    SELECT DISTINCT FORMAT(GioKhoiHanhDK, 'yyyy-MM'), 1
    FROM ChuyenXe
    WHERE GioKhoiHanhDK IS NOT NULL
      AND FORMAT(GioKhoiHanhDK, 'yyyy-MM') <> @ThangHienTai;

    -- 3. Trả về kết quả: Tháng hiện tại đầu tiên, sau đó là các tháng có dữ liệu giảm dần
    SELECT Thang
    FROM (
        SELECT Thang, MIN(ThuTu) AS ThuTu
        FROM #DanhSachThang
        GROUP BY Thang
    ) t
    ORDER BY ThuTu ASC, Thang DESC;

    DROP TABLE #DanhSachThang;
END;
GO

-- ==============================================================================
-- 2. SP: Tổng hợp số liệu tháng (MH05 - 3 ô số tổng: Doanh thu F15, Số vé, Tổng lương F02)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_TongHopSoLieuThang
    @Thang VARCHAR(7) = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR @Thang = ''
        SET @Thang = FORMAT(GETDATE(), 'yyyy-MM');

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    -- Chuẩn hóa mã chi nhánh: Nếu không chỉ định hoặc là ALL, mặc định lấy chi nhánh hiện tại
    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    -- 1. Nếu đứng tại HN và chọn DN
    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_TongHopSoLieuThang @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- 2. Nếu đứng tại HN và chọn HCM
    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_TongHopSoLieuThang @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- 3. Truy vấn cục bộ
    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    -- Doanh thu tháng (F15) và Số vé tính doanh thu
    DECLARE @DoanhThuThang FLOAT = 0;
    DECLARE @SoVeTinhDoanhThu INT = 0;

    SELECT 
        @DoanhThuThang = ISNULL(SUM(v.GiaVe), 0),
        @SoVeTinhDoanhThu = COUNT(v.MaVe)
    FROM Ve v
    JOIN ChuyenXe cx ON v.MaChuyen = cx.MaChuyen
    JOIN Xe x ON cx.MaXe = x.MaXe
    WHERE cx.TrangThai = 'HoanThanh'
      AND cx.GioKhoiHanhDK >= @NgayDauThang
      AND cx.GioKhoiHanhDK < @NgayDauThangSau
      AND x.MaCN = @MaCN;

    -- Tổng lương tài xế (F02)
    DECLARE @TongLuongTaiXe FLOAT = 0;

    IF EXISTS (
        SELECT 1 
        FROM BangLuong bl
        JOIN TaiXe tx ON bl.MaTX = tx.MaTX
        WHERE bl.Thang = @Thang AND tx.MaCN = @MaCN
    )
    BEGIN
        SELECT @TongLuongTaiXe = ISNULL(SUM(bl.TongLuong), 0)
        FROM BangLuong bl
        JOIN TaiXe tx ON bl.MaTX = tx.MaTX
        WHERE bl.Thang = @Thang AND tx.MaCN = @MaCN;
    END
    ELSE
    BEGIN
        SELECT @TongLuongTaiXe = ISNULL(SUM(pc.ThuLao), 0)
        FROM PhanCong pc
        JOIN ChuyenXe cx ON pc.MaChuyen = cx.MaChuyen
        JOIN TaiXe tx ON pc.MaTX = tx.MaTX
        WHERE cx.TrangThai = 'HoanThanh'
          AND cx.GioKhoiHanhDK >= @NgayDauThang
          AND cx.GioKhoiHanhDK < @NgayDauThangSau
          AND tx.MaCN = @MaCN;
    END;

    SELECT 
        @Thang AS Thang,
        @DoanhThuThang AS DoanhThuThang,
        @SoVeTinhDoanhThu AS SoVeTinhDoanhThu,
        @TongLuongTaiXe AS TongLuongTaiXe;
END;
GO

-- ==============================================================================
-- 3. SP: sp_R01 - Báo cáo Lương tài xế (MH05 Tab 1)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R01
    @Thang VARCHAR(7) = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR @Thang = ''
        SET @Thang = FORMAT(GETDATE(), 'yyyy-MM');

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    -- Chuẩn hóa tham số @MaCN
    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    -- 1. Nếu đứng tại Site HN và chọn xem riêng Site DN (CN02)
    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_R01 @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- 2. Nếu đứng tại Site HN và chọn xem riêng Site HCM (CN03)
    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_R01 @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- 3. Truy vấn cục bộ (tại @LocalBranch)
    -- 3.1. Nếu tháng đã chốt lương -> Lấy trực tiếp từ snapshot BangLuong
    IF EXISTS (
        SELECT 1 
        FROM BangLuong bl
        JOIN TaiXe tx ON bl.MaTX = tx.MaTX
        WHERE bl.Thang = @Thang 
          AND tx.MaCN = @MaCN
    )
    BEGIN
        SELECT 
            bl.MaTX,
            tx.HoDem,
            tx.Ten,
            (tx.HoDem + ' ' + tx.Ten) AS HoTen,
            tx.MaCN,
            ISNULL(cn.TenCN, tx.MaCN) AS TenCN,
            bl.SoChuyenLai,
            bl.SoChuyenPhu,
            bl.TongLuong
        FROM BangLuong bl
        JOIN TaiXe tx ON bl.MaTX = tx.MaTX
        LEFT JOIN ChiNhanh cn ON tx.MaCN = cn.MaCN
        WHERE bl.Thang = @Thang
          AND tx.MaCN = @MaCN
          AND tx.TrangThai = 'DangLam'
        ORDER BY bl.TongLuong DESC, bl.MaTX ASC;
        RETURN;
    END;

    -- 3.2. Nếu tháng chưa chốt -> Tính toán động từ các chuyến Hoàn thành
    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    SELECT 
        tx.MaTX,
        tx.HoDem,
        tx.Ten,
        (tx.HoDem + ' ' + tx.Ten) AS HoTen,
        tx.MaCN,
        ISNULL(cn.TenCN, tx.MaCN) AS TenCN,
        COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND pc.VaiTro = 'LAI' THEN 1 END) AS SoChuyenLai,
        COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND pc.VaiTro = 'PHU' THEN 1 END) AS SoChuyenPhu,
        ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' THEN pc.ThuLao ELSE 0 END), 0) AS TongLuong
    FROM TaiXe tx
    LEFT JOIN ChiNhanh cn ON tx.MaCN = cn.MaCN
    LEFT JOIN PhanCong pc ON tx.MaTX = pc.MaTX
    LEFT JOIN ChuyenXe c ON pc.MaChuyen = c.MaChuyen 
                         AND c.GioKhoiHanhDK >= @NgayDauThang 
                         AND c.GioKhoiHanhDK < @NgayDauThangSau
    WHERE tx.MaCN = @MaCN
      AND tx.TrangThai = 'DangLam'
    GROUP BY tx.MaTX, tx.HoDem, tx.Ten, tx.MaCN, cn.TenCN
    ORDER BY TongLuong DESC, tx.MaTX ASC;
END;
GO

-- ==============================================================================
-- 4. SP: sp_R02 - Báo cáo Doanh thu theo xe (MH05 Tab 2)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R02
    @Thang VARCHAR(7) = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR @Thang = ''
        SET @Thang = FORMAT(GETDATE(), 'yyyy-MM');

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_R02 @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_R02 @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- Truy vấn cục bộ
    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    DECLARE @TongDoanhThu FLOAT = 0;

    SELECT @TongDoanhThu = ISNULL(SUM(v.GiaVe), 0)
    FROM Ve v
    JOIN ChuyenXe c ON v.MaChuyen = c.MaChuyen
    JOIN Xe x ON c.MaXe = x.MaXe
    WHERE c.TrangThai = 'HoanThanh'
      AND v.TrangThai = 'DaBan'
      AND c.GioKhoiHanhDK >= @NgayDauThang
      AND c.GioKhoiHanhDK < @NgayDauThangSau
      AND x.TrangThai = 'HoatDong'
      AND x.MaCN = @MaCN;

    SELECT 
        x.MaXe,
        x.BienSo,
        ISNULL(lx.TenLoaiXe, x.MaLoaiXe) AS TenLoaiXe,
        x.MaCN,
        ISNULL(cn.TenCN, x.MaCN) AS TenCN,
        COUNT(DISTINCT CASE WHEN c.TrangThai = 'HoanThanh' THEN c.MaChuyen END) AS SoChuyen,
        COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.MaVe END) AS SoVe,
        ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.GiaVe ELSE 0 END), 0) AS DoanhThu,
        CASE 
            WHEN @TongDoanhThu > 0 THEN 
                ROUND(ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.GiaVe ELSE 0 END), 0) * 100.0 / @TongDoanhThu, 2)
            ELSE 0.0
        END AS TyLe
    FROM Xe x
    LEFT JOIN LoaiXe lx ON x.MaLoaiXe = lx.MaLoaiXe
    LEFT JOIN ChiNhanh cn ON x.MaCN = cn.MaCN
    LEFT JOIN ChuyenXe c ON x.MaXe = c.MaXe 
                        AND c.GioKhoiHanhDK >= @NgayDauThang 
                        AND c.GioKhoiHanhDK < @NgayDauThangSau
    LEFT JOIN Ve v ON c.MaChuyen = v.MaChuyen AND v.TrangThai = 'DaBan'
    WHERE x.TrangThai = 'HoatDong'
      AND x.MaCN = @MaCN
    GROUP BY x.MaXe, x.BienSo, lx.TenLoaiXe, x.MaLoaiXe, x.MaCN, cn.TenCN
    ORDER BY DoanhThu DESC, x.BienSo ASC;
END;
GO

-- ==============================================================================
-- 5. SP: sp_R03 - Báo cáo Doanh thu theo tuyến (MH05 Tab 3)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R03
    @Thang VARCHAR(7) = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR @Thang = ''
        SET @Thang = FORMAT(GETDATE(), 'yyyy-MM');

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_R03 @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_R03 @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- Truy vấn cục bộ
    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    DECLARE @TongDoanhThu FLOAT = 0;

    SELECT @TongDoanhThu = ISNULL(SUM(v.GiaVe), 0)
    FROM Ve v
    JOIN ChuyenXe c ON v.MaChuyen = c.MaChuyen
    JOIN Xe x ON c.MaXe = x.MaXe
    WHERE c.TrangThai = 'HoanThanh'
      AND v.TrangThai = 'DaBan'
      AND c.GioKhoiHanhDK >= @NgayDauThang
      AND c.GioKhoiHanhDK < @NgayDauThangSau
      AND x.MaCN = @MaCN;

    SELECT 
        t.MaTuyen,
        (t.DiemDau + N' – ' + t.DiemCuoi) AS TenTuyen,
        t.CapDo,
        t.DoDaiKm,
        COUNT(DISTINCT CASE WHEN c.TrangThai = 'HoanThanh' THEN c.MaChuyen END) AS SoChuyen,
        COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.MaVe END) AS SoVe,
        ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.GiaVe ELSE 0 END), 0) AS DoanhThu,
        CASE 
            WHEN @TongDoanhThu > 0 THEN 
                ROUND(ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.GiaVe ELSE 0 END), 0) * 100.0 / @TongDoanhThu, 2)
            ELSE 0.0
        END AS TyLe
    FROM TuyenDuong t
    LEFT JOIN ChuyenXe c ON t.MaTuyen = c.MaTuyen 
                        AND c.GioKhoiHanhDK >= @NgayDauThang 
                        AND c.GioKhoiHanhDK < @NgayDauThangSau
    LEFT JOIN Xe x ON c.MaXe = x.MaXe AND x.MaCN = @MaCN
    LEFT JOIN Ve v ON c.MaChuyen = v.MaChuyen AND v.TrangThai = 'DaBan'
    GROUP BY t.MaTuyen, t.DiemDau, t.DiemCuoi, t.CapDo, t.DoDaiKm
    ORDER BY DoanhThu DESC, t.MaTuyen ASC;
END;
GO

-- ==============================================================================
-- 6. SP: sp_R04 - Báo cáo Doanh thu theo loại xe (MH05 Tab 4)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R04
    @Thang VARCHAR(7) = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR @Thang = ''
        SET @Thang = FORMAT(GETDATE(), 'yyyy-MM');

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_R04 @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_R04 @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- Truy vấn cục bộ
    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    DECLARE @TongDoanhThu FLOAT = 0;

    SELECT @TongDoanhThu = ISNULL(SUM(v.GiaVe), 0)
    FROM Ve v
    JOIN ChuyenXe c ON v.MaChuyen = c.MaChuyen
    JOIN Xe x ON c.MaXe = x.MaXe
    WHERE c.TrangThai = 'HoanThanh'
      AND v.TrangThai = 'DaBan'
      AND c.GioKhoiHanhDK >= @NgayDauThang
      AND c.GioKhoiHanhDK < @NgayDauThangSau
      AND x.MaCN = @MaCN;

    SELECT 
        lx.MaLoaiXe,
        lx.TenLoaiXe,
        lx.SoGhe,
        COUNT(DISTINCT CASE WHEN c.TrangThai = 'HoanThanh' THEN c.MaChuyen END) AS SoChuyen,
        COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.MaVe END) AS SoVe,
        ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.GiaVe ELSE 0 END), 0) AS DoanhThu,
        CASE 
            WHEN @TongDoanhThu > 0 THEN 
                ROUND(ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' AND v.TrangThai = 'DaBan' THEN v.GiaVe ELSE 0 END), 0) * 100.0 / @TongDoanhThu, 2)
            ELSE 0.0
        END AS TyLe
    FROM LoaiXe lx
    LEFT JOIN Xe x ON lx.MaLoaiXe = x.MaLoaiXe AND x.MaCN = @MaCN
    LEFT JOIN ChuyenXe c ON x.MaXe = c.MaXe 
                        AND c.GioKhoiHanhDK >= @NgayDauThang 
                        AND c.GioKhoiHanhDK < @NgayDauThangSau
    LEFT JOIN Ve v ON c.MaChuyen = v.MaChuyen AND v.TrangThai = 'DaBan'
    GROUP BY lx.MaLoaiXe, lx.TenLoaiXe, lx.SoGhe
    ORDER BY DoanhThu DESC, lx.MaLoaiXe ASC;
END;
GO

-- ==============================================================================
-- 7. SP: sp_R06 - Báo cáo Xe quá hạn bảo dưỡng (MH05 Tab 5)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R06
    @NgayXet DATE = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @NgayXet IS NULL
        SET @NgayXet = CAST(GETDATE() AS DATE);

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_R06 @NgayXet = @pNgayXet, @MaCN = ''CN02''',
            N'@pNgayXet DATE',
            @pNgayXet = @NgayXet;
        RETURN;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_R06 @NgayXet = @pNgayXet, @MaCN = ''CN03''',
            N'@pNgayXet DATE',
            @pNgayXet = @NgayXet;
        RETURN;
    END;

    -- Truy vấn cục bộ
    DECLARE @ChuKyBD INT = 360;
    DECLARE @KmMoiNgayBD FLOAT = 100;

    SELECT @ChuKyBD = CAST(GiaTri AS INT) FROM ThamSo WHERE MaThamSo = 'CHU_KY_BD';
    SELECT @KmMoiNgayBD = GiaTri FROM ThamSo WHERE MaThamSo = 'KM_MOI_NGAY_BD';

    IF @ChuKyBD IS NULL OR @ChuKyBD <= 0 SET @ChuKyBD = 360;
    IF @KmMoiNgayBD IS NULL OR @KmMoiNgayBD <= 0 SET @KmMoiNgayBD = 100;

    WITH XeBase AS (
        SELECT 
            x.MaXe,
            x.BienSo,
            x.MaLoaiXe,
            x.MaCN,
            x.NgayDuaVaoSD,
            ISNULL((SELECT MAX(bd.NgayBaoDuong) FROM BaoDuong bd WHERE bd.MaXe = x.MaXe), x.NgayDuaVaoSD) AS NgayBaoDuongGanNhat
        FROM Xe x
        WHERE x.TrangThai IN ('HoatDong', 'BaoDuong')
          AND x.MaCN = @MaCN
    ),
    XeKmLamViec AS (
        SELECT 
            xb.MaXe,
            xb.BienSo,
            xb.MaLoaiXe,
            xb.MaCN,
            xb.NgayDuaVaoSD,
            xb.NgayBaoDuongGanNhat,
            ISNULL(SUM(c.KmThucTe * dpt.HeSoDuongKho), 0) AS KmLamViec
        FROM XeBase xb
        LEFT JOIN ChuyenXe c ON xb.MaXe = c.MaXe 
                            AND c.TrangThai = 'HoanThanh' 
                            AND CAST(c.GioKhoiHanhDK AS DATE) >= xb.NgayBaoDuongGanNhat
        LEFT JOIN TuyenDuong t ON c.MaTuyen = t.MaTuyen
        LEFT JOIN DoPhucTap dpt ON t.CapDo = dpt.CapDo
        GROUP BY xb.MaXe, xb.BienSo, xb.MaLoaiXe, xb.MaCN, xb.NgayDuaVaoSD, xb.NgayBaoDuongGanNhat
    ),
    XeHanBaoDuong AS (
        SELECT 
            klv.MaXe,
            klv.BienSo,
            ISNULL(lx.TenLoaiXe, klv.MaLoaiXe) AS TenLoaiXe,
            klv.MaCN,
            ISNULL(cn.TenCN, klv.MaCN) AS TenCN,
            klv.NgayDuaVaoSD,
            klv.NgayBaoDuongGanNhat,
            klv.KmLamViec,
            DATEADD(DAY, @ChuKyBD - FLOOR(klv.KmLamViec / @KmMoiNgayBD), klv.NgayBaoDuongGanNhat) AS NgayBaoDuongTiepTheo
        FROM XeKmLamViec klv
        LEFT JOIN LoaiXe lx ON klv.MaLoaiXe = lx.MaLoaiXe
        LEFT JOIN ChiNhanh cn ON klv.MaCN = cn.MaCN
    )
    SELECT 
        MaXe,
        BienSo,
        TenLoaiXe,
        MaCN,
        TenCN,
        NgayDuaVaoSD,
        NgayBaoDuongGanNhat,
        KmLamViec,
        NgayBaoDuongTiepTheo,
        DATEDIFF(DAY, NgayBaoDuongTiepTheo, @NgayXet) AS SoNgayQuaHan
    FROM XeHanBaoDuong
    WHERE NgayBaoDuongTiepTheo < @NgayXet
    ORDER BY SoNgayQuaHan DESC, BienSo ASC;
END;
GO

-- ==============================================================================
-- 8. SP: sp_ChotLuongThang (MH05 - Nút Chốt lương tháng)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_ChotLuongThang
    @Thang VARCHAR(7),
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR LEN(@Thang) <> 7 OR SUBSTRING(@Thang, 5, 1) <> '-'
    BEGIN
        RAISERROR(N'Tháng chốt lương không hợp lệ (định dạng chuẩn: yyyy-MM).', 16, 1);
        RETURN;
    END;

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_ChotLuongThang @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_ChotLuongThang @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- Truy vấn cục bộ
    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);
    DECLARE @NgayChotHienTai DATETIME = GETDATE();

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE bl
        FROM BangLuong bl
        JOIN TaiXe tx ON bl.MaTX = tx.MaTX
        WHERE bl.Thang = @Thang
          AND tx.MaCN = @MaCN;

        INSERT INTO BangLuong (MaTX, Thang, SoChuyenLai, SoChuyenPhu, TongLuong, NgayChot)
        SELECT 
            tx.MaTX,
            @Thang AS Thang,
            COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND pc.VaiTro = 'LAI' THEN 1 END) AS SoChuyenLai,
            COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND pc.VaiTro = 'PHU' THEN 1 END) AS SoChuyenPhu,
            ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' THEN pc.ThuLao ELSE 0 END), 0) AS TongLuong,
            @NgayChotHienTai AS NgayChot
        FROM TaiXe tx
        LEFT JOIN PhanCong pc ON tx.MaTX = pc.MaTX
        LEFT JOIN ChuyenXe c ON pc.MaChuyen = c.MaChuyen 
                             AND c.GioKhoiHanhDK >= @NgayDauThang 
                             AND c.GioKhoiHanhDK < @NgayDauThangSau
        WHERE tx.MaCN = @MaCN
          AND tx.TrangThai = 'DangLam'
        GROUP BY tx.MaTX;

        DECLARE @SoDongDaLuu INT = @@ROWCOUNT;
        DECLARE @TongLuongDaLuu FLOAT = 0;

        SELECT @TongLuongDaLuu = ISNULL(SUM(bl.TongLuong), 0)
        FROM BangLuong bl
        JOIN TaiXe tx ON bl.MaTX = tx.MaTX
        WHERE bl.Thang = @Thang
          AND tx.MaCN = @MaCN;

        COMMIT TRANSACTION;

        SELECT 
            @Thang AS Thang,
            CAST(1 AS BIT) AS DaChot,
            @SoDongDaLuu AS SoDong,
            @TongLuongDaLuu AS TongLuong,
            @NgayChotHienTai AS NgayChot,
            N'Chốt lương tháng ' + @Thang + N' thành công cho ' + CAST(@SoDongDaLuu AS NVARCHAR(10)) + N' tài xế.' AS ThongBao;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ==============================================================================
-- 9. SP: sp_KiemTraTrangThaiChotLuong (MH05 - Dòng trạng thái chốt)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_KiemTraTrangThaiChotLuong
    @Thang VARCHAR(7),
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_KiemTraTrangThaiChotLuong @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_KiemTraTrangThaiChotLuong @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- Truy vấn cục bộ
    DECLARE @SoDong INT = 0;
    DECLARE @TongLuong FLOAT = 0;
    DECLARE @NgayChot DATETIME = NULL;

    SELECT 
        @SoDong = COUNT(bl.MaTX),
        @TongLuong = ISNULL(SUM(bl.TongLuong), 0),
        @NgayChot = MAX(bl.NgayChot)
    FROM BangLuong bl
    JOIN TaiXe tx ON bl.MaTX = tx.MaTX
    WHERE bl.Thang = @Thang
      AND tx.MaCN = @MaCN;

    IF @SoDong > 0
    BEGIN
        SELECT 
            @Thang AS Thang,
            CAST(1 AS BIT) AS DaChot,
            @SoDong AS SoDong,
            @TongLuong AS TongLuong,
            @NgayChot AS NgayChot,
            N'BangLuong đang có ' + CAST(@SoDong AS NVARCHAR(10)) + N' dòng của tháng ' + @Thang + N' (đã chốt)' AS ThongBao;
    END
    ELSE
    BEGIN
        SELECT 
            @Thang AS Thang,
            CAST(0 AS BIT) AS DaChot,
            0 AS SoDong,
            0.0 AS TongLuong,
            NULL AS NgayChot,
            N'Tháng ' + @Thang + N' chưa chốt lương' AS ThongBao;
    END;
END;
GO

-- ==============================================================================
-- 10. SP: sp_LayDanhSachBangLuong (Xem bảng lương đã chốt)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_LayDanhSachBangLuong
    @Thang VARCHAR(7),
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF @MaCN IS NOT NULL
    BEGIN
        SET @MaCN = UPPER(LTRIM(RTRIM(@MaCN)));
        IF @MaCN = 'HN' SET @MaCN = 'CN01';
        ELSE IF @MaCN = 'DN' SET @MaCN = 'CN02';
        ELSE IF @MaCN = 'HCM' SET @MaCN = 'CN03';
        ELSE IF @MaCN = 'ALL' OR @MaCN = 'TAT_CA' OR @MaCN = '' SET @MaCN = @LocalBranch;
    END
    ELSE
    BEGIN
        SET @MaCN = @LocalBranch;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_LayDanhSachBangLuong @Thang = @pThang, @MaCN = ''CN02''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    IF (@LocalBranch = 'CN01' AND @MaCN = 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_LayDanhSachBangLuong @Thang = @pThang, @MaCN = ''CN03''',
            N'@pThang VARCHAR(7)',
            @pThang = @Thang;
        RETURN;
    END;

    -- Truy vấn cục bộ
    SELECT 
        bl.MaTX,
        tx.HoDem,
        tx.Ten,
        (tx.HoDem + ' ' + tx.Ten) AS HoTen,
        tx.MaCN,
        ISNULL(cn.TenCN, tx.MaCN) AS TenCN,
        bl.Thang,
        bl.SoChuyenLai,
        bl.SoChuyenPhu,
        bl.TongLuong,
        bl.NgayChot
    FROM BangLuong bl
    JOIN TaiXe tx ON bl.MaTX = tx.MaTX
    LEFT JOIN ChiNhanh cn ON tx.MaCN = cn.MaCN
    WHERE bl.Thang = @Thang
      AND tx.MaCN = @MaCN
    ORDER BY bl.TongLuong DESC, bl.MaTX ASC;
END;
GO
