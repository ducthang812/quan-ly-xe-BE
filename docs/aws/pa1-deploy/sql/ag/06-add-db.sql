-- Chay tren NODE 1 (Primary): dua 1 CSDL vao AG. Bien: $(DB)
USE master;
GO
ALTER DATABASE [$(DB)] SET RECOVERY FULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.availability_databases_cluster WHERE database_name = N'$(DB)')
BEGIN
    BACKUP DATABASE [$(DB)] TO DISK = N'/var/opt/mssql/data/$(DB).bak' WITH INIT;
    ALTER AVAILABILITY GROUP [$(AG)] ADD DATABASE [$(DB)];
END
GO
