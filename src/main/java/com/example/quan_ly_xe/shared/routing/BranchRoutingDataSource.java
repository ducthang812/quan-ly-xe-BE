package com.example.quan_ly_xe.shared.routing;

import org.springframework.jdbc.datasource.lookup.AbstractRoutingDataSource;

/**
 * DataSource tự động định tuyến kết nối tới database của chi nhánh tương ứng
 * (Trụ sở Hà Nội CN01, Đà Nẵng CN02, TP.HCM CN03).
 */
public class BranchRoutingDataSource extends AbstractRoutingDataSource {

    @Override
    protected Object determineCurrentLookupKey() {
        return BranchContextHolder.getBranch();
    }
}

