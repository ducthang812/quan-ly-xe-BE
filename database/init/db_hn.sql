CREATE DATABASE QLXeKhach_HN;
GO
USE QLXeKhach_HN;
GO

-- ==========================================
-- A. TẠO 19 BẢNG (CHUẨN BCNF)
-- ==========================================

-- 1. Nhóm danh mục dùng chung
CREATE TABLE ThamSo (
    MaThamSo VARCHAR(50) PRIMARY KEY, 
    GiaTri FLOAT NOT NULL, 
    MoTa NVARCHAR(255)
);

CREATE TABLE DoPhucTap (
    CapDo INT PRIMARY KEY CHECK (CapDo IN (1, 2, 3)), 
    MoTa NVARCHAR(100), 
    HeSoLuong FLOAT NOT NULL CHECK (HeSoLuong > 0), 
    HeSoDuongKho FLOAT NOT NULL CHECK (HeSoDuongKho >= 1)
);

CREATE TABLE LoaiXe (
    MaLoaiXe VARCHAR(10) PRIMARY KEY, 
    TenLoaiXe NVARCHAR(100) UNIQUE NOT NULL, 
    SoGhe INT NOT NULL CHECK (SoGhe BETWEEN 9 AND 50)
);

CREATE TABLE LoaiNgay (
    MaLoaiNgay VARCHAR(20) PRIMARY KEY, 
    TenLoaiNgay NVARCHAR(50) NOT NULL
);

CREATE TABLE LichNgay (
    Ngay DATE PRIMARY KEY, 
    MaLoaiNgay VARCHAR(20) NOT NULL,
    CONSTRAINT FK_LichNgay_LoaiNgay FOREIGN KEY (MaLoaiNgay) REFERENCES LoaiNgay(MaLoaiNgay)
);

CREATE TABLE TuyenDuong (
    MaTuyen VARCHAR(10) PRIMARY KEY, 
    DiemDau NVARCHAR(50) NOT NULL, 
    DiemCuoi NVARCHAR(50) NOT NULL, 
    DoDaiKm FLOAT NOT NULL CHECK (DoDaiKm > 0), 
    CapDo INT NOT NULL,
    CONSTRAINT FK_Tuyen_DoPhucTap FOREIGN KEY (CapDo) REFERENCES DoPhucTap(CapDo),
    CONSTRAINT CK_Tuyen_DiemKhacNhau CHECK (DiemDau <> DiemCuoi)
);

CREATE TABLE BangGiaVe (
    MaTuyen VARCHAR(10), 
    MaLoaiNgay VARCHAR(20), 
    GiaVe FLOAT NOT NULL CHECK (GiaVe > 0), 
    PRIMARY KEY (MaTuyen, MaLoaiNgay),
    CONSTRAINT FK_GiaVe_Tuyen FOREIGN KEY (MaTuyen) REFERENCES TuyenDuong(MaTuyen),
    CONSTRAINT FK_GiaVe_LoaiNgay FOREIGN KEY (MaLoaiNgay) REFERENCES LoaiNgay(MaLoaiNgay)
);

CREATE TABLE ChiNhanh (
    MaCN VARCHAR(10) PRIMARY KEY, 
    TenCN NVARCHAR(100) NOT NULL, 
    DiaChi NVARCHAR(255), 
    SoDienThoai VARCHAR(15), 
    MaTruongCN VARCHAR(15)
);

-- 2. Nhóm giao dịch cục bộ Hà Nội
CREATE TABLE NhanVien (
    MaNV VARCHAR(15) PRIMARY KEY, 
    HoDem NVARCHAR(50) NOT NULL, 
    Ten NVARCHAR(20) NOT NULL, 
    ChucVu VARCHAR(20) CHECK (ChucVu IN ('BanVe', 'DieuHanh', 'KyThuat', 'QuanLy')), 
    SoDienThoai VARCHAR(15), 
    MaCN VARCHAR(10) NOT NULL,
    CONSTRAINT FK_NhanVien_ChiNhanh FOREIGN KEY (MaCN) REFERENCES ChiNhanh(MaCN)
);

ALTER TABLE ChiNhanh 
ADD CONSTRAINT FK_CN_TruongCN FOREIGN KEY (MaTruongCN) REFERENCES NhanVien(MaNV);

CREATE TABLE Xe (
    MaXe VARCHAR(10) PRIMARY KEY, 
    BienSo VARCHAR(15) UNIQUE NOT NULL, 
    MaLoaiXe VARCHAR(10) NOT NULL, 
    MaCN VARCHAR(10) NOT NULL, 
    NamSanXuat INT NOT NULL CHECK (NamSanXuat >= 2005), 
    NgayDuaVaoSD DATE NOT NULL, 
    TrangThai VARCHAR(20) DEFAULT 'HoatDong' CHECK (TrangThai IN ('HoatDong', 'BaoDuong', 'NgungHD')),
    CONSTRAINT FK_Xe_LoaiXe FOREIGN KEY (MaLoaiXe) REFERENCES LoaiXe(MaLoaiXe),
    CONSTRAINT FK_Xe_ChiNhanh FOREIGN KEY (MaCN) REFERENCES ChiNhanh(MaCN)
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
    MaCN VARCHAR(10) NOT NULL,
    CONSTRAINT FK_TaiXe_ChiNhanh FOREIGN KEY (MaCN) REFERENCES ChiNhanh(MaCN)
);

