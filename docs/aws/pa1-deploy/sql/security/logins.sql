-- Chay tren CA 2 NODE cua site. Login nam trong master nen AG khong tu chep;
-- SID co dinh giup user trong CSDL (duoc AG chep) khong bi "mo coi" sau failover.
--   link_user   : login cho Linked Server tu site khac: doc bang + goi stored procedure (khong ghi truc tiep)
--   app_user    : login cua ung dung (BE), doc + ghi CSDL cua site
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'link_user')
    CREATE LOGIN link_user WITH PASSWORD = '$(LINK_PASSWORD)', SID = 0x5041315F4C494E4B5F52454144455221, CHECK_POLICY = OFF;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'app_user')
    CREATE LOGIN app_user WITH PASSWORD = '$(APP_PASSWORD)', SID = 0x5041315F4150505F555345525F5F5F21, CHECK_POLICY = OFF;
GO
