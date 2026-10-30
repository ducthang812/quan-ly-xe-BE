/*
 Module B - smoke test thủ công.
 CHƯA CHẠY ĐƯỢC Ở MÁY DEV. Chỉ chạy trên SQL Server thật sau khi đã áp dụng
 migration module A, stub/module C và migration B.

 Điều kiện dữ liệu: thay các mã dưới đây bằng 1 tuyến có bảng giá cho ngày test,
 2 xe hoạt động đủ điều kiện, 4 tài xế đang làm việc, 1 tài xế nghỉ việc và
 1 nhân viên bán vé hợp lệ.
 Nên chạy trên database test có thể xóa sau khi thử; script chủ ý giữ dữ liệu thành công
 để người chạy đối chiếu kết quả.
*/
SET NOCOUNT ON;

DECLARE @MaTuyen CHAR(3) = 'T01';
DECLARE @Xe1 CHAR(5) = 'X0001', @Xe2 CHAR(5) = 'X0002';
DECLARE @Lai1 CHAR(6) = 'TX0001', @Phu1 CHAR(6) = 'TX0002';
DECLARE @Lai2 CHAR(6) = 'TX0003', @Phu2 CHAR(6) = 'TX0004';
DECLARE @NghiViec CHAR(6) = 'TX0005';
DECLARE @NhanVien CHAR(6) = 'NV0001';
DECLARE @Chuyen1 CHAR(10) = 'C301026901', @Chuyen2 CHAR(10) = 'C301026902';
DECLARE @BatDau DATETIME = '2030-10-26T08:00:00', @KetThuc DATETIME = '2030-10-26T12:00:00';
DECLARE @MaVe VARCHAR(30);

-- 1. Tạo chuyến hợp lệ. Mong đợi: 1 dòng, MaChuyen = C301026901.
EXEC dbo.sp_TaoChuyenVaPhanCong @MaTuyen, @Xe1, @BatDau, @KetThuc,
    @Lai1, @Phu1, @Chuyen1;

-- 2. Tạo chuyến dùng cùng xe và giao thời gian. Mong đợi: THROW 50402 -> E16.
BEGIN TRY
    EXEC dbo.sp_TaoChuyenVaPhanCong @MaTuyen, @Xe1, '2030-10-26T09:00:00',
        '2030-10-26T13:00:00', @Lai2, @Phu2, 'C301026910';
    THROW 59999, N'FAIL: thiếu lỗi E16', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 3. Phân công tài xế nghỉ việc. Mong đợi: THROW 50301|TX0005 -> DRIVER_NOT_ACTIVE.
BEGIN TRY
    EXEC dbo.sp_TaoChuyenVaPhanCong @MaTuyen, @Xe2, '2030-10-27T08:00:00',
        '2030-10-27T12:00:00', @NghiViec, @Phu2, 'C301027901';
    THROW 59999, N'FAIL: thiếu lỗi DRIVER_NOT_ACTIVE', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 4. Tạo chuyến xe khác nhưng dùng lại TX0001 trong giờ giao nhau.
-- Mong đợi: THROW 50302 với message 50302|TX0001 -> E19.
BEGIN TRY
    EXEC dbo.sp_TaoChuyenVaPhanCong @MaTuyen, @Xe2, '2030-10-26T09:00:00',
        '2030-10-26T13:00:00', @Lai1, @Phu2, @Chuyen2;
    THROW 59999, N'FAIL: thiếu lỗi E19', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 5. Bán ghế 3. Mong đợi: 1 dòng; LanBan=1, MaVe theo F07 và GiaVe khác NULL.
EXEC dbo.sp_BanVe @Chuyen1, 3, N'Khách smoke test', '0901234567', NULL, NULL, @NhanVien;
SELECT @MaVe = MaVe FROM dbo.Ve
 WHERE MaChuyen=@Chuyen1 AND SoGhe=3 AND TrangThai='DaBan';

-- 6. Bán lại ghế 3 khi vé còn hiệu lực. Mong đợi: THROW 51003 -> E24.
BEGIN TRY
    EXEC dbo.sp_BanVe @Chuyen1, 3, N'Khách khác', '0901234568', NULL, NULL, @NhanVien;
    THROW 59999, N'FAIL: thiếu lỗi E24', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 7. Hủy vé rồi bán lại ghế 3. Mong đợi: vé mới LanBan=2, mã kết thúc bằng -03-2 (F07).
