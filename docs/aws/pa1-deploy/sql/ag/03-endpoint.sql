-- Chay tren CA 2 NODE: endpoint dong bo AG o cong 5022
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE name = 'Hadr_endpoint')
    CREATE ENDPOINT [Hadr_endpoint]
        AS TCP (LISTENER_PORT = 5022)
        FOR DATABASE_MIRRORING (
            ROLE = ALL,
            AUTHENTICATION = CERTIFICATE dbm_certificate,
            ENCRYPTION = REQUIRED ALGORITHM AES);
GO
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [dbm_login];
GO
