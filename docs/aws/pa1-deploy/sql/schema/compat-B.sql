-- Bo sung cho schema db_*.sql de thu tuc/trigger cua module B chay duoc
-- (sp_BanVe, sp_TaoChuyenVaPhanCong them dong ma khong truyen MaVe, LanBan, GiaVe, ThuLao;
--  trigger trg_Ve_SinhMaVaGia sinh MaVe tu ma tam 'TMP...' va tu dien GiaVe,
--  trigger trg_PhanCong_TinhThuLao tu tinh ThuLao).
-- Chay tren NODE 1 cho CSDL chi nhanh ($(BRANCH_DB)). Chay lai nhieu lan cung duoc.
USE [$(BRANCH_DB)];
GO
SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.DF_Ve_MaVe') IS NULL
    ALTER TABLE dbo.Ve ADD CONSTRAINT DF_Ve_MaVe
        DEFAULT ('TMP' + LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 27)) FOR MaVe;
IF OBJECT_ID(N'dbo.DF_Ve_LanBan') IS NULL
    ALTER TABLE dbo.Ve ADD CONSTRAINT DF_Ve_LanBan DEFAULT (0) FOR LanBan;
IF OBJECT_ID(N'dbo.DF_PhanCong_ThuLao') IS NULL
    ALTER TABLE dbo.PhanCong ADD CONSTRAINT DF_PhanCong_ThuLao DEFAULT (0) FOR ThuLao;
GO
-- GiaVe duoc phep NULL luc INSERT (trigger dien gia ngay sau do)
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.Ve') AND name = N'GiaVe' AND is_nullable = 0)
BEGIN
    DECLARE @ck sysname, @sql nvarchar(400);
    SELECT @ck = cc.name
    FROM sys.check_constraints cc
    JOIN sys.columns c ON c.object_id = cc.parent_object_id AND c.column_id = cc.parent_column_id
    WHERE cc.parent_object_id = OBJECT_ID(N'dbo.Ve') AND c.name = N'GiaVe';
    IF @ck IS NOT NULL
    BEGIN
        SET @sql = N'ALTER TABLE dbo.Ve DROP CONSTRAINT ' + QUOTENAME(@ck);
        EXEC (@sql);
    END
    ALTER TABLE dbo.Ve ALTER COLUMN GiaVe FLOAT NULL;
    EXEC (N'ALTER TABLE dbo.Ve ADD CONSTRAINT CK_Ve_GiaVe CHECK (GiaVe > 0)');
END
GO
