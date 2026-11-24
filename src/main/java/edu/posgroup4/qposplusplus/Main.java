package edu.posgroup4.qposplusplus;

/**
 * QPOS++ Main Entry Point.
 * Verifies the database connection and ensures all QPOS++ tables and constraints exist.
 */
public final class Main {
    public static void main(String[] args) throws Exception {
        System.out.println("Initializing QPOS++ database schema...");
        SchemaInitializer.initialize();
        System.out.println("QPOS++ MySQL schema is ready and verified in the database.");
    }
}
