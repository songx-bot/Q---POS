package edu.posgroup4.qposplusplus;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * QPOS++ Database Schema Initializer.
 * Applies schema.sql on first run; safely handles existing tables, duplicate indexes,
 * and existing foreign keys so subsequent runs are idempotent.
 */
public final class SchemaInitializer {
    private static final Pattern FOREIGN_KEY_DDL = Pattern.compile(
            "ALTER\\s+TABLE\\s+(\\w+)\\s+ADD\\s+CONSTRAINT\\s+(\\w+)\\s+FOREIGN\\s+KEY", Pattern.CASE_INSENSITIVE);

    private SchemaInitializer() {}

    public static void initialize() throws IOException, SQLException {
        Database database = new Database();
        String schema = loadSchemaSql();

        try (Connection connection = database.connect(); Statement statement = connection.createStatement()) {
            for (String command : schema.split(";")) {
                String sql = command.trim();
                if (sql.isEmpty()) continue;

                Matcher foreignKey = FOREIGN_KEY_DDL.matcher(sql);
                if (foreignKey.find() && foreignKeyExists(connection, foreignKey.group(1), foreignKey.group(2))) {
                    continue;
                }

                try {
                    statement.execute(sql);
                } catch (SQLException ex) {
                    // 1061: Duplicate key name / index already exists (MySQL lacks CREATE INDEX IF NOT EXISTS)
                    // 1050: Table already exists
                    if (ex.getErrorCode() == 1061 || ex.getErrorCode() == 1050) {
                        continue;
                    }
                    throw ex;
                }
            }
        }
    }

    private static String loadSchemaSql() throws IOException {
        // 1. Try reading from classpath (JAR or resources root)
        try (InputStream input = SchemaInitializer.class.getResourceAsStream("/db/schema.sql")) {
            if (input != null) {
                return new String(input.readAllBytes(), StandardCharsets.UTF_8);
            }
        }

        // 2. Fall back to relative file paths on disk
        Path[] candidatePaths = new Path[] {
            Path.of("src", "main", "resources", "db", "schema.sql"),
            Path.of("db", "schema.sql"),
            Path.of("..", "db", "schema.sql"),
            Path.of("POS--4", "db", "schema.sql"),
            Path.of("POS--4", "src", "main", "resources", "db", "schema.sql")
        };

        for (Path path : candidatePaths) {
            if (Files.exists(path)) {
                return Files.readString(path, StandardCharsets.UTF_8);
            }
        }

        throw new IOException("QPOS++ schema.sql was not found on the classpath (/db/schema.sql) or file search paths.");
    }

    private static boolean foreignKeyExists(Connection connection, String table, String constraint)
            throws SQLException {
        String query = "SELECT 1 FROM information_schema.TABLE_CONSTRAINTS " +
                "WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = ? AND CONSTRAINT_NAME = ? " +
                "AND CONSTRAINT_TYPE = 'FOREIGN KEY'";
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setString(1, table);
            statement.setString(2, constraint);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next();
            }
        }
    }
}
