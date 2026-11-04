-- Tao/cap nhat view tong hop o TruSo: dbo.v_<Bang> = UNION ALL cua cn01, cn02, cn03 (bang nao da co).
-- Chay tren Primary cua HN, sau khi snapshot cua ca 3 chi nhanh da ve. Chay lai bao nhieu lan cung duoc.
USE [TruSo];
GO
SET NOCOUNT ON;
DECLARE @t sysname, @sql nvarchar(max), @part nvarchar(max), @s sysname;
DECLARE tb CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM (VALUES (N'NhanVien'), (N'Xe'), (N'TaiXe'), (N'TaiXe_SDT'), (N'ChuyenXe'), (N'PhanCong'),
                             (N'HanhKhach'), (N'Ve'), (N'BaoDuong'), (N'DangKiem'), (N'BangLuong')) v(name);
OPEN tb; FETCH NEXT FROM tb INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @part = NULL;
    DECLARE sc CURSOR LOCAL FAST_FORWARD FOR SELECT s FROM (VALUES (N'cn01'), (N'cn02'), (N'cn03')) v(s);
    OPEN sc; FETCH NEXT FROM sc INTO @s;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF OBJECT_ID(QUOTENAME(@s) + N'.' + QUOTENAME(@t), N'U') IS NOT NULL
            SET @part = ISNULL(@part + NCHAR(10) + N'UNION ALL ', N'')
                      + N'SELECT ''' + UPPER(@s) + N''' AS CN_Nguon, * FROM ' + QUOTENAME(@s) + N'.' + QUOTENAME(@t);
        FETCH NEXT FROM sc INTO @s;
    END
    CLOSE sc; DEALLOCATE sc;
    IF @part IS NOT NULL
    BEGIN
        SET @sql = N'CREATE OR ALTER VIEW dbo.' + QUOTENAME(N'v_' + @t) + N' AS ' + NCHAR(10) + @part + N';';
        EXEC (@sql);
        PRINT N'v_' + @t + N': ' + REPLACE(@part, NCHAR(10), N' ');
    END
    ELSE PRINT N'v_' + @t + N': chua co bang nao (snapshot chua ve?)';
    FETCH NEXT FROM tb INTO @t;
END
CLOSE tb; DEALLOCATE tb;
GO
