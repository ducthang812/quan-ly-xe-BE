CREATE DATABASE QLXeKhach_DN;
GO
USE QLXeKhach_DN;
GO

-- ==========================================
-- A. TẠO 12 BẢNG GIAO DỊCH CỤC BỘ TẠI ĐÀ NẴNG
-- (Gỡ khóa ngoại trỏ về bảng danh mục ở HN)
-- ==========================================

CREATE TABLE NhanVien (
    MaNV VARCHAR(15) PRIMARY KEY, 
    HoDem NVARCHAR(50) NOT NULL, 
    Ten NVARCHAR(20) NOT NULL, 
    ChucVu VARCHAR(20) CHECK (ChucVu IN ('BanVe', 'DieuHanh', 'KyThuat', 'QuanLy')), 
    SoDienThoai VARCHAR(15), 
    MaCN VARCHAR(10) NOT NULL -- Tham chiếu ngầm về ChiNhanh ở HN
);

CREATE TABLE Xe (
    MaXe VARCHAR(10) PRIMARY KEY, 
    BienSo VARCHAR(15) UNIQUE NOT NULL, 
    MaLoaiXe VARCHAR(10) NOT NULL, -- Tham chiếu ngầm về LoaiXe ở HN
    MaCN VARCHAR(10) NOT NULL, 
    NamSanXuat INT NOT NULL CHECK (NamSanXuat >= 2005), 
    NgayDuaVaoSD DATE NOT NULL, 
    TrangThai VARCHAR(20) DEFAULT 'HoatDong' CHECK (TrangThai IN ('HoatDong', 'BaoDuong', 'NgungHD'))
);

CREATE TABLE TaiXe (
    MaTX VARCHAR(10) PRIMARY KEY, 
    HoDem NVARCHAR(50) NOT NULL, 
    Ten NVARCHAR(20) NOT NULL, 
    NgaySinh DATE NOT NULL CHECK (DATEDIFF(YEAR, NgaySinh, GETDATE()) >= 21), 
    CCCD VARCHAR(12) UNIQUE NOT NULL, 
    SoGPLX VARCHAR(20) UNIQUE NOT NULL, 
    HangGPLX VARCHAR(5) CHECK (HangGPLX IN ('D', 'E', 'FC')), 
    SoNha NVARCHAR(100), 
    Phuong NVARCHAR(50), 
    Tinh NVARCHAR(50), 
    NgayVaoLam DATE NOT NULL, 
    TrangThai VARCHAR(20) DEFAULT 'DangLam' CHECK (TrangThai IN ('DangLam', 'NghiViec')), 
    MaCN VARCHAR(10) NOT NULL
);

CREATE TABLE TaiXe_SDT (
    MaTX VARCHAR(10), 
    SoDienThoai VARCHAR(15), 
    PRIMARY KEY (MaTX, SoDienThoai),
    CONSTRAINT FK_TaiXeSDT_TaiXe FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX) ON DELETE CASCADE
);

CREATE TABLE ChuyenXe (
    MaChuyen VARCHAR(15) PRIMARY KEY, 
    MaTuyen VARCHAR(10) NOT NULL, -- Tham chiếu ngầm về TuyenDuong ở HN
    MaXe VARCHAR(10) NOT NULL, 
    GioKhoiHanhDK DATETIME NOT NULL, 
    GioDenDK DATETIME, 
    GioKhoiHanhTT DATETIME, 
    GioDenTT DATETIME, 
    KmThucTe FLOAT, 
    ChiPhiVanHanh FLOAT CHECK (ChiPhiVanHanh >= 0), 
    TrangThai VARCHAR(20) DEFAULT 'KeHoach' CHECK (TrangThai IN ('KeHoach', 'DangChay', 'HoanThanh', 'Huy')),
    CONSTRAINT FK_Chuyen_Xe FOREIGN KEY (MaXe) REFERENCES Xe(MaXe)
);

