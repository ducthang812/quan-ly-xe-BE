-- ==============================================================================
-- Migration: V202610211000__A_stored_procedures.sql
-- Người A: Cấu hình, Tuyến đường, Giá vé, Tài xế, Tham số, Danh mục dùng chung
-- Sprint 0 & Sprint 1: Toàn bộ truy vấn thông qua Stored Procedures (T-SQL)
-- ==============================================================================

-- ==============================================================================
-- 0. TỰ ĐỘNG KHỞI TẠO SYNONYM TRỎ VỀ HÀ NỘI CHO CÁC SITE CHI NHÁNH (ĐÀ NẴNG / HCM)
-- Nếu trên database hiện tại chưa có bảng ThamSo vật lý, tự động tạo SYNONYM
-- sang SERVER_HN để các SP danh mục dùng chung truy vấn mượt mà qua Linked Server.
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
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'LichLoaiNgay')
        EXEC('CREATE SYNONYM dbo.LichLoaiNgay FOR SERVER_HN.QLXeKhach_HN.dbo.LichLoaiNgay');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'TuyenDuong')
        EXEC('CREATE SYNONYM dbo.TuyenDuong FOR SERVER_HN.QLXeKhach_HN.dbo.TuyenDuong');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'BangGiaVe')
        EXEC('CREATE SYNONYM dbo.BangGiaVe FOR SERVER_HN.QLXeKhach_HN.dbo.BangGiaVe');
    IF NOT EXISTS (SELECT 1 FROM sys.synonyms WHERE name = 'ChiNhanh')
        EXEC('CREATE SYNONYM dbo.ChiNhanh FOR SERVER_HN.QLXeKhach_HN.dbo.ChiNhanh');
END;
GO

-- 1. SP: Lấy danh sách chi nhánh (Sprint 0 - Shared Catalog)
CREATE OR ALTER PROCEDURE sp_LayDanhSachChiNhanh
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.MaCN, 
        c.TenCN, 
        c.DiaChi, 
        c.SoDienThoai, 
        c.MaTruongCN,
        ISNULL(nv.HoDem + ' ' + nv.Ten, N'') AS TenTruongCN
    FROM ChiNhanh c
    LEFT JOIN NhanVien nv ON c.MaTruongCN = nv.MaNV
    ORDER BY c.MaCN ASC;
END;
GO

-- 2. SP: Lấy danh sách tham số cấu hình (Sprint 0 & UC-002)
CREATE OR ALTER PROCEDURE sp_LayDanhSachThamSo
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MaThamSo, GiaTri, MoTa 
    FROM ThamSo;
END;
GO

-- 3. SP: Lấy danh sách độ phức tạp tuyến đường (Sprint 0 & UC-002)
CREATE OR ALTER PROCEDURE sp_LayDanhSachDoPhucTap
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CapDo, MoTa, HeSoLuong, HeSoDuongKho 
    FROM DoPhucTap
    ORDER BY CapDo ASC;
END;
GO

-- Tạo bảng LichLoaiNgay nếu là Database Hà Nội và chưa tồn tại
IF (DB_NAME() LIKE '%HN%' AND OBJECT_ID('dbo.LichLoaiNgay', 'U') IS NULL)
BEGIN
    CREATE TABLE dbo.LichLoaiNgay (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        MaLoaiNgay VARCHAR(20) NOT NULL CONSTRAINT FK_LichLoaiNgay_LoaiNgay REFERENCES LoaiNgay(MaLoaiNgay),
        TuNgay DATE NOT NULL,
        DenNgay DATE NOT NULL,
        MoTa NVARCHAR(100) NULL,
        CONSTRAINT CK_LichLoaiNgay_Ngay CHECK (TuNgay <= DenNgay)
    );

    INSERT INTO dbo.LichLoaiNgay (MaLoaiNgay, TuNgay, DenNgay, MoTa) VALUES
    ('LETET', '2025-01-25', '2025-02-02', N'Tết'),
    ('LETET', '2025-04-30', '2025-05-04', NULL),
    ('LETET', '2025-08-30', '2025-09-02', NULL),
    ('MUADL', '2025-06-01', '2025-08-31', NULL);
END;
GO

-- 4. SP: Lấy danh sách lịch loại ngày trực tiếp từ cơ sở dữ liệu
CREATE OR ALTER PROCEDURE sp_LayDanhSachLichNgay
    @Nam INT = NULL,
    @Thang INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        l.Id,
        l.MaLoaiNgay,
        ln.TenLoaiNgay,
        l.TuNgay,
        l.DenNgay,
        l.MoTa
    FROM dbo.LichLoaiNgay l
    JOIN LoaiNgay ln ON l.MaLoaiNgay = ln.MaLoaiNgay
    ORDER BY l.TuNgay ASC;