EXEC dbo.sp_HuyVe @MaVe;
-- Vé đã hủy không được hủy lần hai. Mong đợi: THROW 54002 -> TICKET_ALREADY_CANCELLED.
BEGIN TRY
    EXEC dbo.sp_HuyVe @MaVe;
    THROW 59999, N'FAIL: thiếu lỗi TICKET_ALREADY_CANCELLED', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;
EXEC dbo.sp_BanVe @Chuyen1, 3, N'Khách smoke test', '0901234567', NULL, NULL, @NhanVien;
SELECT @MaVe = MaVe FROM dbo.Ve
 WHERE MaChuyen=@Chuyen1 AND SoGhe=3 AND TrangThai='DaBan';
SELECT MaVe, LanBan FROM dbo.Ve WHERE MaChuyen=@Chuyen1 AND SoGhe=3 ORDER BY LanBan;

-- 7b. Lấy bảng vé theo chuyến. Mong đợi: 2 dòng ghế 3, gồm DaHuy lần 1 và DaBan lần 2,
-- đầy đủ khách, SĐT, giá, ngày bán.
EXEC dbo.sp_LayDanhSachVeTheoChuyen @Chuyen1;

-- 8a. Bán ghế tài xế 1. Mong đợi: THROW 50101 -> E26.
BEGIN TRY
    EXEC dbo.sp_BanVe @Chuyen1, 1, N'Khách lỗi', '0901234569', NULL, NULL, @NhanVien;
    THROW 59999, N'FAIL: thiếu lỗi E26 cho ghế 1', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 8b. Bán ghế vượt SoGhe của xe (999). Mong đợi: THROW 50101 -> E26.
BEGIN TRY
    EXEC dbo.sp_BanVe @Chuyen1, 999, N'Khách lỗi', '0901234569', NULL, NULL, @NhanVien;
    THROW 59999, N'FAIL: thiếu lỗi E26 cho ghế vượt chỗ', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 9. Kết thúc với km=0. Mong đợi: THROW 50601 -> E21, chuyến chưa HoanThanh.
BEGIN TRY
    EXEC dbo.sp_KetThucChuyen @Chuyen1, NULL, NULL, 0, 100000;
    THROW 59999, N'FAIL: thiếu lỗi E21', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 10. Kết thúc hợp lệ. Mong đợi: 1 dòng MaChuyen, trạng thái HoanThanh.
EXEC dbo.sp_KetThucChuyen @Chuyen1, NULL, NULL, 200, 100000;
SELECT MaChuyen, TrangThai, KmThucTe FROM dbo.ChuyenXe WHERE MaChuyen=@Chuyen1;

-- 11. Vé đang bán của chuyến đã hoàn thành không được hủy (SRS 7.3).
BEGIN TRY
    EXEC dbo.sp_HuyVe @MaVe;
    THROW 59999, N'FAIL: thiếu lỗi TRIP_NOT_CANCELLABLE khi hủy vé', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 12. Hủy chuyến đã HoanThanh. Mong đợi: THROW 54001 -> TRIP_NOT_CANCELLABLE.
BEGIN TRY
    EXEC dbo.sp_HuyChuyen @Chuyen1;
    THROW 59999, N'FAIL: thiếu lỗi TRIP_NOT_CANCELLABLE', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;

-- 13. Mã cuối ngày đã đạt 999 thì không được sinh mã tiếp theo.
EXEC dbo.sp_TaoChuyenVaPhanCong @MaTuyen, @Xe2, '2030-10-26T14:00:00',
    '2030-10-26T16:00:00', @Lai2, @Phu2, 'C301026999';
-- 13a. Chuyến tồn tại nhưng chưa có vé. Mong đợi: 0 dòng.
EXEC dbo.sp_LayDanhSachVeTheoChuyen 'C301026999';
BEGIN TRY
    EXEC dbo.sp_TaoChuyenVaPhanCong @MaTuyen, @Xe2, '2030-10-26T18:00:00',
        '2030-10-26T20:00:00', @Lai2, @Phu2, NULL;
    THROW 59999, N'FAIL: thiếu lỗi TRIP_CODE_EXHAUSTED', 1;
END TRY BEGIN CATCH SELECT ERROR_NUMBER() errorNumber, ERROR_MESSAGE() errorMessage; END CATCH;
