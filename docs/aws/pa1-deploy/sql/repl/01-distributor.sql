-- Chay tren NODE 1 cua site: bien node 1 thanh Distributor + Publisher (distributor cuc bo).
USE master;
GO
DECLARE @me sysname = @@SERVERNAME;
IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = 'repl_distributor')
    EXEC sp_adddistributor @distributor = @me, @password = N'$(SA_PASSWORD)';
GO
IF DB_ID(N'distribution') IS NULL
    EXEC sp_adddistributiondb @database = N'distribution', @log_file_size = 2,
         @deletebatchsize_xact = 5000, @deletebatchsize_cmd = 2000,
         @security_mode = 0, @login = N'sa', @password = N'$(SA_PASSWORD)';
GO
-- Thu muc snapshot (da tao boi scripts/30-repl.sh)
USE [distribution];
GO
DECLARE @dir nvarchar(500) = N'/var/opt/mssql/data/ReplData/';
IF OBJECT_ID(N'dbo.UIProperties') IS NULL CREATE TABLE dbo.UIProperties (id int);
IF EXISTS (SELECT 1 FROM ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', NULL, NULL))
    EXEC sp_updateextendedproperty N'SnapshotFolder', @dir, 'user', dbo, 'table', 'UIProperties';
ELSE
    EXEC sp_addextendedproperty N'SnapshotFolder', @dir, 'user', dbo, 'table', 'UIProperties';
GO
DECLARE @me sysname = @@SERVERNAME;
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.MSdistpublishers WHERE name = @me)
    EXEC sp_adddistpublisher @publisher = @me, @distribution_db = N'distribution',
         @security_mode = 0, @login = N'sa', @password = N'$(SA_PASSWORD)',
         @working_directory = N'/var/opt/mssql/data/ReplData/',
         @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER';
GO
