package com.example.quan_ly_xe.shared.routing;

import java.util.function.Supplier;

/**
 * Quản lý ngữ cảnh chi nhánh (MaCN) cho luồng xử lý hiện tại (ThreadLocal).
 * <p>
 * Thuộc phạm vi Sprint 0 (Người A phụ trách lớp định tuyến chi nhánh).
 */
public final class BranchContextHolder {

    private static final ThreadLocal<String> CURRENT_BRANCH = new ThreadLocal<>();

    private BranchContextHolder() {
    }

    public static String getBranch() {
        return CURRENT_BRANCH.get();
    }

    public static void setBranch(String branchCode) {
        if (branchCode != null && !branchCode.isBlank()) {
            CURRENT_BRANCH.set(branchCode.trim().toUpperCase());
        } else {
            CURRENT_BRANCH.remove();
        }
    }

    public static void clear() {
        CURRENT_BRANCH.remove();
    }

    /**
     * Tiện ích thực thi logic trong ngữ cảnh một chi nhánh cụ thể (dành cho truy vấn toàn chuỗi hoặc chéo chi nhánh).
     */
    public static <T> T runWithBranch(String branchCode, Supplier<T> action) {
        String previous = getBranch();
        try {
            setBranch(branchCode);
            return action.get();
        } finally {
            setBranch(previous);
        }
    }

    public static void runWithBranch(String branchCode, Runnable action) {
        runWithBranch(branchCode, () -> {
            action.run();
            return null;
        });
    }
}

