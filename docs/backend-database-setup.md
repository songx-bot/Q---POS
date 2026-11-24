# Start the Backend and Connect MySQL

This guide covers local development on Windows for the Spring Boot backend in this repository.

## Current setup

- Backend project: repository root (`pom.xml`)
- Runtime: Java 17
- MySQL Windows service: `MySQL80`
- MySQL version verified during setup: 8.0.46
- Database: `qpos_db`
- Default database user: `root` (overridable with `QPOS_DB_USER`)
- Default JDBC address: `jdbc:mysql://localhost:3306/qpos_db`
- Full POS schema: `db/schema.sql`
- Spring Boot health route: `http://localhost:8080/api/v1/health`

The JDBC URL and account settings can be overridden with `QPOS_DB_URL`, `QPOS_DB_USER`, and `QPOS_DB_PASSWORD`. The password should be supplied through the process environment, not saved in this document or committed to source control. Configuration is in `src/main/resources/application.properties`.

## Prerequisites

1. Install a Java 17 JDK and confirm the active Java runtime:

   ```cmd
   java -version
   ```

   The project compiler setting in `pom.xml` is `17`. Spring Boot 4 requires Java 17 or newer; the project was verified with Temurin 17.

2. Install MySQL Server 8 and ensure the `MySQL80` Windows service exists.
3. Use an account that can start the MySQL service. Service operations may require an Administrator terminal.

## 1. Start MySQL

In an Administrator Command Prompt, run:

```cmd
net start MySQL80
```

Expected result:

```text
The MySQL80 service was started successfully.
```

The service can be stopped with `net stop MySQL80` when local development is finished.

## 2. Create the database schema

On a fresh local database, load the repository's full schema. In Command Prompt, connect with the MySQL client; `-p` prompts for the password without echoing it:

```cmd
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
```

At the `mysql>` prompt, run the schema file using forward slashes in its path:

```sql
SOURCE C:/Users/Latitude/Downloads/pom/db/schema.sql
```

The script creates and selects `qpos_db`, then creates the POS tables. Confirm tables exist with:

```sql
SHOW TABLES;
```

Exit the client with:

```sql
exit
```

Run the schema script for initial database setup. Do not rerun schema changes against data you need to preserve without first taking a backup and reviewing the SQL. Spring Boot's `spring.jpa.hibernate.ddl-auto=update` separately creates or updates the two JPA-mapped tables (`products` and `categories`); it does not replace the complete POS schema in `db/schema.sql`.

## 3. Start Spring Boot

Run the backend from **PowerShell** in the repository root. The secure prompt keeps the password out of command history and does not display it as you type. The environment variable is removed after the app stops.

If the current prompt looks like `C:\Users\...>`, it is Command Prompt. Type `powershell` and press Enter first. Continue only after the prompt changes to `PS C:\Users\Latitude\Downloads\pom>`.

Paste this command into PowerShell:

```powershell
$secure = Read-Host "MySQL root password" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $env:QPOS_DB_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    .\mvnw.cmd spring-boot:run
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Item Env:QPOS_DB_PASSWORD -ErrorAction SilentlyContinue
}
```

Keep this PowerShell window open while using the API. Successful startup includes log messages similar to:

```text
HikariPool-1 - Start completed.
Tomcat started on port 8080 (http)
Started EcommercePosApplication
```

The Hibernate database information should show the JDBC URL for `qpos_db` and the MySQL server version.

## 4. Verify the backend

In a separate Command Prompt or PowerShell window, run:

```cmd
curl.exe -i http://127.0.0.1:8080/api/v1/health
```

Expected response: HTTP `200` with JSON containing `"status":"UP"`.

## Troubleshooting

### `'$secure' is not recognized`

The PowerShell script was pasted into Command Prompt. Start PowerShell by typing `powershell`, confirm the prompt begins with `PS`, then paste the script.

### `Unknown database 'qpos_db'`

The MySQL server is reachable, but the database is not created. In the MySQL client, load `db/schema.sql` using the `SOURCE` command in step 2.

### `Connection refused` or no connection on port 3306

Check the service with `sc query MySQL80`. If stopped, use an Administrator Command Prompt and run `net start MySQL80`.

### `Access denied for user`

Check that the password entered at the hidden PowerShell prompt matches the MySQL account. Do not paste passwords into chat or save them in `application.properties`.

### `release version 25 not supported`

The active JDK is older than the compiler release setting. Check `java -version`; this project is configured for Java 17.

### `UnsupportedClassVersionError` mentioning class version 69 and version 61

This indicates Java 25 class files are being run by Java 17. Clear stale generated output from PowerShell and rebuild:

```powershell
.\mvnw.cmd clean
```

Then rerun the secure startup command in step 3.

## Security note

If a database password was pasted into chat, treat it as exposed and change it to a new password. Never put the password in this guide, source files, or a committed `.env` file.

## Verification record

On 2026-11-24, the backend connected to MySQL 8.0.46, started with Java 17 on port 8080, and returned HTTP 200 from `/api/v1/health`. This verifies local startup and connectivity for that run; it is not a production deployment check.