CREATE TABLE PhanCong (
    MaChuyen VARCHAR(15), 
    MaTX VARCHAR(10), 
    VaiTro VARCHAR(10) CHECK (VaiTro IN ('LAI', 'PHU')), 
    ThuLao FLOAT NOT NULL, 
    PRIMARY KEY (MaChuyen, MaTX), 
    CONSTRAINT UQ_PC_VaiTro UNIQUE (MaChuyen, VaiTro),
    CONSTRAINT FK_PhanCong_Chuyen FOREIGN KEY (MaChuyen) REFERENCES ChuyenXe(MaChuyen),
    CONSTRAINT FK_PhanCong_TaiXe FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX)
);

CREATE TABLE HanhKhach (
    MaHK VARCHAR(15) PRIMARY KEY, 
    HoTen NVARCHAR(100) NOT NULL, 
    SoDienThoai VARCHAR(15) UNIQUE NOT NULL, 
    CCCD VARCHAR(12), 
    Email VARCHAR(100)
);

CREATE TABLE Ve (
    MaVe VARCHAR(50) PRIMARY KEY, 
    MaChuyen VARCHAR(15) NOT NULL, 
    MaHK VARCHAR(15) NOT NULL, 
    MaNVBan VARCHAR(15) NOT NULL, 
    SoGhe INT NOT NULL, 
    LanBan INT NOT NULL, 
    GiaVe FLOAT NOT NULL CHECK (GiaVe > 0), 
    NgayBan DATETIME DEFAULT GETDATE(), 
    TrangThai VARCHAR(20) DEFAULT 'DaBan' CHECK (TrangThai IN ('DaBan', 'DaHuy')),
    CONSTRAINT FK_Ve_Chuyen FOREIGN KEY (MaChuyen) REFERENCES ChuyenXe(MaChuyen),
    CONSTRAINT FK_Ve_HanhKhach FOREIGN KEY (MaHK) REFERENCES HanhKhach(MaHK),
    CONSTRAINT FK_Ve_NVBan FOREIGN KEY (MaNVBan) REFERENCES NhanVien(MaNV)
);

CREATE UNIQUE INDEX UX_Ve_GheDangBan ON Ve(MaChuyen, SoGhe) WHERE TrangThai = 'DaBan';

CREATE TABLE BaoDuong (
    MaXe VARCHAR(10), 
    NgayBaoDuong DATE, 
    NoiDung NVARCHAR(255), 
    ChiPhi FLOAT CHECK (ChiPhi >= 0), 
    PRIMARY KEY (MaXe, NgayBaoDuong),
    CONSTRAINT FK_BaoDuong_Xe FOREIGN KEY (MaXe) REFERENCES Xe(MaXe)
);

CREATE TABLE DangKiem (
    MaXe VARCHAR(10), 
    NgayDangKiem DATE, 
    NgayHetHan DATE, 
    KetQua VARCHAR(20) CHECK (KetQua IN ('Dat', 'KhongDat')), 
    ChiPhi FLOAT CHECK (ChiPhi >= 0), 
    PRIMARY KEY (MaXe, NgayDangKiem),
    CONSTRAINT FK_DangKiem_Xe FOREIGN KEY (MaXe) REFERENCES Xe(MaXe)
);

CREATE TABLE BangLuong (
    MaTX VARCHAR(10), 
    Thang VARCHAR(7), 
    SoChuyenLai INT DEFAULT 0, 
    SoChuyenPhu INT DEFAULT 0, 
    TongLuong FLOAT DEFAULT 0, 
    NgayChot DATETIME DEFAULT GETDATE(), 
    PRIMARY KEY (MaTX, Thang),
    CONSTRAINT FK_BangLuong_TaiXe FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX)
);
GO

-- ==========================================
-- B. INSERT DỮ LIỆU CỤC BỘ ĐÀ NẴNG
-- ==========================================
INSERT INTO NhanVien VALUES 
('NV_DN01', N'Phạm', N'Điều Hành ĐN', 'DieuHanh', '0903333333', 'CN02');

