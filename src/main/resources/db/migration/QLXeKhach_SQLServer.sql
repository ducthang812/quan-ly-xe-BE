-- 4.1 Nhóm danh mục dùng chung --------------------------------------
CREATE TABLE LoaiXe (
                        MaLoaiXe    CHAR(4)       NOT NULL CONSTRAINT PK_LoaiXe PRIMARY KEY,
                        TenLoaiXe   NVARCHAR(50)  NOT NULL CONSTRAINT UQ_LoaiXe_Ten UNIQUE,
                        SoGhe       INT           NOT NULL CONSTRAINT CK_LoaiXe_SoGhe CHECK (SoGhe BETWEEN 9 AND 50)
    -- Số chỗ khách = SoGhe - 2 là thuộc tính dẫn xuất, không lưu để giữ BCNF
);

CREATE TABLE DoPhucTap (
                           CapDo        TINYINT       NOT NULL CONSTRAINT PK_DoPhucTap PRIMARY KEY
                               CONSTRAINT CK_DoPhucTap_CapDo CHECK (CapDo IN (1,2,3)),
                           MoTa         NVARCHAR(100) NULL,
                           HeSoLuong    DECIMAL(3,2)  NOT NULL CONSTRAINT CK_DoPhucTap_HSL CHECK (HeSoLuong > 0),
                           HeSoDuongKho DECIMAL(3,2)  NOT NULL CONSTRAINT CK_DoPhucTap_HSDK CHECK (HeSoDuongKho >= 1)
);

CREATE TABLE TuyenDuong (
                            MaTuyen   CHAR(3)      NOT NULL CONSTRAINT PK_TuyenDuong PRIMARY KEY,
                            DiemDau   NVARCHAR(50) NOT NULL,
                            DiemCuoi  NVARCHAR(50) NOT NULL,
                            DoDaiKm   INT          NOT NULL CONSTRAINT CK_Tuyen_DoDai CHECK (DoDaiKm > 0),
                            CapDo     TINYINT      NOT NULL CONSTRAINT FK_Tuyen_DoPhucTap REFERENCES DoPhucTap(CapDo),
                            CONSTRAINT CK_Tuyen_DiemKhacNhau CHECK (DiemDau <> DiemCuoi),
                            CONSTRAINT UQ_Tuyen_DiemDauCuoi UNIQUE (DiemDau, DiemCuoi)
);

CREATE TABLE LoaiNgay (
                          MaLoaiNgay  VARCHAR(10)  NOT NULL CONSTRAINT PK_LoaiNgay PRIMARY KEY,
                          TenLoaiNgay NVARCHAR(50) NOT NULL CONSTRAINT UQ_LoaiNgay_Ten UNIQUE
);

CREATE TABLE LichNgay (
                          Ngay       DATE        NOT NULL CONSTRAINT PK_LichNgay PRIMARY KEY,
                          MaLoaiNgay VARCHAR(10) NOT NULL CONSTRAINT FK_LichNgay_LoaiNgay REFERENCES LoaiNgay(MaLoaiNgay)
);

CREATE TABLE BangGiaVe (
                           MaTuyen    CHAR(3)       NOT NULL CONSTRAINT FK_Gia_Tuyen REFERENCES TuyenDuong(MaTuyen),
                           MaLoaiNgay VARCHAR(10)   NOT NULL CONSTRAINT FK_Gia_LoaiNgay REFERENCES LoaiNgay(MaLoaiNgay),
                           GiaVe      DECIMAL(12,0) NOT NULL CONSTRAINT CK_Gia_GiaVe CHECK (GiaVe > 0),
                           CONSTRAINT PK_BangGiaVe PRIMARY KEY (MaTuyen, MaLoaiNgay)
);

CREATE TABLE ThamSo (
                        MaThamSo VARCHAR(30)    NOT NULL CONSTRAINT PK_ThamSo PRIMARY KEY,
                        GiaTri   DECIMAL(12,2)  NOT NULL,
                        MoTa     NVARCHAR(200)  NULL
);

