package com.example.quan_ly_xe.common.exception;

/**
 * Lối tắt cho trường hợp không tìm thấy bản ghi theo khóa (trả HTTP 404).
 *
 * <pre>{@code
 * xeRepository.findById(maXe)
 *     .orElseThrow(() -> new ResourceNotFoundException("xe", maXe));
 * }</pre>
 */
public class ResourceNotFoundException extends AppException {

    public ResourceNotFoundException(String tenTaiNguyen, Object khoa) {
        super(ErrorCode.NOT_FOUND, tenTaiNguyen + " '" + khoa + "'");
    }

    public ResourceNotFoundException(String moTa) {
        super(ErrorCode.NOT_FOUND, moTa);
    }
}
