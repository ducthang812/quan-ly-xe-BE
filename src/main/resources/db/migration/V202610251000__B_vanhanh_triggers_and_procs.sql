-- =============================================================================
-- Module B - van hanh chuyen xe va ban ve (Pha 1)
-- SQL Server / Flyway.  Moi CREATE OR ALTER nam trong batch rieng.
-- =============================================================================

CREATE OR ALTER FUNCTION dbo.fn_LoaiNgay(@Ngay DATE)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @MaLoaiNgay VARCHAR(10);

    -- Gom ca lich ngay va lich khoang roi xep hang chung de bao dam
    -- LETET > MUADL > CUOITUAN > THUONG khi hai nguon chong nhau.
    SELECT TOP (1) @MaLoaiNgay = lich.MaLoaiNgay
    FROM (
        SELECT ln.MaLoaiNgay, ln.Ngay AS MocSapXep
        FROM dbo.LichNgay ln
        WHERE ln.Ngay = @Ngay
        UNION ALL
        SELECT l.MaLoaiNgay, l.TuNgay
        FROM dbo.LichLoaiNgay l
        WHERE @Ngay BETWEEN l.TuNgay AND l.DenNgay
    ) lich
    ORDER BY CASE lich.MaLoaiNgay
                 WHEN 'LETET' THEN 1 WHEN 'MUADL' THEN 2
                 WHEN 'CUOITUAN' THEN 3 WHEN 'THUONG' THEN 4 ELSE 5
             END,
             lich.MocSapXep DESC;

    IF @MaLoaiNgay IS NULL
        SET @MaLoaiNgay = CASE
            -- 1900-01-01 la thu Hai; khong phu thuoc SET DATEFIRST/LANGUAGE.
            WHEN ((DATEDIFF(DAY, CONVERT(DATE, '19000101', 112), @Ngay) % 7) + 7) % 7 IN (5, 6)
                THEN 'CUOITUAN'
            ELSE 'THUONG'
        END;

    RETURN @MaLoaiNgay;
END;
GO