-- 4.2 Nhóm tổ chức ---------------------------------------------------
CREATE TABLE ChiNhanh (
                          MaCN        CHAR(4)       NOT NULL CONSTRAINT PK_ChiNhanh PRIMARY KEY,
                          TenCN       NVARCHAR(100) NOT NULL CONSTRAINT UQ_ChiNhanh_Ten UNIQUE,
                          DiaChi      NVARCHAR(200) NOT NULL,
                          SoDienThoai VARCHAR(15)   NULL,
                          MaTruongCN  CHAR(6)       NULL      -- FK thêm sau khi có bảng NhanVien
);

CREATE TABLE NhanVien (
                          MaNV        CHAR(6)      NOT NULL CONSTRAINT PK_NhanVien PRIMARY KEY,
                          HoDem       NVARCHAR(50) NOT NULL,
                          Ten         NVARCHAR(20) NOT NULL,
                          ChucVu      VARCHAR(10)  NOT NULL CONSTRAINT CK_NV_ChucVu
                              CHECK (ChucVu IN ('BanVe','DieuHanh','KyThuat','QuanLy')),
                          SoDienThoai VARCHAR(15)  NULL,
                          MaCN        CHAR(4)      NOT NULL CONSTRAINT FK_NV_ChiNhanh REFERENCES ChiNhanh(MaCN)
);

-- Liên kết 1-1: mỗi chi nhánh 1 trưởng, mỗi người chỉ làm trưởng 1 chi nhánh
ALTER TABLE ChiNhanh ADD CONSTRAINT FK_CN_TruongCN
    FOREIGN KEY (MaTruongCN) REFERENCES NhanVien(MaNV);
CREATE UNIQUE INDEX UX_ChiNhanh_TruongCN ON ChiNhanh(MaTruongCN) WHERE MaTruongCN IS NOT NULL;

CREATE TABLE TaiXe (
                       MaTX       CHAR(6)       NOT NULL CONSTRAINT PK_TaiXe PRIMARY KEY,
                       HoDem      NVARCHAR(50)  NOT NULL,
                       Ten        NVARCHAR(20)  NOT NULL,
                       NgaySinh   DATE          NOT NULL,
                       CCCD       CHAR(12)      NOT NULL CONSTRAINT UQ_TX_CCCD UNIQUE,
                       SoGPLX     VARCHAR(12)   NOT NULL CONSTRAINT UQ_TX_GPLX UNIQUE,
                       HangGPLX   VARCHAR(2)    NOT NULL CONSTRAINT CK_TX_Hang CHECK (HangGPLX IN ('D','E','FC')),
                       SoNha      NVARCHAR(50)  NULL,
                       Phuong     NVARCHAR(50)  NULL,
                       Tinh       NVARCHAR(50)  NULL,
                       NgayVaoLam DATE          NOT NULL,
                       MaCN       CHAR(4)       NOT NULL CONSTRAINT FK_TX_ChiNhanh REFERENCES ChiNhanh(MaCN),
                       TrangThai  VARCHAR(10)   NOT NULL CONSTRAINT DF_TX_TrangThai DEFAULT 'DangLam'
                           CONSTRAINT CK_TX_TrangThai CHECK (TrangThai IN ('DangLam','NghiViec')),
                       CONSTRAINT CK_TX_Tuoi CHECK (NgaySinh <= DATEADD(YEAR, -21, CAST(GETDATE() AS DATE)))
);

CREATE TABLE TaiXe_SDT (        -- thuộc tính đa trị
                           MaTX        CHAR(6)     NOT NULL CONSTRAINT FK_SDT_TaiXe REFERENCES TaiXe(MaTX) ON DELETE CASCADE,
                           SoDienThoai VARCHAR(15) NOT NULL,
                           CONSTRAINT PK_TaiXe_SDT PRIMARY KEY (MaTX, SoDienThoai)
);

CREATE TABLE Xe (
                    MaXe         CHAR(5)     NOT NULL CONSTRAINT PK_Xe PRIMARY KEY,
                    BienSo       VARCHAR(12) NOT NULL CONSTRAINT UQ_Xe_BienSo UNIQUE,
                    MaLoaiXe     CHAR(4)     NOT NULL CONSTRAINT FK_Xe_LoaiXe REFERENCES LoaiXe(MaLoaiXe),
                    MaCN         CHAR(4)     NOT NULL CONSTRAINT FK_Xe_ChiNhanh REFERENCES ChiNhanh(MaCN),
                    NamSanXuat   INT         NULL CONSTRAINT CK_Xe_NamSX CHECK (NamSanXuat BETWEEN 2005 AND YEAR(GETDATE())),
                    NgayDuaVaoSD DATE        NOT NULL,
                    TrangThai    VARCHAR(10) NOT NULL CONSTRAINT DF_Xe_TrangThai DEFAULT 'HoatDong'
                        CONSTRAINT CK_Xe_TrangThai CHECK (TrangThai IN ('HoatDong','BaoDuong','NgungHD'))
);