END;
GO

-- 5. SP: Cập nhật tham số thù lao (UC-002)
CREATE OR ALTER PROCEDURE sp_CapNhatThamSoThuLao
    @DonGiaKm FLOAT,
    @HsLai FLOAT,
    @HsPhu FLOAT,
    @HsLuongCap1 FLOAT,
    @HsLuongCap2 FLOAT,
    @HsLuongCap3 FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    -- Ràng buộc phân quyền phân tán: Chỉ database Hà Nội mới có quyền cập nhật tham số dùng chung
    IF DB_NAME() NOT LIKE '%HN%'
    BEGIN
        THROW 50000, N'Chỉ chi nhánh Hà Nội (Trụ sở chính) mới có quyền cập nhật tham số và cấu hình hệ thống. Chi nhánh hiện tại chỉ có quyền đọc.', 1;
    END;

    IF (@DonGiaKm <= 0 OR @HsLai <= 0 OR @HsPhu <= 0 
        OR @HsLuongCap1 <= 0 OR @HsLuongCap2 <= 0 OR @HsLuongCap3 <= 0)
    BEGIN
        THROW 50000, N'Giá trị phải lớn hơn 0.', 1;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE ThamSo SET GiaTri = @DonGiaKm WHERE MaThamSo = 'DON_GIA_KM';
        UPDATE ThamSo SET GiaTri = @HsLai WHERE MaThamSo = 'HS_LAI';
        UPDATE ThamSo SET GiaTri = @HsPhu WHERE MaThamSo = 'HS_PHU';

        UPDATE DoPhucTap SET HeSoLuong = @HsLuongCap1 WHERE CapDo = 1;
        UPDATE DoPhucTap SET HeSoLuong = @HsLuongCap2 WHERE CapDo = 2;
        UPDATE DoPhucTap SET HeSoLuong = @HsLuongCap3 WHERE CapDo = 3;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 6. SP: Cập nhật tham số bảo dưỡng và đăng kiểm (UC-002)
CREATE OR ALTER PROCEDURE sp_CapNhatThamSoBaoDuongDangKiem
    @ChuKyBd FLOAT,
    @KmMoiNgayBd FLOAT,
    @CanhBaoNgay FLOAT,
    @ChuKyDkCu FLOAT,
    @ChuKyDkMoi FLOAT,
    @TuoiXeCu FLOAT,
    @HsDuongKhoCap1 FLOAT,
    @HsDuongKhoCap2 FLOAT,
    @HsDuongKhoCap3 FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    -- Ràng buộc phân quyền phân tán: Chỉ database Hà Nội mới có quyền cập nhật tham số dùng chung
    IF DB_NAME() NOT LIKE '%HN%'
    BEGIN
        THROW 50000, N'Chỉ chi nhánh Hà Nội (Trụ sở chính) mới có quyền cập nhật tham số và cấu hình hệ thống. Chi nhánh hiện tại chỉ có quyền đọc.', 1;
    END;

    IF (@ChuKyBd <= 0 OR @KmMoiNgayBd <= 0 OR @CanhBaoNgay <= 0 
        OR @ChuKyDkCu <= 0 OR @ChuKyDkMoi <= 0 OR @TuoiXeCu <= 0)
    BEGIN
        THROW 50000, N'Giá trị phải lớn hơn 0.', 1;
    END;

    IF (@HsDuongKhoCap1 < 1 OR @HsDuongKhoCap2 < 1 OR @HsDuongKhoCap3 < 1)
    BEGIN
        THROW 50000, N'Hệ số đường khó phải từ 1 trở lên.', 1;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE ThamSo SET GiaTri = @ChuKyBd WHERE MaThamSo = 'CHU_KY_BD';
        UPDATE ThamSo SET GiaTri = @KmMoiNgayBd WHERE MaThamSo = 'KM_MOI_NGAY_BD';
        UPDATE ThamSo SET GiaTri = @CanhBaoNgay WHERE MaThamSo = 'CANH_BAO_NGAY';
        UPDATE ThamSo SET GiaTri = @ChuKyDkCu WHERE MaThamSo = 'CHU_KY_DK_CU';
        UPDATE ThamSo SET GiaTri = @ChuKyDkMoi WHERE MaThamSo = 'CHU_KY_DK_MOI';
        UPDATE ThamSo SET GiaTri = @TuoiXeCu WHERE MaThamSo = 'TUOI_XE_CU';

        UPDATE DoPhucTap SET HeSoDuongKho = @HsDuongKhoCap1 WHERE CapDo = 1;
        UPDATE DoPhucTap SET HeSoDuongKho = @HsDuongKhoCap2 WHERE CapDo = 2;
        UPDATE DoPhucTap SET HeSoDuongKho = @HsDuongKhoCap3 WHERE CapDo = 3;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 7. SP: Thêm tuyến kèm 4 mức giá vé (UC-003)
