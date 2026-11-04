-- (1) DONG BO LEN: 11 bang giao dich cua chi nhanh -> TruSo (o HN), vao schema rieng cnXX.
-- Chay tren NODE 1 cua moi site. Bien: $(BRANCH_DB), $(MACN)
-- Khoi tao bang snapshot: du lieu mau co san trong chi nhanh cung duoc chep len.
-- Ten thu tuc ghi o TruSo co ten schema (vd sp_MSins_cn02Ve) de 3 chi nhanh khong de len nhau.
USE [$(BRANCH_DB)];
GO
EXEC sp_replicationdboption @dbname = N'$(BRANCH_DB)', @optname = N'publish', @value = N'true';
GO
IF NOT EXISTS (SELECT 1 FROM distribution.dbo.MSlogreader_agents WHERE publisher_db = N'$(BRANCH_DB)')
    EXEC sp_addlogreader_agent @job_login = NULL, @job_password = NULL,
         @publisher_security_mode = 0, @publisher_login = N'sa', @publisher_password = N'$(SA_PASSWORD)';
GO
IF NOT EXISTS (SELECT 1 FROM dbo.syspublications WHERE name = N'PUB_LEN_$(MACN)')
BEGIN
    EXEC sp_addpublication @publication = N'PUB_LEN_$(MACN)', @status = N'active',
         @allow_push = N'true', @allow_pull = N'false', @independent_agent = N'true',
         @repl_freq = N'continuous', @immediate_sync = N'true', @retention = 0,
         @description = N'Manh $(MACN) dong bo len Tru so';
    EXEC sp_addpublication_snapshot @publication = N'PUB_LEN_$(MACN)', @frequency_type = 1,
         @job_login = NULL, @job_password = NULL,
         @publisher_security_mode = 0, @publisher_login = N'sa', @publisher_password = N'$(SA_PASSWORD)';

    -- 11 bang giao dich cuc bo (theo db_dn.sql / db_hcm.sql cua nhom, HN co cung 11 bang nay)
    DECLARE @owner sysname = LOWER(N'$(MACN)');
    DECLARE @t sysname, @ins nvarchar(255), @del nvarchar(255), @upd nvarchar(255);
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM (VALUES (N'NhanVien'), (N'Xe'), (N'TaiXe'), (N'TaiXe_SDT'), (N'ChuyenXe'), (N'PhanCong'),
                                 (N'HanhKhach'), (N'Ve'), (N'BaoDuong'), (N'DangKiem'), (N'BangLuong')) v(name);
    OPEN c; FETCH NEXT FROM c INTO @t;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @ins = N'CALL sp_MSins_'  + @owner + @t;
        SET @del = N'CALL sp_MSdel_'  + @owner + @t;
        SET @upd = N'SCALL sp_MSupd_' + @owner + @t;
        EXEC sp_addarticle @publication = N'PUB_LEN_$(MACN)', @article = @t,
             @source_owner = N'dbo', @source_object = @t,
             @destination_owner = @owner, @destination_table = @t,
             @pre_creation_cmd = N'drop',
             @ins_cmd = @ins, @del_cmd = @del, @upd_cmd = @upd;
        FETCH NEXT FROM c INTO @t;
    END
    CLOSE c; DEALLOCATE c;

    EXEC sp_addsubscription @publication = N'PUB_LEN_$(MACN)', @subscriber = N'lsn-hn', @destination_db = N'TruSo',
         @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only';
    EXEC sp_addpushsubscription_agent @publication = N'PUB_LEN_$(MACN)', @subscriber = N'lsn-hn', @subscriber_db = N'TruSo',
         @job_login = NULL, @job_password = NULL,
         @subscriber_security_mode = 0, @subscriber_login = N'sa', @subscriber_password = N'$(SA_PASSWORD)',
         @frequency_type = 64;

    EXEC sp_startpublication_snapshot @publication = N'PUB_LEN_$(MACN)';
END
GO
