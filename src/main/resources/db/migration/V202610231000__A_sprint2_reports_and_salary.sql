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
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM ChuyenXe)
    BEGIN
        SELECT '2025-06' AS Thang
        UNION
        SELECT '2025-05' AS Thang
        ORDER BY Thang DESC;
        RETURN;
    END;

    SELECT DISTINCT FORMAT(GioKhoiHanhDK, 'yyyy-MM') AS Thang
    FROM ChuyenXe
    ORDER BY Thang DESC;
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
        SET @Thang = '2025-06';

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    -- 1. Doanh thu tháng (F15) và Số vé tính doanh thu
    DECLARE @DoanhThuThang FLOAT = 0;
    DECLARE @SoVeTinhDoanhThu INT = 0;

    SELECT 
        @DoanhThuThang = ISNULL(SUM(v.GiaVe), 0),
        @SoVeTinhDoanhThu = COUNT(v.MaVe)
    FROM Ve v
    JOIN ChuyenXe c ON v.MaChuyen = c.MaChuyen
    JOIN Xe x ON c.MaXe = x.MaXe
    WHERE c.TrangThai = 'HoanThanh'
      AND v.TrangThai = 'DaBan'
      AND c.GioKhoiHanhDK >= @NgayDauThang
      AND c.GioKhoiHanhDK < @NgayDauThangSau
      AND (@MaCN IS NULL OR x.MaCN = @MaCN);

    -- 2. Tổng lương tài xế (F02)
    DECLARE @TongLuongTaiXe FLOAT = 0;

    SELECT 
        @TongLuongTaiXe = ISNULL(SUM(pc.ThuLao), 0)
    FROM PhanCong pc
    JOIN ChuyenXe c ON pc.MaChuyen = c.MaChuyen
    JOIN TaiXe tx ON pc.MaTX = tx.MaTX
    WHERE c.TrangThai = 'HoanThanh'
      AND c.GioKhoiHanhDK >= @NgayDauThang
      AND c.GioKhoiHanhDK < @NgayDauThangSau
      AND (@MaCN IS NULL OR tx.MaCN = @MaCN);

    SELECT 
        @Thang AS Thang,
        @DoanhThuThang AS DoanhThuThang,
        @SoVeTinhDoanhThu AS SoVeTinhDoanhThu,
        @TongLuongTaiXe AS TongLuongTaiXe;
END;
GO

-- ==============================================================================
-- 3. SP: sp_R01 - Báo cáo Lương tài xế (MH05 Tab 1)
-- BR-MH05-02: Lương tháng = tổng thù lao đã lưu của các phân công thuộc chuyến Hoàn thành
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R01
    @Thang VARCHAR(7) = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR @Thang = ''
        SET @Thang = '2025-06';

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

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
    WHERE (@MaCN IS NULL OR tx.MaCN = @MaCN)
      AND tx.TrangThai = 'DangLam'
    GROUP BY tx.MaTX, tx.HoDem, tx.Ten, tx.MaCN, cn.TenCN
    ORDER BY TongLuong DESC, tx.MaTX ASC;
END;
GO

-- ==============================================================================
-- 4. SP: sp_R02 - Báo cáo Doanh thu theo xe (MH05 Tab 2)
-- BR-MH05-01 & BR-MH05-03: Chỉ liệt kê xe đang Hoạt động
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R02
    @Thang VARCHAR(7) = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Thang IS NULL OR @Thang = ''
        SET @Thang = '2025-06';

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    -- Tính tổng doanh thu lọc theo điều kiện để tính tỷ lệ %
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
      AND (@MaCN IS NULL OR x.MaCN = @MaCN);

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
    WHERE x.TrangThai = 'HoatDong' -- BR-MH05-03: Chỉ liệt kê xe đang Hoạt động
      AND (@MaCN IS NULL OR x.MaCN = @MaCN)
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
        SET @Thang = '2025-06';

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

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
      AND (@MaCN IS NULL OR x.MaCN = @MaCN);

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
    LEFT JOIN Xe x ON c.MaXe = x.MaXe AND (@MaCN IS NULL OR x.MaCN = @MaCN)
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
        SET @Thang = '2025-06';

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

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
      AND (@MaCN IS NULL OR x.MaCN = @MaCN);

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
    LEFT JOIN Xe x ON lx.MaLoaiXe = x.MaLoaiXe AND (@MaCN IS NULL OR x.MaCN = @MaCN)
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
-- BR-MH05-04, Công thức F10 (Km làm việc), F11 (Ngày bảo dưỡng tiếp theo)
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_R06
    @NgayXet DATE = NULL,
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @NgayXet IS NULL
        SET @NgayXet = CAST(GETDATE() AS DATE);

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

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
        WHERE x.TrangThai IN ('HoatDong', 'BaoDuong') -- Chỉ xét xe khác NgungHD
          AND (@MaCN IS NULL OR x.MaCN = @MaCN)
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
            -- F11 = NgayBaoDuongGanNhat + CHU_KY_BD - FLOOR(KmLamViec / KM_MOI_NGAY_BD)
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
    WHERE NgayBaoDuongTiepTheo < @NgayXet -- BR-MH05-04: Quá hạn bảo dưỡng tại ngày xét
    ORDER BY SoNgayQuaHan DESC, BienSo ASC;
