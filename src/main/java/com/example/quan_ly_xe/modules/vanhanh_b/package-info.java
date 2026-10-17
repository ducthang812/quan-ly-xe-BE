/**
 * Module B – Chuyến và vé.
 * <p>
 * Chủ sở hữu: <b>Người B</b>. Use case UC-008 đến UC-013.
 * Bảng sở hữu (ghi DDL): ChuyenXe, PhanCong, HanhKhach, Ve. Trigger TR01–TR06,
 * thủ tục sp_TaoChuyenVaPhanCong, sp_KetThucChuyen, sp_BanVe.
 * <p>
 * Phụ thuộc đọc: gọi hàm "kiểm tra xe đủ điều kiện chạy" của C (giao tiếp #2);
 * đọc danh mục tuyến/giá/tài xế của A. B cũng giữ việc chung: bộ ánh xạ lỗi
 * E01–E32 (đã đặt ở {@code common.exception}) và khung giao dịch.
 * Đặt code của B trong các package con tại đây.
 */
package com.example.quan_ly_xe.modules.vanhanh_b;
