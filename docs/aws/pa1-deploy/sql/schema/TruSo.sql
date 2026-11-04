-- CSDL tong hop o Tru so (chi tao tren NODE 1 cua site HN).
-- Danh muc goc van nam trong QLXeKhach_HN (Tru so sua o do).
-- TruSo chua ban sao du lieu giao dich cua ca 3 chi nhanh, moi chi nhanh mot schema rieng:
--   cn01.* <- QLXeKhach_HN,  cn02.* <- QLXeKhach_DN,  cn03.* <- QLXeKhach_HCM
-- Bang trong cac schema do replication (snapshot) tu tao. Tach schema de ma cua 3 chi nhanh
-- khong dam nhau. Cac view dbo.v_<Bang> gop 3 chi nhanh lai (sql/truso/views.sql).
USE master;
GO
IF DB_ID(N'TruSo') IS NULL CREATE DATABASE [TruSo];
GO
USE [TruSo];
GO
IF SCHEMA_ID(N'cn01') IS NULL EXEC (N'CREATE SCHEMA cn01 AUTHORIZATION dbo');
IF SCHEMA_ID(N'cn02') IS NULL EXEC (N'CREATE SCHEMA cn02 AUTHORIZATION dbo');
IF SCHEMA_ID(N'cn03') IS NULL EXEC (N'CREATE SCHEMA cn03 AUTHORIZATION dbo');
GO