-- 4.3 Nhóm vận hành --------------------------------------------------
CREATE TABLE ChuyenXe (
                          MaChuyen      CHAR(10)      NOT NULL CONSTRAINT PK_ChuyenXe PRIMARY KEY,
                          MaTuyen       CHAR(3)       NOT NULL CONSTRAINT FK_Chuyen_Tuyen REFERENCES TuyenDuong(MaTuyen),
                          MaXe          CHAR(5)       NOT NULL CONSTRAINT FK_Chuyen_Xe REFERENCES Xe(MaXe),
                          GioKhoiHanhDK DATETIME      NOT NULL,
                          GioDenDK      DATETIME      NOT NULL,
                          GioKhoiHanhTT DATETIME      NULL,
                          GioDenTT      DATETIME      NULL,
                          KmThucTe      INT           NULL CONSTRAINT CK_Chuyen_Km CHECK (KmThucTe > 0),
                          ChiPhiVanHanh DECIMAL(12,0) NOT NULL CONSTRAINT DF_Chuyen_ChiPhi DEFAULT 0
                              CONSTRAINT CK_Chuyen_ChiPhi CHECK (ChiPhiVanHanh >= 0),
                          TrangThai     VARCHAR(10)   NOT NULL CONSTRAINT DF_Chuyen_TrangThai DEFAULT 'KeHoach'
                              CONSTRAINT CK_Chuyen_TrangThai CHECK (TrangThai IN ('KeHoach','DangChay','HoanThanh','Huy')),
                          CONSTRAINT CK_Chuyen_GioDK CHECK (GioDenDK > GioKhoiHanhDK),
                          CONSTRAINT CK_Chuyen_GioTT CHECK (GioDenTT > GioKhoiHanhTT),
                          CONSTRAINT CK_Chuyen_MaFormat CHECK (MaChuyen LIKE 'C[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
                          CONSTRAINT UQ_Chuyen_XeGio UNIQUE (MaXe, GioKhoiHanhDK)   -- khóa ứng viên
);

CREATE TABLE PhanCong (          -- liên kết N-N Tài xế – Chuyến xe
                          MaChuyen CHAR(10)      NOT NULL CONSTRAINT FK_PC_Chuyen REFERENCES ChuyenXe(MaChuyen),
                          MaTX     CHAR(6)       NOT NULL CONSTRAINT FK_PC_TaiXe REFERENCES TaiXe(MaTX),
                          VaiTro   CHAR(3)       NOT NULL CONSTRAINT CK_PC_VaiTro CHECK (VaiTro IN ('LAI','PHU')),
                          ThuLao   DECIMAL(12,0) NOT NULL CONSTRAINT DF_PC_ThuLao DEFAULT 0
                              CONSTRAINT CK_PC_ThuLao CHECK (ThuLao >= 0),
                          CONSTRAINT PK_PhanCong PRIMARY KEY (MaChuyen, MaTX),
                          CONSTRAINT UQ_PC_ChuyenVaiTro UNIQUE (MaChuyen, VaiTro)   -- tối đa 1 lái, 1 phụ
);

CREATE TABLE HanhKhach (
                           MaHK        CHAR(8)       NOT NULL CONSTRAINT PK_HanhKhach PRIMARY KEY,
                           HoTen       NVARCHAR(100) NOT NULL,
                           SoDienThoai VARCHAR(15)   NOT NULL CONSTRAINT UQ_HK_SDT UNIQUE,
                           CCCD        CHAR(12)      NULL,
                           Email       VARCHAR(100)  NULL
);

CREATE TABLE Ve (
                    MaVe      VARCHAR(30)   NOT NULL CONSTRAINT PK_Ve PRIMARY KEY
                        CONSTRAINT DF_Ve_MaVe DEFAULT ('TMP' + LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 27)),
                    MaChuyen  CHAR(10)      NOT NULL CONSTRAINT FK_Ve_Chuyen REFERENCES ChuyenXe(MaChuyen),
                    SoGhe     INT           NOT NULL CONSTRAINT CK_Ve_SoGhe CHECK (SoGhe > 0),
                    LanBan    INT           NOT NULL CONSTRAINT DF_Ve_LanBan DEFAULT 0      -- 0 = chưa gán, TR02 gán ngay khi thêm
                        CONSTRAINT CK_Ve_LanBan CHECK (LanBan >= 0),
                    MaHK      CHAR(8)       NOT NULL CONSTRAINT FK_Ve_HanhKhach REFERENCES HanhKhach(MaHK),
                    MaNVBan   CHAR(6)       NOT NULL CONSTRAINT FK_Ve_NhanVien REFERENCES NhanVien(MaNV),
                    GiaVe     DECIMAL(12,0) NULL CONSTRAINT CK_Ve_GiaVe CHECK (GiaVe > 0),  -- TR02 tự điền nếu bỏ trống
                    NgayBan   DATETIME      NOT NULL CONSTRAINT DF_Ve_NgayBan DEFAULT GETDATE(),
                    TrangThai VARCHAR(6)    NOT NULL CONSTRAINT DF_Ve_TrangThai DEFAULT 'DaBan'
                        CONSTRAINT CK_Ve_TrangThai CHECK (TrangThai IN ('DaBan','DaHuy')),
                    CONSTRAINT UQ_Ve_ChuyenGheLan UNIQUE (MaChuyen, SoGhe, LanBan)   -- khóa gốc của thực thể yếu Vé
);
-- Không bán trùng ghế đang hiệu lực; ghế của vé đã hủy được bán lại
CREATE UNIQUE INDEX UX_Ve_GheDangBan ON Ve(MaChuyen, SoGhe) WHERE TrangThai = 'DaBan';

