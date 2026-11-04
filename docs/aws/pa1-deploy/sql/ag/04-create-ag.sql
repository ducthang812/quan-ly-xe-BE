-- Chay tren NODE 1: tao Availability Group (khong cluster, failover bang tay)
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.availability_groups WHERE name = N'$(AG)')
    CREATE AVAILABILITY GROUP [$(AG)]
        WITH (CLUSTER_TYPE = NONE)
        FOR REPLICA ON
            N'$(SQL1)' WITH (
                ENDPOINT_URL = N'tcp://$(SQL1):5022',
                AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
                FAILOVER_MODE = MANUAL,
                SEEDING_MODE = AUTOMATIC,
                SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)),
            N'$(SQL2)' WITH (
                ENDPOINT_URL = N'tcp://$(SQL2):5022',
                AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
                FAILOVER_MODE = MANUAL,
                SEEDING_MODE = AUTOMATIC,
                SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL));
GO
ALTER AVAILABILITY GROUP [$(AG)] GRANT CREATE ANY DATABASE;
GO
