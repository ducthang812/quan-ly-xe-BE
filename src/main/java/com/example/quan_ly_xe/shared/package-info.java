/**
 * Hợp đồng dùng chung giữa các module (chốt ở Sprint 0, sửa phải báo bên dùng).
 * <p>
 * Nơi đặt các giao diện liên module một chiều (bên cung cấp → bên dùng), ví dụ:
 * <ul>
 *   <li>A: lớp định tuyến theo chi nhánh cho cụm SQL Server 3 nút, truy vấn gộp toàn chuỗi;</li>
 *   <li>C → B: hàm kiểm tra xe đủ điều kiện chạy (trả mã 50401/50403/50404);</li>
 *   <li>API danh mục dùng chung (chi nhánh, tuyến, tài xế, xe, loại xe, tham số).</li>
 * </ul>
 * Quy ước: chỉ khai báo <b>giao diện</b> ở đây; mỗi module tự hiện thực trong
 * package của mình. Phần ánh xạ lỗi E01–E32 nằm ở {@code common.exception}.
 */
package com.example.quan_ly_xe.shared;