CREATE OR ALTER PROCEDURE sp_ThemTuyenVaGia
    @DiemDau NVARCHAR(50),
    @DiemCuoi NVARCHAR(50),
    @DoDaiKm FLOAT,
    @CapDo INT,
    @GiaThuong FLOAT,
    @GiaCuoiTuan FLOAT,
    @GiaMuaDL FLOAT,
    @GiaLeTet FLOAT,
    @MaTuyen VARCHAR(10) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Ràng buộc phân quyền phân tán: Chỉ database Hà Nội mới có quyền thêm tuyến đường và giá vé
    IF DB_NAME() NOT LIKE '%HN%'
    BEGIN
        THROW 50000, N'Chỉ chi nhánh Hà Nội (Trụ sở chính) mới có quyền thêm tuyến đường và giá vé. Chi nhánh hiện tại chỉ có quyền đọc.', 1;
    END;

    -- Validate điểm đầu và cuối
    IF (LOWER(LTRIM(RTRIM(@DiemDau))) = LOWER(LTRIM(RTRIM(@DiemCuoi))))
    BEGIN
        THROW 50000, N'Điểm đầu và điểm cuối phải khác nhau.', 1;
    END;

    -- Validate độ dài
    IF (@DoDaiKm <= 0)
    BEGIN
        THROW 50000, N'Độ dài tuyến phải lớn hơn 0 km.', 1;
    END;

    -- Validate 4 mức giá: thiếu hoặc <= 0 ném lỗi E06 (57001)
    IF (@GiaThuong IS NULL OR @GiaThuong <= 0 
        OR @GiaCuoiTuan IS NULL OR @GiaCuoiTuan <= 0 
        OR @GiaMuaDL IS NULL OR @GiaMuaDL <= 0 
        OR @GiaLeTet IS NULL OR @GiaLeTet <= 0)
    BEGIN
        THROW 57001, N'Nhập đủ 4 mức giá lớn hơn 0. Tuyến chưa được lưu.', 1;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Tự sinh mã tuyến: T + 2 chữ số (ví dụ T01, T02...)
        DECLARE @MaxNum INT = 0;
        SELECT @MaxNum = ISNULL(MAX(TRY_CAST(SUBSTRING(MaTuyen, 2, LEN(MaTuyen)) AS INT)), 0)
        FROM TuyenDuong
        WHERE MaTuyen LIKE 'T%';

        SET @MaTuyen = 'T' + RIGHT('0' + CAST(@MaxNum + 1 AS VARCHAR(10)), 2);

        INSERT INTO TuyenDuong (MaTuyen, DiemDau, DiemCuoi, DoDaiKm, CapDo)
        VALUES (@MaTuyen, @DiemDau, @DiemCuoi, @DoDaiKm, @CapDo);

        INSERT INTO BangGiaVe (MaTuyen, MaLoaiNgay, GiaVe) VALUES
        (@MaTuyen, 'THUONG', @GiaThuong),
        (@MaTuyen, 'CUOITUAN', @GiaCuoiTuan),
        (@MaTuyen, 'MUADL', @GiaMuaDL),
        (@MaTuyen, 'LETET', @GiaLeTet);

        COMMIT TRANSACTION;

        SELECT @MaTuyen AS MaTuyen;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 8. SP: Cập nhật hoặc thêm giá vé (UC-004)
CREATE OR ALTER PROCEDURE sp_UpsertBangGiaVe
    @MaTuyen VARCHAR(10),
    @MaLoaiNgay VARCHAR(20),
    @GiaVe FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    -- Ràng buộc phân quyền phân tán: Chỉ database Hà Nội mới có quyền cập nhật bảng giá vé
    IF DB_NAME() NOT LIKE '%HN%'
    BEGIN
        THROW 50000, N'Chỉ chi nhánh Hà Nội (Trụ sở chính) mới có quyền cập nhật bảng giá vé. Chi nhánh hiện tại chỉ có quyền đọc.', 1;
    END;

    IF (@GiaVe <= 0)
    BEGIN
        THROW 50000, N'Giá trị phải lớn hơn 0.', 1;
    END;

    IF EXISTS (SELECT 1 FROM BangGiaVe WHERE MaTuyen = @MaTuyen AND MaLoaiNgay = @MaLoaiNgay)
    BEGIN
        UPDATE BangGiaVe SET GiaVe = @GiaVe WHERE MaTuyen = @MaTuyen AND MaLoaiNgay = @MaLoaiNgay;
    END
    ELSE
    BEGIN
        INSERT INTO BangGiaVe (MaTuyen, MaLoaiNgay, GiaVe) VALUES (@MaTuyen, @MaLoaiNgay, @GiaVe);
    END;
