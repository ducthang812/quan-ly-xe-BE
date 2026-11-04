-- (2) NHAN BAN XUONG: 9 bang danh muc tu QLXeKhach_HN (ban goc o Tru so) -> DN, HCM.
-- Chay tren sql-hn-1. Chi nhanh nhan ban sao chi doc; sua danh muc chi o Ha Noi.
-- Subscriber la listener (lsn-*) nen van ghi duoc vao Primary moi sau failover o chi nhanh.
USE [QLXeKhach_HN];
GO
EXEC sp_replicationdboption @dbname = N'QLXeKhach_HN', @optname = N'publish', @value = N'true';
GO
IF NOT EXISTS (SELECT 1 FROM distribution.dbo.MSlogreader_agents WHERE publisher_db = N'QLXeKhach_HN')
    EXEC sp_addlogreader_agent @job_login = NULL, @job_password = NULL,
         @publisher_security_mode = 0, @publisher_login = N'sa', @publisher_password = N'$(SA_PASSWORD)';
GO
IF NOT EXISTS (SELECT 1 FROM dbo.syspublications WHERE name = N'PUB_DANHMUC')
BEGIN
    EXEC sp_addpublication @publication = N'PUB_DANHMUC', @status = N'active',
         @allow_push = N'true', @allow_pull = N'false', @independent_agent = N'true',
         @repl_freq = N'continuous', @immediate_sync = N'true', @retention = 0,
         @description = N'Danh muc tu Tru so xuong chi nhanh';
    EXEC sp_addpublication_snapshot @publication = N'PUB_DANHMUC', @frequency_type = 1,
         @job_login = NULL, @job_password = NULL,
         @publisher_security_mode = 0, @publisher_login = N'sa', @publisher_password = N'$(SA_PASSWORD)';

    -- 9 bang danh muc dung chung: 8 bang trong db_hn.sql + LichLoaiNgay (do migration cua A tao o HN,
    -- trigger ban ve cua B dung qua dbo.fn_LoaiNgay)
    DECLARE @t sysname;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM (VALUES (N'ThamSo'), (N'DoPhucTap'), (N'LoaiXe'), (N'LoaiNgay'), (N'LichNgay'),
                                 (N'LichLoaiNgay'), (N'TuyenDuong'), (N'BangGiaVe'), (N'ChiNhanh')) v(name);
    OPEN c; FETCH NEXT FROM c INTO @t;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_addarticle @publication = N'PUB_DANHMUC', @article = @t,
             @source_owner = N'dbo', @source_object = @t, @destination_table = @t,
             @pre_creation_cmd = N'drop';
        FETCH NEXT FROM c INTO @t;
    END
    CLOSE c; DEALLOCATE c;

    EXEC sp_addsubscription @publication = N'PUB_DANHMUC', @subscriber = N'lsn-dn', @destination_db = N'QLXeKhach_DN',
         @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only';
    EXEC sp_addpushsubscription_agent @publication = N'PUB_DANHMUC', @subscriber = N'lsn-dn', @subscriber_db = N'QLXeKhach_DN',
         @job_login = NULL, @job_password = NULL,
         @subscriber_security_mode = 0, @subscriber_login = N'sa', @subscriber_password = N'$(SA_PASSWORD)',
         @frequency_type = 64;

    EXEC sp_addsubscription @publication = N'PUB_DANHMUC', @subscriber = N'lsn-hcm', @destination_db = N'QLXeKhach_HCM',
         @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only';
    EXEC sp_addpushsubscription_agent @publication = N'PUB_DANHMUC', @subscriber = N'lsn-hcm', @subscriber_db = N'QLXeKhach_HCM',
         @job_login = NULL, @job_password = NULL,
         @subscriber_security_mode = 0, @subscriber_login = N'sa', @subscriber_password = N'$(SA_PASSWORD)',
         @frequency_type = 64;

    -- Snapshot lan dau: tao bang danh muc o DN, HCM va nap du lieu (1-2 phut)
    EXEC sp_startpublication_snapshot @publication = N'PUB_DANHMUC';
END
GO