-- 4.4 Nhóm bảo dưỡng và lương ----------------------------------------
CREATE TABLE BaoDuong (
                          MaXe         CHAR(5)       NOT NULL CONSTRAINT FK_BD_Xe REFERENCES Xe(MaXe),
                          NgayBaoDuong DATE          NOT NULL,
                          NoiDung      NVARCHAR(200) NULL,
                          ChiPhi       DECIMAL(12,0) NULL CONSTRAINT CK_BD_ChiPhi CHECK (ChiPhi >= 0),
                          CONSTRAINT PK_BaoDuong PRIMARY KEY (MaXe, NgayBaoDuong)
);

CREATE TABLE DangKiem (
                          MaXe         CHAR(5)       NOT NULL CONSTRAINT FK_DK_Xe REFERENCES Xe(MaXe),
                          NgayDangKiem DATE          NOT NULL,
                          NgayHetHan   DATE          NOT NULL,
                          KetQua       VARCHAR(8)    NOT NULL CONSTRAINT CK_DK_KetQua CHECK (KetQua IN ('Dat','KhongDat')),
                          ChiPhi       DECIMAL(12,0) NULL CONSTRAINT CK_DK_ChiPhi CHECK (ChiPhi >= 0),
                          CONSTRAINT CK_DK_Ngay CHECK (NgayHetHan > NgayDangKiem),
                          CONSTRAINT PK_DangKiem PRIMARY KEY (MaXe, NgayDangKiem)
);

CREATE TABLE BangLuong (
                           MaTX        CHAR(6)       NOT NULL CONSTRAINT FK_BL_TaiXe REFERENCES TaiXe(MaTX),
                           Thang       CHAR(7)       NOT NULL CONSTRAINT CK_BL_Thang CHECK (Thang LIKE '[0-9][0-9][0-9][0-9]-[0-1][0-9]'),
                           SoChuyenLai INT           NOT NULL CONSTRAINT CK_BL_Lai CHECK (SoChuyenLai >= 0),
                           SoChuyenPhu INT           NOT NULL CONSTRAINT CK_BL_Phu CHECK (SoChuyenPhu >= 0),
                           TongLuong   DECIMAL(14,0) NOT NULL CONSTRAINT CK_BL_Tong CHECK (TongLuong >= 0),
                           NgayChot    DATETIME      NOT NULL CONSTRAINT DF_BL_NgayChot DEFAULT GETDATE(),
                           CONSTRAINT PK_BangLuong PRIMARY KEY (MaTX, Thang)
);
GO

