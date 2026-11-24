package edu.posgroup4.qposplusplus;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * QPOS++ Database Connection Manager.
 * Connects to the local MySQL database for QPOS++ using environment variables
 * or defaults configured for MySQL 8.0+.
 */
public final class Database {
    private final String url;
    private final String username;
    private final String password;

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ignored) {
            // Driver will be discovered automatically via JDBC SPI if present on classpath
        }
    }

    public Database() {
        String dbName = setting("QPOS_DB_NAME", "qpos_db");
        this.url = setting("QPOS_DB_URL", "jdbc:mysql://localhost:3306/" + dbName + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC");
        this.username = setting("QPOS_DB_USER", "root");
        this.password = setting("QPOS_DB_PASSWORD", "");
    }

    public Connection connect() throws SQLException {
        return DriverManager.getConnection(url, username, password);
    }

    private static String setting(String name, String defaultValue) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? defaultValue : value;
    }
}
