-- Chay tren NODE 1: tao login/chung chi cho endpoint AG va xuat chung chi ra thu muc dung chung
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$(MK_PASSWORD)';
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'dbm_login')
    CREATE LOGIN dbm_login WITH PASSWORD = '$(DBM_PASSWORD)';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'dbm_user')
    CREATE USER dbm_user FOR LOGIN dbm_login;
GO
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'dbm_certificate')
BEGIN
    CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'pa1 AG endpoint', EXPIRY_DATE = '20301231';
    BACKUP CERTIFICATE dbm_certificate
        TO FILE = '/var/opt/mssql/shared/dbm_certificate.cer'
        WITH PRIVATE KEY (
            FILE = '/var/opt/mssql/shared/dbm_certificate.pvk',
            ENCRYPTION BY PASSWORD = '$(CERT_PASSWORD)');
END
GO