END;
GO

-- 9. SP: Lấy danh sách tuyến đường kèm giá vé (UC-003, UC-004 & Danh mục)
CREATE OR ALTER PROCEDURE sp_LayDanhSachTuyenVaGia
    @MaTuyen VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.MaTuyen, 
        t.DiemDau, 
        t.DiemCuoi, 
        t.DoDaiKm, 
        t.CapDo, 
        d.MoTa AS TenCapDo,
        d.HeSoLuong,
        d.HeSoDuongKho,
        MAX(CASE WHEN g.MaLoaiNgay = 'THUONG' THEN g.GiaVe END) AS GiaThuong,
        MAX(CASE WHEN g.MaLoaiNgay = 'CUOITUAN' THEN g.GiaVe END) AS GiaCuoiTuan,
        MAX(CASE WHEN g.MaLoaiNgay = 'MUADL' THEN g.GiaVe END) AS GiaMuaDL,
        MAX(CASE WHEN g.MaLoaiNgay = 'LETET' THEN g.GiaVe END) AS GiaLeTet
    FROM TuyenDuong t
    JOIN DoPhucTap d ON t.CapDo = d.CapDo
    LEFT JOIN BangGiaVe g ON t.MaTuyen = g.MaTuyen
    WHERE (@MaTuyen IS NULL OR t.MaTuyen = @MaTuyen)
    GROUP BY t.MaTuyen, t.DiemDau, t.DiemCuoi, t.DoDaiKm, t.CapDo, d.MoTa, d.HeSoLuong, d.HeSoDuongKho
    ORDER BY t.MaTuyen ASC;
END;
GO

-- 10. SP: Thêm tài xế (UC-007)
CREATE OR ALTER PROCEDURE sp_ThemTaiXe
    @HoDem NVARCHAR(50),
    @Ten NVARCHAR(20),
    @NgaySinh DATE,
    @CCCD VARCHAR(12),
    @SoGPLX VARCHAR(20),
    @HangGPLX VARCHAR(5),
    @SoNha NVARCHAR(100) = NULL,
    @Phuong NVARCHAR(50) = NULL,
    @Tinh NVARCHAR(50) = NULL,
    @SoDienThoai VARCHAR(15) = NULL,
    @MaCN VARCHAR(10) = NULL,
    @NgayVaoLam DATE = NULL,
    @MaTX VARCHAR(10) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Xác định chi nhánh cục bộ của CSDL đang chạy
    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    IF (@MaCN IS NULL OR LTRIM(RTRIM(@MaCN)) = '')
        SET @MaCN = @LocalBranch;

    -- Ràng buộc phân mảnh ngang: chỉ được thêm tài xế thuộc chi nhánh của chính mình
    IF (@MaCN <> @LocalBranch)
    BEGIN
        THROW 50000, N'Không thể thêm tài xế cho chi nhánh khác. Chi nhánh hiện tại chỉ có thể thêm tài xế của chính mình.', 1;
    END;

    -- Validate định dạng CCCD đúng 12 chữ số
    IF (LEN(LTRIM(RTRIM(@CCCD))) <> 12)
    BEGIN
        THROW 50000, N'CCCD phải gồm đúng 12 chữ số.', 1;
    END;

    IF (@NgayVaoLam IS NULL)
        SET @NgayVaoLam = CAST(GETDATE() AS DATE);

    -- Validate tuổi tài xế >= 21
    IF (DATEDIFF(YEAR, @NgaySinh, GETDATE()) < 21)
    BEGIN
        THROW 50000, N'Tài xế phải từ 21 tuổi trở lên.', 1;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Tự sinh mã tài xế phân biệt theo chi nhánh
        DECLARE @MaxNum INT = 0;
        IF (@LocalBranch = 'CN02')
        BEGIN
            SELECT @MaxNum = ISNULL(MAX(TRY_CAST(SUBSTRING(MaTX, 6, LEN(MaTX)) AS INT)), 0)
            FROM TaiXe
            WHERE MaTX LIKE 'TX_DN%';
            SET @MaTX = 'TX_DN' + RIGHT('00' + CAST(@MaxNum + 1 AS VARCHAR(10)), 2);
        END
        ELSE IF (@LocalBranch = 'CN03')
        BEGIN
            SELECT @MaxNum = ISNULL(MAX(TRY_CAST(SUBSTRING(MaTX, 7, LEN(MaTX)) AS INT)), 0)
            FROM TaiXe
            WHERE MaTX LIKE 'TX_HCM%';
            SET @MaTX = 'TX_HCM' + RIGHT('00' + CAST(@MaxNum + 1 AS VARCHAR(10)), 2);
        END
        ELSE
        BEGIN
            SELECT @MaxNum = ISNULL(MAX(TRY_CAST(SUBSTRING(MaTX, 3, LEN(MaTX)) AS INT)), 0)
            FROM TaiXe
            WHERE MaTX LIKE 'TX[0-9]%';
            SET @MaTX = 'TX' + RIGHT('0000' + CAST(@MaxNum + 1 AS VARCHAR(10)), 4);
        END;

        INSERT INTO TaiXe (
            MaTX, HoDem, Ten, NgaySinh, CCCD, SoGPLX, HangGPLX,
            SoNha, Phuong, Tinh, NgayVaoLam, TrangThai, MaCN
        ) VALUES (
            @MaTX, @HoDem, @Ten, @NgaySinh, @CCCD, @SoGPLX, @HangGPLX,
            @SoNha, @Phuong, @Tinh, @NgayVaoLam, 'DangLam', @MaCN
        );

        IF (@SoDienThoai IS NOT NULL AND LTRIM(RTRIM(@SoDienThoai)) <> '')
        BEGIN
            INSERT INTO TaiXe_SDT (MaTX, SoDienThoai)
            VALUES (@MaTX, LTRIM(RTRIM(@SoDienThoai)));
        END;

        COMMIT TRANSACTION;

        SELECT @MaTX AS MaTX;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 11. SP: Lấy danh sách tài xế (UC-007 & Phân tán liên chi nhánh)