CREATE TABLE TaiXe_SDT (
    MaTX VARCHAR(10), 
    SoDienThoai VARCHAR(15), 
    PRIMARY KEY (MaTX, SoDienThoai),
    CONSTRAINT FK_TaiXeSDT_TaiXe FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX) ON DELETE CASCADE
);

CREATE TABLE ChuyenXe (
    MaChuyen VARCHAR(15) PRIMARY KEY, 
    MaTuyen VARCHAR(10) NOT NULL, 
    MaXe VARCHAR(10) NOT NULL, 
    GioKhoiHanhDK DATETIME NOT NULL, 
    GioDenDK DATETIME, 
    GioKhoiHanhTT DATETIME, 
    GioDenTT DATETIME, 
    KmThucTe FLOAT, 
    ChiPhiVanHanh FLOAT CHECK (ChiPhiVanHanh >= 0), 
    TrangThai VARCHAR(20) DEFAULT 'KeHoach' CHECK (TrangThai IN ('KeHoach', 'DangChay', 'HoanThanh', 'Huy')),
    CONSTRAINT FK_Chuyen_Tuyen FOREIGN KEY (MaTuyen) REFERENCES TuyenDuong(MaTuyen),
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
-- B. INSERT DỮ LIỆU GỐC & CẤU HÌNH
-- ==========================================
INSERT INTO ThamSo VALUES 
('DON_GIA_KM', 2000, N'Đơn giá thù lao mỗi km'), 
('HS_LAI', 1.0, N'Hệ số lái xe'), 
('HS_PHU', 0.6, N'Hệ số phụ xe'), 
('CHU_KY_BD', 360, N'Chu kỳ BD'), 
('KM_MOI_NGAY_BD', 100, N'Số km giảm 1 ngày BD'), 
('CANH_BAO_NGAY', 15, N'Cảnh báo đến hạn'), 
('CHU_KY_DK_CU', 6, N'ĐK xe cũ'), 
('CHU_KY_DK_MOI', 12, N'ĐK xe mới'), 
('TUOI_XE_CU', 5, N'Tuổi xe cũ');

INSERT INTO DoPhucTap VALUES 
(1, N'Đường bằng', 1.0, 1.0), 
(2, N'Đèo nhẹ', 1.2, 1.3), 
(3, N'Đèo dốc', 1.5, 1.6);

INSERT INTO LoaiXe VALUES 
('LX09', N'Limousine 9 chỗ', 9), 
('LX16', N'Xe 16 chỗ', 16), 
('LX29', N'Xe 29 chỗ', 29), 
('LX45', N'Xe 45 chỗ', 45);

INSERT INTO LoaiNgay VALUES 
('THUONG', N'Ngày thường'), 
('CUOITUAN', N'Cuối tuần'), 
('MUADL', N'Mùa du lịch'), 
('LETET', N'Ngày Lễ Tết');

INSERT INTO LichNgay VALUES 
('2025-06-02', 'MUADL'), 
('2025-06-03', 'THUONG');

INSERT INTO TuyenDuong VALUES 
('T01', N'Hà Nội', N'Đà Nẵng', 760, 2), 
('T02', N'Hà Nội', N'Vinh', 300, 2);

INSERT INTO BangGiaVe VALUES 
('T01', 'THUONG', 400000), 
('T01', 'MUADL', 460000), 
('T02', 'THUONG', 250000), 
('T02', 'MUADL', 287500);

INSERT INTO ChiNhanh (MaCN, TenCN, DiaChi) VALUES 
('CN01', N'Hà Nội', N'Bến Mỹ Đình'), 
('CN02', N'Đà Nẵng', N'Bến Trung tâm'), 
('CN03', N'TP.HCM', N'Bến Miền Đông');

INSERT INTO NhanVien VALUES 
('NV_HN01', N'Trần', N'Quản', 'QuanLy', '0901111111', 'CN01'), 
('NV_HN02', N'Lê', N'Bán', 'BanVe', '0902222222', 'CN01');

UPDATE ChiNhanh SET MaTruongCN = 'NV_HN01' WHERE MaCN = 'CN01';

INSERT INTO Xe VALUES 
('XE001', '29B-123.45', 'LX45', 'CN01', 2022, '2025-01-01', 'HoatDong');

INSERT INTO TaiXe VALUES 
('TX0001', N'Nguyễn', N'Tài', '1985-05-10', '001085000001', 'GPLX001', 'E', N'Số 1', N'Mỹ Đình', N'Hà Nội', '2023-01-01', 'DangLam', 'CN01'), 
('TX0002', N'Lê', N'Phụ', '1995-08-20', '001095000002', 'GPLX002', 'D', N'Số 2', N'Cầu Giấy', N'Hà Nội', '2024-01-01', 'DangLam', 'CN01');
GO


USE [master];
GO

-- 1. Trỏ sang Đà Nẵng (Dùng tên container sql_dn, port gốc 1433)
EXEC sp_addlinkedserver 
    @server = N'SERVER_DN', 
    @srvproduct = N'', 
    @provider = N'MSOLEDBSQL', 
    @datasrc = N'sql_dn,1433'; -- Trong docker dùng ten container sql_dn, port gốc 1433
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'SERVER_DN', 
    @useself = N'False', 
    @rmtuser = N'sa', 
    @rmtpassword = N'Abc@123456';

EXEC sp_serveroption @server = N'SERVER_DN', @optname = 'rpc', @optvalue = 'true';
EXEC sp_serveroption @server = N'SERVER_DN', @optname = 'rpc out', @optvalue = 'true';

-- 2. Trỏ sang TP.HCM (Dùng tên container sql_hcm, port gốc 1433)
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