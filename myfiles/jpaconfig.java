package com.instana.robotshop.shipping;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import javax.sql.DataSource;

import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Bean;

@Configuration
public class JpaConfig {

    private static final Logger logger = LoggerFactory.getLogger(JpaConfig.class);

    @Bean
    public DataSource getDataSource() {

        String host = System.getenv().getOrDefault(
                "MYSQL_HOST",
                "mysql.data-space.svc.cluster.local"
        );

        String port = System.getenv().getOrDefault("MYSQL_PORT", "3306");
        String database = System.getenv().getOrDefault("MYSQL_DATABASE", "cities");
        String username = System.getenv().getOrDefault("MYSQL_USER", "shipping");
        String password = System.getenv().getOrDefault("MYSQL_PASSWORD", "secret");

        String jdbcUrl = String.format(
                "jdbc:mysql://%s:%s/%s?useSSL=false&allowPublicKeyRetrieval=true&autoReconnect=true",
                host, port, database
        );

        logger.info("Using JDBC URL: {}", jdbcUrl);

        return DataSourceBuilder.create()
                .driverClassName("com.mysql.cj.jdbc.Driver")
                .url(jdbcUrl)
                .username(username)
                .password(password)
                .build();
    }
}
