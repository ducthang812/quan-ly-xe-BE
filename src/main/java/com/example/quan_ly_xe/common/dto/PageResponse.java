package com.example.quan_ly_xe.common.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Kết quả phân trang gọn, tách client khỏi kiểu {@link Page} của Spring Data.
 * Dùng chung cho các danh sách dài (danh sách chuyến, vé, xe, báo cáo...).
 *
 * @param <T> kiểu phần tử
 */
@Getter
@AllArgsConstructor
public class PageResponse<T> {

    private final List<T> items;
    private final int page;
    private final int size;
    private final long totalItems;
    private final int totalPages;
    private final boolean last;

    public static <T> PageResponse<T> from(Page<T> page) {
        return new PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.isLast()
        );
    }
}