-- Stub cua module C. Dynamic SQL de CREATE PROCEDURE co the nam trong IF.
IF OBJECT_ID(N'dbo.sp_KiemTraXeDuDieuKien', N'P') IS NULL
BEGIN
    EXEC(N'CREATE PROCEDURE dbo.sp_KiemTraXeDuDieuKien
        @MaXe CHAR(5),
        @NgayKhoiHanh DATE
    AS
    BEGIN
        SET NOCOUNT ON;
        RETURN 0;
    END;');
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Ve_KiemTraSoCho
ON dbo.Ve
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.ChuyenXe c ON c.MaChuyen = i.MaChuyen
        JOIN dbo.Xe x ON x.MaXe = c.MaXe
        JOIN dbo.LoaiXe lx ON lx.MaLoaiXe = x.MaLoaiXe
        WHERE i.TrangThai = 'DaBan' AND (i.SoGhe <= 2 OR i.SoGhe > lx.SoGhe)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50101, N'50101', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN deleted d ON d.MaVe = i.MaVe
        JOIN dbo.ChuyenXe c ON c.MaChuyen = i.MaChuyen
        WHERE i.TrangThai = 'DaBan'
          AND c.TrangThai <> 'KeHoach'
          AND (d.MaVe IS NULL OR d.TrangThai <> 'DaBan' OR d.MaChuyen <> i.MaChuyen)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50102, N'50102', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT MaChuyen FROM inserted) a
        JOIN dbo.ChuyenXe c ON c.MaChuyen = a.MaChuyen
        JOIN dbo.Xe x ON x.MaXe = c.MaXe
        JOIN dbo.LoaiXe lx ON lx.MaLoaiXe = x.MaLoaiXe
        CROSS APPLY (
            SELECT COUNT_BIG(*) AS SoVe
            FROM dbo.Ve v
            WHERE v.MaChuyen = a.MaChuyen AND v.TrangThai = 'DaBan'
        ) q
        WHERE q.SoVe > lx.SoGhe - 2
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50103, N'50103', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Ve_SinhMaVaGia
ON dbo.Ve
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @VeMoi TABLE (MaVe VARCHAR(30) NOT NULL PRIMARY KEY);

    ;WITH XepHang AS (
        SELECT i.MaVe AS MaVeTam, i.MaChuyen, i.SoGhe, i.GiaVe,
               ROW_NUMBER() OVER (PARTITION BY i.MaChuyen, i.SoGhe ORDER BY i.MaVe) AS SttLo
        FROM inserted i
        WHERE i.MaVe LIKE 'TMP%'
    ), DaCo AS (
        SELECT x.MaVeTam, x.MaChuyen, x.SoGhe, x.GiaVe, x.SttLo,
               (SELECT COUNT(*) FROM dbo.Ve v2
                WHERE v2.MaChuyen = x.MaChuyen AND v2.SoGhe = x.SoGhe
                  AND NOT EXISTS (SELECT 1 FROM inserted ii WHERE ii.MaVe = v2.MaVe)) AS SoLanCu
        FROM XepHang x
    )
    UPDATE v
       SET v.LanBan = d.SoLanCu + d.SttLo,
           v.MaVe = RTRIM(c.MaTuyen) + '-' + RTRIM(c.MaXe) + '-' + RTRIM(c.MaChuyen) + '-'
                 + RIGHT('0' + CONVERT(VARCHAR(2), d.SoGhe), 2) + '-'
                 + CONVERT(VARCHAR(3), d.SoLanCu + d.SttLo),
           v.GiaVe = COALESCE(d.GiaVe, bg.GiaVe)
    OUTPUT inserted.MaVe INTO @VeMoi(MaVe)
    FROM dbo.Ve v
    JOIN DaCo d ON d.MaVeTam = v.MaVe
    JOIN dbo.ChuyenXe c ON c.MaChuyen = d.MaChuyen
    LEFT JOIN dbo.BangGiaVe bg
      ON bg.MaTuyen = c.MaTuyen
     AND bg.MaLoaiNgay = dbo.fn_LoaiNgay(CAST(c.GioKhoiHanhDK AS DATE));

    IF EXISTS (SELECT 1 FROM dbo.Ve v JOIN @VeMoi m ON m.MaVe = v.MaVe WHERE v.GiaVe IS NULL)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50201, N'50201', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_PhanCong_TrungGio
ON dbo.PhanCong
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaTXKhongHoatDong CHAR(6);
    SELECT TOP (1) @MaTXKhongHoatDong = i.MaTX
        FROM inserted i
        JOIN dbo.TaiXe tx ON tx.MaTX = i.MaTX
        WHERE tx.TrangThai <> 'DangLam'
        ORDER BY i.MaTX;

    IF @MaTXKhongHoatDong IS NOT NULL
    BEGIN
        DECLARE @ThongDiepKhongHoatDong NVARCHAR(2048) = N'50301|' + RTRIM(@MaTXKhongHoatDong);
        ROLLBACK TRANSACTION;
        THROW 50301, @ThongDiepKhongHoatDong, 1;
    END;

    DECLARE @MaTXTrung CHAR(6);
    SELECT TOP (1) @MaTXTrung = i.MaTX
        FROM inserted i
        JOIN dbo.ChuyenXe c1 ON c1.MaChuyen = i.MaChuyen
        JOIN dbo.PhanCong p2 ON p2.MaTX = i.MaTX AND p2.MaChuyen <> i.MaChuyen
        JOIN dbo.ChuyenXe c2 ON c2.MaChuyen = p2.MaChuyen
        WHERE c1.TrangThai <> 'Huy' AND c2.TrangThai <> 'Huy'
          AND c1.GioKhoiHanhDK < c2.GioDenDK AND c2.GioKhoiHanhDK < c1.GioDenDK
        ORDER BY i.MaTX;

    IF @MaTXTrung IS NOT NULL
    BEGIN
        DECLARE @ThongDiep NVARCHAR(2048) = N'50302|' + RTRIM(@MaTXTrung);
        ROLLBACK TRANSACTION;
        THROW 50302, @ThongDiep, 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_ChuyenXe_KiemTraXe
