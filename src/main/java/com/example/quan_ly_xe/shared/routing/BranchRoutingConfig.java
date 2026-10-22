package com.example.quan_ly_xe.shared.routing;

import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

/**
 * Cấu hình cụm DataSource định tuyến 3 chi nhánh (Người A phụ trách).
 */
@Configuration
public class BranchRoutingConfig {

    private static final Logger log = LoggerFactory.getLogger(BranchRoutingConfig.class);

    @Value("${app.datasource.branches.CN01.url:${spring.datasource.url}}")
    private String hnUrl;

    @Value("${app.datasource.branches.CN01.username:${spring.datasource.username:sa}}")
    private String hnUser;

    @Value("${app.datasource.branches.CN01.password:${spring.datasource.password:Abc@123456}}")
    private String hnPass;

    @Value("${app.datasource.branches.CN02.url:jdbc:sqlserver://localhost:1434;databaseName=QLXeKhach_DN;encrypt=true;trustServerCertificate=true}")
    private String dnUrl;

    @Value("${app.datasource.branches.CN02.username:sa}")
    private String dnUser;

    @Value("${app.datasource.branches.CN02.password:Abc@123456}")
    private String dnPass;

    @Value("${app.datasource.branches.CN03.url:jdbc:sqlserver://localhost:1435;databaseName=QLXeKhach_HCM;encrypt=true;trustServerCertificate=true}")
    private String hcmUrl;

    @Value("${app.datasource.branches.CN03.username:sa}")
    private String hcmUser;

    @Value("${app.datasource.branches.CN03.password:Abc@123456}")
    private String hcmPass;

    private DataSource createDataSource(String url, String user, String pass, String poolName) {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl(url);
        ds.setUsername(user);
        ds.setPassword(pass);
        ds.setDriverClassName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        ds.setPoolName(poolName);
        ds.setMaximumPoolSize(10);
        ds.setMinimumIdle(2);
        ds.setConnectionTimeout(5000);
        return ds;
    }

    @Bean
    @Primary
    public DataSource dataSource() {
        log.info("Khởi tạo BranchRoutingDataSource cho 3 chi nhánh (HN: CN01, DN: CN02, HCM: CN03)");

        DataSource hnDataSource = createDataSource(hnUrl, hnUser, hnPass, "HikariPool-HN");
        DataSource dnDataSource = createDataSource(dnUrl, dnUser, dnPass, "HikariPool-DN");
        DataSource hcmDataSource = createDataSource(hcmUrl, hcmUser, hcmPass, "HikariPool-HCM");

        Map<Object, Object> targetDataSources = new HashMap<>();
        targetDataSources.put("CN01", hnDataSource);
        targetDataSources.put("CN02", dnDataSource);
        targetDataSources.put("CN03", hcmDataSource);

        BranchRoutingDataSource routingDataSource = new BranchRoutingDataSource();
        routingDataSource.setDefaultTargetDataSource(hnDataSource);
        routingDataSource.setTargetDataSources(targetDataSources);
        routingDataSource.afterPropertiesSet();

        return routingDataSource;
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}

