-- (3) LINKED SERVER (khop voi stored procedure cua BE: doc bang + goi thu tuc tu xa). Chay tren CA 2 NODE cua site (linked server nam trong master,
-- AG khong chep, nen node 2 cung can co de dung duoc sau failover).
-- Bien: $(LINK) ten linked server, $(TARGET) ten listener dich, $(TARGET_DB) CSDL mac dinh
USE master;
GO
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'$(LINK)')
    EXEC sp_dropserver @server = N'$(LINK)', @droplogins = 'droplogins';
GO
EXEC sp_addlinkedserver @server = N'$(LINK)', @srvproduct = N'', @provider = N'MSOLEDBSQL',
     @datasrc = N'$(TARGET)', @catalog = N'$(TARGET_DB)';
-- Moi login o day dang nhap sang ben kia bang link_user: doc bang + EXECUTE thu tuc, khong ghi truc tiep
EXEC sp_addlinkedsrvlogin @rmtsrvname = N'$(LINK)', @useself = N'False', @locallogin = NULL,
     @rmtuser = N'link_user', @rmtpassword = N'$(LINK_PASSWORD)';
EXEC sp_serveroption @server = N'$(LINK)', @optname = 'data access', @optvalue = 'true';
-- BE goi thu tuc o site khac (EXEC SERVER_DN.QLXeKhach_DN.dbo.sp_...): can rpc + rpc out
EXEC sp_serveroption @server = N'$(LINK)', @optname = 'rpc', @optvalue = 'true';
EXEC sp_serveroption @server = N'$(LINK)', @optname = 'rpc out', @optvalue = 'true';
-- Khong nang len giao dich phan tan (MSDTC khong co trong container Linux)
EXEC sp_serveroption @server = N'$(LINK)', @optname = 'remote proc transaction promotion', @optvalue = 'false';
GO