INSERT INTO Xe VALUES 
('XE_DN01', '43B-222.22', 'LX29', 'CN02', 2023, '2025-01-01', 'HoatDong'),
('XE_DN02', '43B-333.33', 'LX45', 'CN02', 2022, '2025-01-01', 'HoatDong'),
('XE_DN03', '43B-444.44', 'LX16', 'CN02', 2023, '2025-01-01', 'HoatDong'),
('XE_DN04', '43B-555.55', 'LX09', 'CN02', 2024, '2025-01-01', 'HoatDong'),
('XE_DN05', '43B-666.66', 'LX45', 'CN02', 2023, '2025-01-01', 'HoatDong');

INSERT INTO DangKiem VALUES 
('XE_DN01', '2025-01-01', '2026-01-01', 'Dat', 350000),
('XE_DN02', '2025-01-01', '2026-01-01', 'Dat', 350000),
('XE_DN03', '2025-01-01', '2026-01-01', 'Dat', 350000),
('XE_DN04', '2025-01-01', '2026-01-01', 'Dat', 350000),
('XE_DN05', '2025-01-01', '2026-01-01', 'Dat', 350000);

INSERT INTO TaiXe VALUES 
('TX_DN01', N'Hoàng', N'Lái ĐN', '1988-05-05', '048088333333', 'GP333', 'E', N'Số 12', N'Hải Châu', N'Đà Nẵng', '2025-01-01', 'DangLam', 'CN02'),
('TX_DN02', N'Đỗ', N'Phụ ĐN', '1992-06-06', '048092444444', 'GP444', 'D', N'Số 34', N'Sơn Trà', N'Đà Nẵng', '2025-01-01', 'DangLam', 'CN02'),
('TX_DN03', N'Phan', N'Thịnh', '1989-03-20', '048089433798', 'GP_DN65433798', 'E', N'Số 99', N'Thạch Thang', N'Đà Nẵng', '2025-06-02', 'DangLam', 'CN02'),
('TX_DN04', N'Lê', N'Phước', '1989-03-20', '048089607733', 'GP_DN87607733', 'E', N'Số 99', N'Thạch Thang', N'Đà Nẵng', '2025-06-02', 'DangLam', 'CN02'),
('TX_DN05', N'Nguyễn', N'Khang', '1992-08-25', '001092888999', 'GPLX888999', 'E', N'Số 58', N'Hải Châu', N'Đà Nẵng', '2026-10-26', 'DangLam', 'CN02');

INSERT INTO TaiXe_SDT VALUES 
('TX_DN01', '0905222001'),
('TX_DN02', '0905222002'),
('TX_DN03', '0905222003'),
('TX_DN04', '0905222004'),
('TX_DN05', '0905222005');
GO

-- ==========================================
-- C. CẤU HÌNH LINKED SERVER SANG HN VÀ HCM
-- ==========================================
USE [master];
GO

-- 1. Trỏ về Trụ sở Hà Nội
EXEC sp_addlinkedserver 
    @server = N'SERVER_HN', 
    @srvproduct = N'', 
    @provider = N'MSOLEDBSQL', 
    @datasrc = N'sql_hn,1433';

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'SERVER_HN', 
    @useself = N'False', 
    @rmtuser = N'sa', 
    @rmtpassword = N'Abc@123456';

EXEC sp_serveroption @server = N'SERVER_HN', @optname = 'rpc', @optvalue = 'true';
EXEC sp_serveroption @server = N'SERVER_HN', @optname = 'rpc out', @optvalue = 'true';

-- 2. Trỏ sang Chi nhánh TP.HCM
EXEC sp_addlinkedserver 
    @server = N'SERVER_HCM', 
    @srvproduct = N'', 
    @provider = N'MSOLEDBSQL', 
    @datasrc = N'sql_hcm,1433';

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'SERVER_HCM', 
    @useself = N'False', 
    @rmtuser = N'sa', 
    @rmtpassword = N'Abc@123456';

EXEC sp_serveroption @server = N'SERVER_HCM', @optname = 'rpc', @optvalue = 'true';
EXEC sp_serveroption @server = N'SERVER_HCM', @optname = 'rpc out', @optvalue = 'true';
GO