CREATE OR ALTER PROCEDURE sp_LayDanhSachTaiXe
    @MaCN VARCHAR(10) = NULL,
    @TrangThai VARCHAR(20) = NULL,
    @Thang VARCHAR(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF (@Thang IS NULL)
        SET @Thang = FORMAT(GETDATE(), 'yyyy-MM');

    -- Xác định chi nhánh cục bộ của CSDL đang chạy
    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    -- Chuẩn hóa mã chi nhánh: Nếu không chỉ định hoặc là ALL, mặc định lấy chi nhánh hiện tại
    IF (@MaCN IS NOT NULL)
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

    -- 1. Nếu cần lấy Hà Nội (CN01) nhưng đây không phải DB Hà Nội
    IF (@MaCN = 'CN01' AND @LocalBranch <> 'CN01')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HN.QLXeKhach_HN.dbo.sp_LayDanhSachTaiXe @MaCN = @pMaCN, @TrangThai = @pTrangThai, @Thang = @pThang',
            N'@pMaCN VARCHAR(10), @pTrangThai VARCHAR(20), @pThang VARCHAR(7)',
            @pMaCN = 'CN01', @pTrangThai = @TrangThai, @pThang = @Thang;
        RETURN;
    END;

    -- 2. Nếu cần lấy Đà Nẵng (CN02) nhưng đây không phải DB Đà Nẵng
    IF (@MaCN = 'CN02' AND @LocalBranch <> 'CN02')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_LayDanhSachTaiXe @MaCN = @pMaCN, @TrangThai = @pTrangThai, @Thang = @pThang',
            N'@pMaCN VARCHAR(10), @pTrangThai VARCHAR(20), @pThang VARCHAR(7)',
            @pMaCN = 'CN02', @pTrangThai = @TrangThai, @pThang = @Thang;
        RETURN;
    END;

    -- 3. Nếu cần lấy TP.HCM (CN03) nhưng đây không phải DB TP.HCM
    IF (@MaCN = 'CN03' AND @LocalBranch <> 'CN03')
    BEGIN
        EXEC sp_executesql 
            N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_LayDanhSachTaiXe @MaCN = @pMaCN, @TrangThai = @pTrangThai, @Thang = @pThang',
            N'@pMaCN VARCHAR(10), @pTrangThai VARCHAR(20), @pThang VARCHAR(7)',
            @pMaCN = 'CN03', @pTrangThai = @TrangThai, @pThang = @Thang;
        RETURN;
    END;

    -- 4. Truy vấn dữ liệu cục bộ của chi nhánh hiện tại
    SELECT 
        tx.MaTX, 
        tx.HoDem, 
        tx.Ten, 
        (tx.HoDem + ' ' + tx.Ten) AS HoTen,
        tx.NgaySinh,
        YEAR(tx.NgaySinh) AS NamSinh,
        tx.CCCD, 
        tx.SoGPLX, 
        tx.HangGPLX, 
        tx.SoNha, 
        tx.Phuong, 
        tx.Tinh, 
        tx.NgayVaoLam, 
        tx.TrangThai, 
        tx.MaCN,
        cn.TenCN,
        (SELECT TOP 1 SoDienThoai FROM TaiXe_SDT WHERE MaTX = tx.MaTX) AS SoDienThoai,
        ISNULL(chuyen.SoChuyen, 0) AS SoChuyen,
        ISNULL(chuyen.ThuLaoThang, 0) AS ThuLaoThang
    FROM TaiXe tx
    JOIN ChiNhanh cn ON tx.MaCN = cn.MaCN
    LEFT JOIN (
        SELECT pc.MaTX,
               COUNT(cx.MaChuyen) AS SoChuyen,
               SUM(pc.ThuLao) AS ThuLaoThang
        FROM PhanCong pc
        JOIN ChuyenXe cx ON pc.MaChuyen = cx.MaChuyen
        WHERE cx.TrangThai = 'HoanThanh'
          AND FORMAT(cx.GioKhoiHanhDK, 'yyyy-MM') = @Thang
        GROUP BY pc.MaTX
    ) chuyen ON tx.MaTX = chuyen.MaTX
    WHERE tx.MaCN = @LocalBranch
      AND (@TrangThai IS NULL OR tx.TrangThai = @TrangThai)
    ORDER BY tx.MaTX ASC;
END;
GO

-- 11.1. SP: Lấy chi tiết một tài xế (Phân tán liên chi nhánh)
CREATE OR ALTER PROCEDURE sp_LayChiTietTaiXe
    @MaTX VARCHAR(10),
    @Thang VARCHAR(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF (@Thang IS NULL)
        SET @Thang = FORMAT(GETDATE(), 'yyyy-MM');

    -- 1. Tìm ở bảng cục bộ trước
    IF EXISTS (SELECT 1 FROM TaiXe WHERE MaTX = @MaTX)
    BEGIN
        SELECT 
            tx.MaTX, 
            tx.HoDem, 
            tx.Ten, 
            (tx.HoDem + ' ' + tx.Ten) AS HoTen,
            tx.NgaySinh,
            YEAR(tx.NgaySinh) AS NamSinh,
            tx.CCCD, 
            tx.SoGPLX, 
            tx.HangGPLX, 
            tx.SoNha, 
            tx.Phuong, 
            tx.Tinh, 
            tx.NgayVaoLam, 
            tx.TrangThai, 
            tx.MaCN,
            cn.TenCN,
            (SELECT TOP 1 SoDienThoai FROM TaiXe_SDT WHERE MaTX = tx.MaTX) AS SoDienThoai,
            ISNULL(chuyen.SoChuyen, 0) AS SoChuyen,
            ISNULL(chuyen.ThuLaoThang, 0) AS ThuLaoThang
        FROM TaiXe tx
        JOIN ChiNhanh cn ON tx.MaCN = cn.MaCN
        LEFT JOIN (
            SELECT pc.MaTX,
                   COUNT(cx.MaChuyen) AS SoChuyen,
                   SUM(pc.ThuLao) AS ThuLaoThang
            FROM PhanCong pc
            JOIN ChuyenXe cx ON pc.MaChuyen = cx.MaChuyen
            WHERE cx.TrangThai = 'HoanThanh'
              AND FORMAT(cx.GioKhoiHanhDK, 'yyyy-MM') = @Thang
            GROUP BY pc.MaTX
        ) chuyen ON tx.MaTX = chuyen.MaTX
        WHERE tx.MaTX = @MaTX;
        RETURN;
    END;

    -- Xác định chi nhánh cục bộ
    DECLARE @LocalBranch VARCHAR(10);
    IF DB_NAME() LIKE '%DN%' SET @LocalBranch = 'CN02';
    ELSE IF DB_NAME() LIKE '%HCM%' SET @LocalBranch = 'CN03';
    ELSE SET @LocalBranch = 'CN01';

    -- 2. Nếu không có ở cục bộ, kiểm tra ở các site khác qua Linked Server
    IF (@LocalBranch <> 'CN01')
    BEGIN
        DECLARE @FoundHN INT = 0;
        EXEC sp_executesql 
            N'IF EXISTS (SELECT 1 FROM SERVER_HN.QLXeKhach_HN.dbo.TaiXe WHERE MaTX = @pMaTX) SET @pFound = 1;',
            N'@pMaTX VARCHAR(10), @pFound INT OUTPUT',
            @pMaTX = @MaTX, @pFound = @FoundHN OUTPUT;
        IF (@FoundHN = 1)
        BEGIN
            EXEC sp_executesql 
                N'EXEC SERVER_HN.QLXeKhach_HN.dbo.sp_LayChiTietTaiXe @MaTX = @pMaTX, @Thang = @pThang;',
                N'@pMaTX VARCHAR(10), @pThang VARCHAR(7)',
                @pMaTX = @MaTX, @pThang = @Thang;
            RETURN;
        END;
    END;

    IF (@LocalBranch <> 'CN02')
    BEGIN
        DECLARE @FoundDN INT = 0;
        EXEC sp_executesql 
            N'IF EXISTS (SELECT 1 FROM SERVER_DN.QLXeKhach_DN.dbo.TaiXe WHERE MaTX = @pMaTX) SET @pFound = 1;',
            N'@pMaTX VARCHAR(10), @pFound INT OUTPUT',
            @pMaTX = @MaTX, @pFound = @FoundDN OUTPUT;
        IF (@FoundDN = 1)
        BEGIN
            EXEC sp_executesql 
                N'EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_LayChiTietTaiXe @MaTX = @pMaTX, @Thang = @pThang;',
                N'@pMaTX VARCHAR(10), @pThang VARCHAR(7)',
                @pMaTX = @MaTX, @pThang = @Thang;
            RETURN;
        END;
    END;

    IF (@LocalBranch <> 'CN03')
    BEGIN
        DECLARE @FoundHCM INT = 0;
        EXEC sp_executesql 
            N'IF EXISTS (SELECT 1 FROM SERVER_HCM.QLXeKhach_HCM.dbo.TaiXe WHERE MaTX = @pMaTX) SET @pFound = 1;',
            N'@pMaTX VARCHAR(10), @pFound INT OUTPUT',
            @pMaTX = @MaTX, @pFound = @FoundHCM OUTPUT;
        IF (@FoundHCM = 1)
        BEGIN
            EXEC sp_executesql 
                N'EXEC SERVER_HCM.QLXeKhach_HCM.dbo.sp_LayChiTietTaiXe @MaTX = @pMaTX, @Thang = @pThang;',
                N'@pMaTX VARCHAR(10), @pThang VARCHAR(7)',
                @pMaTX = @MaTX, @pThang = @Thang;
            RETURN;
        END;
    END;
END;
GO

-- 12. SP: Cập nhật tuyến đường (Bổ sung)
CREATE OR ALTER PROCEDURE sp_CapNhatTuyenDuong
    @MaTuyen VARCHAR(10),
    @DiemDau NVARCHAR(50),
    @DiemCuoi NVARCHAR(50),
    @DoDaiKm FLOAT,
    @CapDo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Ràng buộc phân quyền phân tán: Chỉ database Hà Nội mới có quyền cập nhật tuyến đường
    IF DB_NAME() NOT LIKE '%HN%'
    BEGIN
        THROW 50000, N'Chỉ chi nhánh Hà Nội (Trụ sở chính) mới có quyền cập nhật tuyến đường. Chi nhánh hiện tại chỉ có quyền đọc.', 1;
    END;

    IF (LOWER(LTRIM(RTRIM(@DiemDau))) = LOWER(LTRIM(RTRIM(@DiemCuoi))))
    BEGIN
        THROW 50000, N'Điểm đầu và điểm cuối phải khác nhau.', 1;
    END;

    IF (@DoDaiKm <= 0)
    BEGIN
        THROW 50000, N'Độ dài tuyến phải lớn hơn 0 km.', 1;
    END;

    UPDATE TuyenDuong
    SET DiemDau = @DiemDau,
        DiemCuoi = @DiemCuoi,
        DoDaiKm = @DoDaiKm,
        CapDo = @CapDo
    WHERE MaTuyen = @MaTuyen;
END;
GO

-- 13. SP: Xóa tuyến đường (Bổ sung)
CREATE OR ALTER PROCEDURE sp_XoaTuyenDuong
    @MaTuyen VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Ràng buộc phân quyền phân tán: Chỉ database Hà Nội mới có quyền xóa tuyến đường
    IF DB_NAME() NOT LIKE '%HN%'
    BEGIN
        THROW 50000, N'Chỉ chi nhánh Hà Nội (Trụ sở chính) mới có quyền xóa tuyến đường. Chi nhánh hiện tại chỉ có quyền đọc.', 1;
    END;

    IF EXISTS (SELECT 1 FROM ChuyenXe WHERE MaTuyen = @MaTuyen)
    BEGIN
        THROW 50000, N'Không thể xóa tuyến đã có chuyến xe.', 1;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM BangGiaVe WHERE MaTuyen = @MaTuyen;
        DELETE FROM TuyenDuong WHERE MaTuyen = @MaTuyen;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 14. SP: Cập nhật tài xế (Bổ sung)
CREATE OR ALTER PROCEDURE sp_CapNhatTaiXe
    @MaTX VARCHAR(10),
    @HoDem NVARCHAR(50),
    @Ten NVARCHAR(20),
    @NgaySinh DATE,
    @SoGPLX VARCHAR(20),
    @HangGPLX VARCHAR(5),
    @SoNha NVARCHAR(100) = NULL,
    @Phuong NVARCHAR(50) = NULL,
    @Tinh NVARCHAR(50) = NULL,
    @SoDienThoai VARCHAR(15) = NULL,
    @TrangThai VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tài xế có thuộc chi nhánh hiện tại không
    IF NOT EXISTS (SELECT 1 FROM TaiXe WHERE MaTX = @MaTX)
    BEGIN
        THROW 50000, N'Tài xế không thuộc chi nhánh này hoặc không tồn tại. Bạn chỉ có quyền xem, không được chỉnh sửa.', 1;
    END;

    IF (DATEDIFF(YEAR, @NgaySinh, GETDATE()) < 21)
    BEGIN
        THROW 50000, N'Tài xế phải từ 21 tuổi trở lên.', 1;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE TaiXe
        SET HoDem = @HoDem,
            Ten = @Ten,
            NgaySinh = @NgaySinh,
            SoGPLX = @SoGPLX,
            HangGPLX = @HangGPLX,
            SoNha = @SoNha,
            Phuong = @Phuong,
            Tinh = @Tinh,
            TrangThai = ISNULL(@TrangThai, TrangThai)
        WHERE MaTX = @MaTX;

        IF (@SoDienThoai IS NOT NULL)
        BEGIN
            DELETE FROM TaiXe_SDT WHERE MaTX = @MaTX;
            IF (LTRIM(RTRIM(@SoDienThoai)) <> '')
            BEGIN
                INSERT INTO TaiXe_SDT (MaTX, SoDienThoai)
                VALUES (@MaTX, LTRIM(RTRIM(@SoDienThoai)));
            END;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 15. SP: Đổi trạng thái tài xế (Bổ sung)
CREATE OR ALTER PROCEDURE sp_DoiTrangThaiTaiXe
    @MaTX VARCHAR(10),
    @TrangThai VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@TrangThai NOT IN ('DangLam', 'NghiViec'))
    BEGIN
        THROW 50000, N'Trạng thái tài xế không hợp lệ.', 1;
    END;

    -- Kiểm tra tài xế có thuộc chi nhánh hiện tại không
    IF NOT EXISTS (SELECT 1 FROM TaiXe WHERE MaTX = @MaTX)
    BEGIN
        THROW 50000, N'Tài xế không thuộc chi nhánh này hoặc không tồn tại. Bạn chỉ có quyền xem, không được chỉnh sửa.', 1;
    END;

    UPDATE TaiXe SET TrangThai = @TrangThai WHERE MaTX = @MaTX;
END;
GO

-- 16. SP: Kiểm tra mức độ sẵn sàng (MH01.0 - UC-001)
CREATE OR ALTER PROCEDURE sp_KiemTraMucDoSanSang
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DonGiaKm FLOAT, @ChuKyBd FLOAT, @ChuKyDkCu FLOAT, @ChuKyDkMoi FLOAT;
    SELECT @DonGiaKm = GiaTri FROM ThamSo WHERE MaThamSo = 'DON_GIA_KM';
    SELECT @ChuKyBd = GiaTri FROM ThamSo WHERE MaThamSo = 'CHU_KY_BD';
    SELECT @ChuKyDkCu = GiaTri FROM ThamSo WHERE MaThamSo = 'CHU_KY_DK_CU';
    SELECT @ChuKyDkMoi = GiaTri FROM ThamSo WHERE MaThamSo = 'CHU_KY_DK_MOI';

    DECLARE @SoTuyenThieuGia INT = 0;
    SELECT @SoTuyenThieuGia = COUNT(*)
    FROM (
        SELECT MaTuyen 
        FROM BangGiaVe 
        GROUP BY MaTuyen 
        HAVING COUNT(DISTINCT MaLoaiNgay) < 4
    ) t;

    SET @SoTuyenThieuGia = @SoTuyenThieuGia + (
        SELECT COUNT(*) 
        FROM TuyenDuong 
        WHERE MaTuyen NOT IN (SELECT DISTINCT MaTuyen FROM BangGiaVe)
    );

    DECLARE @SoTaiXeDangLam INT = 0;
    SELECT @SoTaiXeDangLam = COUNT(*) FROM TaiXe WHERE TrangThai = 'DangLam';

    DECLARE @TongSoTuyen INT = 0;
    SELECT @TongSoTuyen = COUNT(*) FROM TuyenDuong;

    SELECT 
        ISNULL(@DonGiaKm, 0) AS DonGiaKm,
        ISNULL(@ChuKyBd, 0) AS ChuKyBd,
        ISNULL(@ChuKyDkCu, 0) AS ChuKyDkCu,
        ISNULL(@ChuKyDkMoi, 0) AS ChuKyDkMoi,
        @TongSoTuyen AS TongSoTuyen,
        @SoTuyenThieuGia AS SoTuyenThieuGia,
        @SoTaiXeDangLam AS SoTaiXeDangLam;
END;
GO

