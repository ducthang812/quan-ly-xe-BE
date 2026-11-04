-- Chay tren NODE 1 (Primary) cho tung CSDL cua site. Bien: $(DB)
USE [$(DB)];
GO
-- link_user: dung cho Linked Server. Doc moi bang + EXECUTE stored procedure cua nhom
-- (BE goi thu tuc o chi nhanh khac qua linked server, vd sp_LayDanhSachTaiXe, sp_ChotLuongThang).
-- Khong co quyen INSERT/UPDATE/DELETE truc tiep: moi thay doi phai di qua thu tuc.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'link_user')
    CREATE USER link_user FOR LOGIN link_user;
ALTER ROLE db_datareader ADD MEMBER link_user;
GRANT EXECUTE TO link_user;
DENY INSERT, UPDATE, DELETE TO link_user;
GO
-- app_user: login cua BE (Spring Boot). Doc, ghi va goi stored procedure.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_user')
    CREATE USER app_user FOR LOGIN app_user;
ALTER ROLE db_datareader ADD MEMBER app_user;
ALTER ROLE db_datawriter ADD MEMBER app_user;
GRANT EXECUTE TO app_user;
GO