ON dbo.ChuyenXe
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.Xe x ON x.MaXe = i.MaXe WHERE i.TrangThai = 'KeHoach' AND x.TrangThai <> 'HoatDong')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50401, N'50401', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN dbo.ChuyenXe c ON c.MaXe = i.MaXe AND c.MaChuyen <> i.MaChuyen
        WHERE i.TrangThai <> 'Huy' AND c.TrangThai <> 'Huy'
          AND i.GioKhoiHanhDK < c.GioDenDK AND c.GioKhoiHanhDK < i.GioDenDK
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50402, N'50402', 1;
    END;

    -- Proc C co giao dien mot xe/mot ngay; cursor chi dung cho loi goi bien gioi module.
    DECLARE @MaXe CHAR(5), @Ngay DATE;
    DECLARE xe_can_kiemtra CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT MaXe, CAST(GioKhoiHanhDK AS DATE)
        FROM inserted WHERE TrangThai = 'KeHoach';
    OPEN xe_can_kiemtra;
    FETCH NEXT FROM xe_can_kiemtra INTO @MaXe, @Ngay;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_KiemTraXeDuDieuKien @MaXe = @MaXe, @NgayKhoiHanh = @Ngay;
        FETCH NEXT FROM xe_can_kiemtra INTO @MaXe, @Ngay;
    END;
    CLOSE xe_can_kiemtra;
    DEALLOCATE xe_can_kiemtra;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_PhanCong_TinhThuLao
ON dbo.PhanCong
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DonGia DECIMAL(12,2), @HsLai DECIMAL(12,2), @HsPhu DECIMAL(12,2);
    SELECT @DonGia = GiaTri FROM dbo.ThamSo WHERE MaThamSo = 'DON_GIA_KM';
    SELECT @HsLai = GiaTri FROM dbo.ThamSo WHERE MaThamSo = 'HS_LAI';
    SELECT @HsPhu = GiaTri FROM dbo.ThamSo WHERE MaThamSo = 'HS_PHU';

    UPDATE p
       SET ThuLao = ROUND(td.DoDaiKm * @DonGia * d.HeSoLuong
                    * CASE p.VaiTro WHEN 'LAI' THEN @HsLai ELSE @HsPhu END, 0)
    FROM dbo.PhanCong p
    JOIN inserted i ON i.MaChuyen = p.MaChuyen AND i.MaTX = p.MaTX
    JOIN dbo.ChuyenXe c ON c.MaChuyen = p.MaChuyen
    JOIN dbo.TuyenDuong td ON td.MaTuyen = c.MaTuyen
    JOIN dbo.DoPhucTap d ON d.CapDo = td.CapDo;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_ChuyenXe_HoanThanh