END;
GO

-- ==============================================================================
-- 8. SP: sp_ChotLuongThang (UC-017 Chốt lương tháng)
-- BR-MH05-05: Xóa lương cũ của tháng rồi ghi mới cho mọi tài xế (kể cả 0 đồng)
-- trong 1 giao dịch; số đã chốt không đổi khi dữ liệu sửa sau
-- ==============================================================================
CREATE OR ALTER PROCEDURE sp_ChotLuongThang
    @Thang VARCHAR(7),
    @MaCN VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Thang IS NULL OR LEN(@Thang) <> 7 OR SUBSTRING(@Thang, 5, 1) <> '-'
    BEGIN
        THROW 50000, N'Định dạng tháng không hợp lệ (bắt buộc yyyy-MM).', 1;
    END;

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

    DECLARE @NgayDauThang DATETIME = CAST(@Thang + '-01' AS DATETIME);
    DECLARE @NgayDauThangSau DATETIME = DATEADD(MONTH, 1, @NgayDauThang);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Xóa dữ liệu lương cũ của tháng trong BangLuong
        IF @MaCN IS NULL
        BEGIN
            DELETE FROM BangLuong WHERE Thang = @Thang;
        END
        ELSE
        BEGIN
            DELETE bl 
            FROM BangLuong bl
            JOIN TaiXe tx ON bl.MaTX = tx.MaTX
            WHERE bl.Thang = @Thang AND tx.MaCN = @MaCN;
        END;

        -- 2. Ghi mới cho mọi tài xế (kể cả 0 đồng)
        INSERT INTO BangLuong (MaTX, Thang, SoChuyenLai, SoChuyenPhu, TongLuong, NgayChot)
        SELECT 
            tx.MaTX,
            @Thang,
            COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND pc.VaiTro = 'LAI' THEN 1 END) AS SoChuyenLai,
            COUNT(CASE WHEN c.TrangThai = 'HoanThanh' AND pc.VaiTro = 'PHU' THEN 1 END) AS SoChuyenPhu,
            ISNULL(SUM(CASE WHEN c.TrangThai = 'HoanThanh' THEN pc.ThuLao ELSE 0 END), 0) AS TongLuong,
            GETDATE() AS NgayChot
        FROM TaiXe tx
        LEFT JOIN PhanCong pc ON tx.MaTX = pc.MaTX
        LEFT JOIN ChuyenXe c ON pc.MaChuyen = c.MaChuyen 
                             AND c.GioKhoiHanhDK >= @NgayDauThang 
                             AND c.GioKhoiHanhDK < @NgayDauThangSau
        WHERE (@MaCN IS NULL OR tx.MaCN = @MaCN)
        GROUP BY tx.MaTX;

        DECLARE @SoDongDaChot INT = @@ROWCOUNT;
        DECLARE @TongTienLuongDaChot FLOAT = 0;
        SELECT @TongTienLuongDaChot = ISNULL(SUM(TongLuong), 0) FROM BangLuong WHERE Thang = @Thang;

        COMMIT TRANSACTION;

        SELECT 
            @Thang AS Thang,
            @SoDongDaChot AS SoDong,
            @TongTienLuongDaChot AS TongLuong,
            @TongTienLuongDaChot AS TongTienLuong,
            GETDATE() AS NgayChot,
            N'Chốt lương tháng ' + @Thang + N' thành công với ' + CAST(@SoDongDaChot AS NVARCHAR(10)) + N' tài xế.' AS ThongBao;
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

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

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
      AND (@MaCN IS NULL OR tx.MaCN = @MaCN);

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

    IF @MaCN = 'ALL' OR @MaCN = ''
        SET @MaCN = NULL;

    SELECT 
        bl.MaTX,
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
      AND (@MaCN IS NULL OR tx.MaCN = @MaCN)
    ORDER BY bl.TongLuong DESC, bl.MaTX ASC;
END;
GO

