-- =============================================================================
-- Dong bo tuy chon Linked Server voi ban AWS. Chay trong master tren CA 3 instance
-- (sql_hn, sql_dn, sql_hcm). Chay lai nhieu lan van an toan.
--
-- 'remote proc transaction promotion' = false: khi thu tuc goi EXEC SERVER_xx...
-- ben trong mot transaction, SQL Server KHONG nang len giao dich phan tan (MSDTC).
-- Container SQL Server tren Linux khong co MSDTC, de mac dinh (true) se loi.
-- =============================================================================
USE master;
SET NOCOUNT ON;
DECLARE @s sysname;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM sys.servers WHERE is_linked = 1 AND name LIKE 'SERVER[_]%';
OPEN c; FETCH NEXT FROM c INTO @s;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC sp_serveroption @server = @s, @optname = 'data access', @optvalue = 'true';
    EXEC sp_serveroption @server = @s, @optname = 'rpc',         @optvalue = 'true';
    EXEC sp_serveroption @server = @s, @optname = 'rpc out',     @optvalue = 'true';
    EXEC sp_serveroption @server = @s, @optname = 'remote proc transaction promotion', @optvalue = 'false';
    PRINT N'Da cap nhat ' + @s;
    FETCH NEXT FROM c INTO @s;
END
CLOSE c; DEALLOCATE c;

SELECT @@SERVERNAME AS instance, name, data_source,
       is_data_access_enabled AS data_access, is_rpc_out_enabled AS rpc_out,
       is_remote_proc_transaction_promotion_enabled AS promotion
FROM sys.servers WHERE is_linked = 1;