ON dbo.ChuyenXe
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE i.TrangThai = 'HoanThanh'
          AND (i.KmThucTe IS NULL OR i.KmThucTe <= 0 OR i.GioKhoiHanhTT IS NULL OR i.GioDenTT IS NULL
               OR (SELECT COUNT(*) FROM dbo.PhanCong p WHERE p.MaChuyen = i.MaChuyen AND p.VaiTro = 'LAI') <> 1
               OR (SELECT COUNT(*) FROM dbo.PhanCong p WHERE p.MaChuyen = i.MaChuyen AND p.VaiTro = 'PHU') <> 1)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50601, N'50601', 1;
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TaoChuyenVaPhanCong
    @MaTuyen CHAR(3), @MaXe CHAR(5), @GioKhoiHanh DATETIME, @GioDen DATETIME,
    @MaLai CHAR(6), @MaPhu CHAR(6), @MaChuyen CHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        IF @MaLai = @MaPhu THROW 53001, N'53001', 1;
        BEGIN TRANSACTION;
        IF @MaChuyen IS NULL
        BEGIN
            DECLARE @Ngay CHAR(6) = CONVERT(CHAR(6), CAST(@GioKhoiHanh AS DATE), 12), @Stt INT;
            SELECT @Stt = ISNULL(MAX(TRY_CONVERT(INT, RIGHT(MaChuyen, 3))), 0) + 1
            FROM dbo.ChuyenXe WITH (UPDLOCK, HOLDLOCK)
            WHERE MaChuyen LIKE 'C' + @Ngay + '[0-9][0-9][0-9]';
            IF @Stt > 999 THROW 54003, N'54003', 1;
            SET @MaChuyen = 'C' + @Ngay + RIGHT('000' + CONVERT(VARCHAR(3), @Stt), 3);
        END;
        INSERT dbo.ChuyenXe(MaChuyen, MaTuyen, MaXe, GioKhoiHanhDK, GioDenDK)
        VALUES (@MaChuyen, @MaTuyen, @MaXe, @GioKhoiHanh, @GioDen);
        INSERT dbo.PhanCong(MaChuyen, MaTX, VaiTro) VALUES (@MaChuyen, @MaLai, 'LAI'), (@MaChuyen, @MaPhu, 'PHU');
        COMMIT TRANSACTION;
        SELECT @MaChuyen AS MaChuyen;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_KetThucChuyen
    @MaChuyen CHAR(10), @GioKhoiHanhTT DATETIME = NULL, @GioDenTT DATETIME = NULL,
    @KmThucTe INT, @ChiPhiVanHanh DECIMAL(12,0)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.ChuyenXe WITH (UPDLOCK, HOLDLOCK) WHERE MaChuyen = @MaChuyen)
        BEGIN ROLLBACK TRANSACTION; RETURN; END;
        IF NOT EXISTS (SELECT 1 FROM dbo.ChuyenXe WHERE MaChuyen = @MaChuyen AND TrangThai IN ('KeHoach','DangChay'))
            THROW 51002, N'51002', 1;
        UPDATE dbo.ChuyenXe
           SET GioKhoiHanhTT = COALESCE(@GioKhoiHanhTT, GioKhoiHanhDK),
               GioDenTT = COALESCE(@GioDenTT, GioDenDK), KmThucTe = @KmThucTe,
               ChiPhiVanHanh = @ChiPhiVanHanh, TrangThai = 'HoanThanh'
         WHERE MaChuyen = @MaChuyen;
        COMMIT TRANSACTION;
        SELECT @MaChuyen AS MaChuyen;
    END TRY BEGIN CATCH IF XACT_STATE() <> 0 ROLLBACK TRANSACTION; THROW; END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BanVe
    @MaChuyen CHAR(10), @SoGhe INT, @HoTen NVARCHAR(100), @SoDienThoai VARCHAR(15),
    @CCCD CHAR(12) = NULL, @Email VARCHAR(100) = NULL, @MaNVBan CHAR(6)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @TrangThai VARCHAR(10), @MaHK CHAR(8);
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @TrangThai = TrangThai FROM dbo.ChuyenXe WITH (UPDLOCK, HOLDLOCK) WHERE MaChuyen = @MaChuyen;
        IF @TrangThai IS NULL BEGIN ROLLBACK TRANSACTION; RETURN; END;
        IF @TrangThai <> 'KeHoach' THROW 51001, N'51001', 1;
        IF EXISTS (SELECT 1 FROM dbo.Ve WITH (UPDLOCK, HOLDLOCK) WHERE MaChuyen = @MaChuyen AND SoGhe = @SoGhe AND TrangThai = 'DaBan')
            THROW 51003, N'51003', 1;
        SELECT @MaHK = MaHK FROM dbo.HanhKhach WITH (UPDLOCK, HOLDLOCK) WHERE SoDienThoai = @SoDienThoai;
        IF @MaHK IS NULL
        BEGIN
            SELECT @MaHK = 'HK' + RIGHT('000000' + CONVERT(VARCHAR(6), ISNULL(MAX(TRY_CONVERT(INT, SUBSTRING(MaHK,3,6))),0) + 1), 6)
            FROM dbo.HanhKhach WITH (UPDLOCK, HOLDLOCK);
            INSERT dbo.HanhKhach(MaHK, HoTen, SoDienThoai, CCCD, Email) VALUES (@MaHK, @HoTen, @SoDienThoai, @CCCD, @Email);
        END
        ELSE UPDATE dbo.HanhKhach SET HoTen = @HoTen, CCCD = COALESCE(@CCCD, CCCD), Email = COALESCE(@Email, Email) WHERE MaHK = @MaHK;
        INSERT dbo.Ve(MaChuyen, SoGhe, MaHK, MaNVBan) VALUES (@MaChuyen, @SoGhe, @MaHK, @MaNVBan);
        DECLARE @MaVe VARCHAR(30);
        SELECT TOP (1) @MaVe = MaVe FROM dbo.Ve WHERE MaChuyen = @MaChuyen AND SoGhe = @SoGhe AND TrangThai = 'DaBan' ORDER BY LanBan DESC;
        COMMIT TRANSACTION;
        SELECT MaVe, GiaVe, LanBan FROM dbo.Ve WHERE MaVe = @MaVe;
    END TRY BEGIN CATCH IF XACT_STATE() <> 0 ROLLBACK TRANSACTION; THROW; END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HuyChuyen @MaChuyen CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.ChuyenXe WHERE MaChuyen = @MaChuyen) RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.ChuyenXe WHERE MaChuyen = @MaChuyen AND TrangThai = 'KeHoach') THROW 54001, N'54001', 1;
    UPDATE dbo.ChuyenXe SET TrangThai = 'Huy' WHERE MaChuyen = @MaChuyen;
    SELECT @MaChuyen AS MaChuyen;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HuyVe @MaVe VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Ve WHERE MaVe = @MaVe) RETURN;
    IF EXISTS (SELECT 1 FROM dbo.Ve WHERE MaVe = @MaVe AND TrangThai = 'DaHuy')
        THROW 54002, N'54002', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Ve v JOIN dbo.ChuyenXe c ON c.MaChuyen=v.MaChuyen WHERE v.MaVe=@MaVe AND v.TrangThai='DaBan' AND c.TrangThai='KeHoach')
        THROW 54001, N'54001', 1;
    UPDATE dbo.Ve SET TrangThai = 'DaHuy' WHERE MaVe = @MaVe;
    SELECT @MaVe AS MaVe;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LayDanhSachChuyen
    @TrangThai VARCHAR(10) = NULL, @MaCN CHAR(4) = NULL, @TuNgay DATE = NULL, @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.MaChuyen, c.MaTuyen, td.DiemDau + N' - ' + td.DiemCuoi AS TenTuyen, td.DoDaiKm,
           c.MaXe, x.BienSo, c.GioKhoiHanhDK, c.GioDenDK, c.GioKhoiHanhTT, c.GioDenTT,
           lai.MaTX AS MaTXLai, lai.HoTen AS TenTXLai, phu.MaTX AS MaTXPhu, phu.HoTen AS TenTXPhu,
           (SELECT COUNT(*) FROM dbo.Ve v WHERE v.MaChuyen=c.MaChuyen AND v.TrangThai='DaBan') AS DaBan,
           lx.SoGhe - 2 AS SoCho, c.TrangThai
    FROM dbo.ChuyenXe c JOIN dbo.TuyenDuong td ON td.MaTuyen=c.MaTuyen JOIN dbo.Xe x ON x.MaXe=c.MaXe
    JOIN dbo.LoaiXe lx ON lx.MaLoaiXe=x.MaLoaiXe
    OUTER APPLY (SELECT p.MaTX, tx.HoDem+N' '+tx.Ten HoTen FROM dbo.PhanCong p JOIN dbo.TaiXe tx ON tx.MaTX=p.MaTX WHERE p.MaChuyen=c.MaChuyen AND p.VaiTro='LAI') lai
    OUTER APPLY (SELECT p.MaTX, tx.HoDem+N' '+tx.Ten HoTen FROM dbo.PhanCong p JOIN dbo.TaiXe tx ON tx.MaTX=p.MaTX WHERE p.MaChuyen=c.MaChuyen AND p.VaiTro='PHU') phu
    WHERE (@TrangThai IS NULL OR c.TrangThai=@TrangThai) AND (@MaCN IS NULL OR x.MaCN=@MaCN)
      AND (@TuNgay IS NULL OR CAST(c.GioKhoiHanhDK AS DATE)>=@TuNgay) AND (@DenNgay IS NULL OR CAST(c.GioKhoiHanhDK AS DATE)<=@DenNgay)
    ORDER BY c.GioKhoiHanhDK DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LayChiTietChuyen @MaChuyen CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.MaChuyen,c.MaTuyen,td.DiemDau+N' - '+td.DiemCuoi AS TenTuyen,td.DoDaiKm,c.MaXe,x.BienSo,
           c.GioKhoiHanhDK,c.GioDenDK,c.GioKhoiHanhTT,c.GioDenTT,c.KmThucTe,c.ChiPhiVanHanh,c.TrangThai,
           lai.MaTX MaTXLai,lai.HoTen TenTXLai,lai.ThuLao ThuLaoLai,phu.MaTX MaTXPhu,phu.HoTen TenTXPhu,phu.ThuLao ThuLaoPhu,
           (SELECT COUNT(*) FROM dbo.Ve v WHERE v.MaChuyen=c.MaChuyen AND v.TrangThai='DaBan') DaBan,lx.SoGhe-2 SoCho
    FROM dbo.ChuyenXe c JOIN dbo.TuyenDuong td ON td.MaTuyen=c.MaTuyen JOIN dbo.Xe x ON x.MaXe=c.MaXe JOIN dbo.LoaiXe lx ON lx.MaLoaiXe=x.MaLoaiXe
    OUTER APPLY (SELECT p.MaTX,tx.HoDem+N' '+tx.Ten HoTen,p.ThuLao FROM dbo.PhanCong p JOIN dbo.TaiXe tx ON tx.MaTX=p.MaTX WHERE p.MaChuyen=c.MaChuyen AND p.VaiTro='LAI') lai
    OUTER APPLY (SELECT p.MaTX,tx.HoDem+N' '+tx.Ten HoTen,p.ThuLao FROM dbo.PhanCong p JOIN dbo.TaiXe tx ON tx.MaTX=p.MaTX WHERE p.MaChuyen=c.MaChuyen AND p.VaiTro='PHU') phu
    WHERE c.MaChuyen=@MaChuyen;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XemTruocChuyen @MaTuyen CHAR(3), @GioKhoiHanh DATETIME, @MaTXLai CHAR(6)=NULL, @MaTXPhu CHAR(6)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DonGia DECIMAL(12,2)=(SELECT GiaTri FROM dbo.ThamSo WHERE MaThamSo='DON_GIA_KM'),
            @HsLai DECIMAL(12,2)=(SELECT GiaTri FROM dbo.ThamSo WHERE MaThamSo='HS_LAI'),
            @HsPhu DECIMAL(12,2)=(SELECT GiaTri FROM dbo.ThamSo WHERE MaThamSo='HS_PHU');
    SELECT td.MaTuyen,dbo.fn_LoaiNgay(CAST(@GioKhoiHanh AS DATE)) MaLoaiNgay,bg.GiaVe,
           DATEADD(MINUTE,15*CEILING(((td.DoDaiKm/55.0+0.5)*60)/15.0),@GioKhoiHanh) GioDenGoiY,
           CAST(ROUND(td.DoDaiKm*@DonGia*d.HeSoLuong*@HsLai,0) AS DECIMAL(12,0)) ThuLaoLai,
           CAST(ROUND(td.DoDaiKm*@DonGia*d.HeSoLuong*@HsPhu,0) AS DECIMAL(12,0)) ThuLaoPhu
    FROM dbo.TuyenDuong td JOIN dbo.DoPhucTap d ON d.CapDo=td.CapDo
    LEFT JOIN dbo.BangGiaVe bg ON bg.MaTuyen=td.MaTuyen AND bg.MaLoaiNgay=dbo.fn_LoaiNgay(CAST(@GioKhoiHanh AS DATE))
    WHERE td.MaTuyen=@MaTuyen;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LaySoDoGhe @MaChuyen CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH N AS (SELECT 1 n UNION ALL SELECT n+1 FROM N WHERE n<50)
    SELECT c.MaChuyen,c.MaTuyen,td.DiemDau+N' - '+td.DiemCuoi TenTuyen,c.MaXe,x.BienSo,c.GioKhoiHanhDK,
           dbo.fn_LoaiNgay(CAST(c.GioKhoiHanhDK AS DATE)) MaLoaiNgay,bg.GiaVe,n.n SoGhe,
           CAST(CASE WHEN n.n>2 AND v.MaVe IS NULL AND c.TrangThai='KeHoach' THEN 1 ELSE 0 END AS BIT) CoTheBan,v.MaVe,
           CAST(CASE WHEN v.MaVe IS NOT NULL THEN 1 ELSE 0 END AS BIT) DaBan
    FROM dbo.ChuyenXe c JOIN dbo.TuyenDuong td ON td.MaTuyen=c.MaTuyen JOIN dbo.Xe x ON x.MaXe=c.MaXe JOIN dbo.LoaiXe lx ON lx.MaLoaiXe=x.MaLoaiXe
    JOIN N n ON n.n<=lx.SoGhe LEFT JOIN dbo.BangGiaVe bg ON bg.MaTuyen=c.MaTuyen AND bg.MaLoaiNgay=dbo.fn_LoaiNgay(CAST(c.GioKhoiHanhDK AS DATE))
    LEFT JOIN dbo.Ve v ON v.MaChuyen=c.MaChuyen AND v.SoGhe=n.n AND v.TrangThai='DaBan'
    WHERE c.MaChuyen=@MaChuyen ORDER BY n.n OPTION (MAXRECURSION 50);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TraCuuVeTheoSDT @SoDienThoai VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT v.MaVe,hk.HoTen,hk.SoDienThoai,v.MaChuyen,c.MaTuyen,td.DiemDau+N' - '+td.DiemCuoi TenTuyen,
           v.SoGhe,v.GiaVe,v.NgayBan,v.TrangThai
    FROM dbo.Ve v JOIN dbo.HanhKhach hk ON hk.MaHK=v.MaHK JOIN dbo.ChuyenXe c ON c.MaChuyen=v.MaChuyen
    JOIN dbo.TuyenDuong td ON td.MaTuyen=c.MaTuyen WHERE hk.SoDienThoai LIKE '%'+@SoDienThoai+'%' ORDER BY v.NgayBan DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LayDanhSachVeTheoChuyen @MaChuyen CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT v.MaVe,v.SoGhe,v.LanBan,hk.HoTen,hk.SoDienThoai,v.GiaVe,v.NgayBan,v.TrangThai,
           v.MaChuyen,c.MaTuyen,td.DiemDau+N' - '+td.DiemCuoi TenTuyen
    FROM dbo.Ve v JOIN dbo.HanhKhach hk ON hk.MaHK=v.MaHK
    JOIN dbo.ChuyenXe c ON c.MaChuyen=v.MaChuyen
    JOIN dbo.TuyenDuong td ON td.MaTuyen=c.MaTuyen
    WHERE v.MaChuyen=@MaChuyen
    ORDER BY v.SoGhe,v.LanBan DESC;
END;
GO

/* CONTRACT (nguon su that cho Pha 2)
fn_LoaiNgay(@Ngay DATE) -> VARCHAR(10).
sp_KiemTraXeDuDieuKien(@MaXe CHAR(5), @NgayKhoiHanh DATE) -> no result set (stub neu C chua tao).
sp_TaoChuyenVaPhanCong(@MaTuyen CHAR(3),@MaXe CHAR(5),@GioKhoiHanh DATETIME,@GioDen DATETIME,@MaLai CHAR(6),@MaPhu CHAR(6),@MaChuyen CHAR(10)=NULL) -> MaChuyen; THROW 50301|MaTX neu tai xe khong DangLam; THROW 54003 neu het STT ngay.
sp_KetThucChuyen(@MaChuyen CHAR(10),@GioKhoiHanhTT DATETIME=NULL,@GioDenTT DATETIME=NULL,@KmThucTe INT,@ChiPhiVanHanh DECIMAL(12,0)) -> MaChuyen; 0 rows if not found.
sp_BanVe(@MaChuyen CHAR(10),@SoGhe INT,@HoTen NVARCHAR(100),@SoDienThoai VARCHAR(15),@CCCD CHAR(12)=NULL,@Email VARCHAR(100)=NULL,@MaNVBan CHAR(6)) -> MaVe,GiaVe,LanBan; 0 rows if trip not found.
sp_HuyChuyen(@MaChuyen CHAR(10)) -> MaChuyen; 0 rows if not found; THROW 54001 neu chuyen khong KeHoach.
sp_HuyVe(@MaVe VARCHAR(30)) -> MaVe; 0 rows if not found; THROW 54002 neu ve da huy, 54001 neu chuyen khong KeHoach.
sp_LayDanhSachChuyen(@TrangThai VARCHAR(10)=NULL,@MaCN CHAR(4)=NULL,@TuNgay DATE=NULL,@DenNgay DATE=NULL) -> MaChuyen,MaTuyen,TenTuyen,DoDaiKm,MaXe,BienSo,GioKhoiHanhDK,GioDenDK,GioKhoiHanhTT,GioDenTT,MaTXLai,TenTXLai,MaTXPhu,TenTXPhu,DaBan,SoCho,TrangThai.
sp_LayChiTietChuyen(@MaChuyen CHAR(10)) -> MaChuyen,MaTuyen,TenTuyen,DoDaiKm,MaXe,BienSo,GioKhoiHanhDK,GioDenDK,GioKhoiHanhTT,GioDenTT,KmThucTe,ChiPhiVanHanh,TrangThai,MaTXLai,TenTXLai,ThuLaoLai,MaTXPhu,TenTXPhu,ThuLaoPhu,DaBan,SoCho.
sp_XemTruocChuyen(@MaTuyen CHAR(3),@GioKhoiHanh DATETIME,@MaTXLai CHAR(6)=NULL,@MaTXPhu CHAR(6)=NULL) -> MaTuyen,MaLoaiNgay,GiaVe,GioDenGoiY,ThuLaoLai,ThuLaoPhu.
sp_LaySoDoGhe(@MaChuyen CHAR(10)) -> MaChuyen,MaTuyen,TenTuyen,MaXe,BienSo,GioKhoiHanhDK,MaLoaiNgay,GiaVe,SoGhe,CoTheBan,MaVe,DaBan.
sp_TraCuuVeTheoSDT(@SoDienThoai VARCHAR(15)) -> MaVe,HoTen,SoDienThoai,MaChuyen,MaTuyen,TenTuyen,SoGhe,GiaVe,NgayBan,TrangThai.
sp_LayDanhSachVeTheoChuyen(@MaChuyen CHAR(10)) -> MaVe,SoGhe,LanBan,HoTen,SoDienThoai,GiaVe,NgayBan,TrangThai,MaChuyen,MaTuyen,TenTuyen; 0 rows if trip has no tickets or does not exist (Java calls sp_LayChiTietChuyen first to distinguish).
*/
