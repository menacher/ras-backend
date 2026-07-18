package com.fianzahealth.ras.backend;

import com.fianzahealth.ras.backend.client.InProcessAnalyzerClient;
import com.fianzahealth.ras.backend.client.InProcessReconerClient;
import com.fianzahealth.ras.backend.client.InProcessX12erClient;
import com.fianzahealth.ras.tenant.TenantContext;
import org.jooq.DSLContext;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.BindMode;
import org.testcontainers.containers.PostgreSQLContainer;

import java.util.Map;

import static com.fianzahealth.ras.jooq.Tables.NOTIFICATION_ALLOWED_DOMAIN;
import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * Boots the full bundled context (ras-api + reconer + x12er + ras-analyzer) against a
 * schema-seeded Postgres, exactly as it starts at a customer install.
 *
 * <p>This exists to catch bundled-classpath mismatches at build time. ras-backend compiles
 * even when the library jars it aggregates disagree about shared dependency versions,
 * because its own sources barely touch them — the breakage only appears when the context
 * is refreshed. Concretely: on 2026-07-18 the hamaspik deploy died on startup with
 * {@code NoClassDefFoundError: NotificationAllowedDomain} because the parent pom still
 * pinned ras-jooq 1.4.0-SNAPSHOT while the bundled ras-api needed 1.5.0-SNAPSHOT.
 * This test fails in that state.
 *
 * <p>{@code useMainMethod = ALWAYS} is load-bearing: {@link RasBackendApplication#main}
 * installs {@code FullyQualifiedAnnotationBeanNameGenerator}, and without it the ~14
 * cross-module short-name collisions are silently resolved by
 * {@code allow-bean-definition-overriding} instead of coexisting as they do in production.
 *
 * <p>{@code ras_v3.sql} is a snapshot of ras-api's {@code src/test/resources/ras_v3.sql}
 * (ras-api does not publish a test-jar). Refresh the copy when a schema change breaks
 * this test.
 */
@SpringBootTest(
        useMainMethod = SpringBootTest.UseMainMethod.ALWAYS,
        properties = {
                // Both halves of the bundle-wide kill-switch (see application.yml): keeps FTP
                // pollers and report crons from racing the assertions on missing /data paths.
                "ras-api.scheduling.enabled=false",
                "ras-analyzer.scheduling.enabled=false",
                "management.otlp.metrics.export.enabled=false"
        })
class RasBackendContextLoadTest {

    private static final PostgreSQLContainer<?> PG = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("ras")
            .withUsername("ras")
            .withPassword("12345")
            .withClasspathResourceMapping("ras_v3.sql",
                    "/docker-entrypoint-initdb.d/init-postgres.sql", BindMode.READ_ONLY)
            .withTmpFs(Map.of("/var/lib/postgresql/data", "rw"))
            .withCommand("postgres", "-c", "fsync=off", "-c", "synchronous_commit=off",
                    "-c", "full_page_writes=off");

    static {
        PG.start();
    }

    @DynamicPropertySource
    static void databaseProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", PG::getJdbcUrl);
        registry.add("spring.datasource.username", PG::getUsername);
        registry.add("spring.datasource.password", PG::getPassword);
    }

    @BeforeAll
    static void initTenant() {
        TenantContext.setTenantId("public");
        TenantContext.setPlanName("PLAN_A");
    }

    @AfterAll
    static void clearTenant() {
        TenantContext.clear();
    }

    @Autowired
    private ApplicationContext context;

    @Autowired
    private DSLContext dslContext;

    /**
     * Round-trips through a table that is BOTH in the generated jooq schema jar AND in
     * DslConfig's public-only mapped-table list — the exact class whose absence caused the
     * 2026-07-18 startup failure. Proves datasource, tenant connection provider, jOOQ
     * configuration, and render mapping against the live schema in one query.
     */
    @Test
    void jooqRoundTripsThroughMappedGeneratedTable() {
        assertNotNull(dslContext.selectCount().from(NOTIFICATION_ALLOWED_DOMAIN).fetchOne());
    }

    /** The bundled profile (production default) must wire the in-process peer clients. */
    @Test
    void bundledProfileWiresInProcessClients() {
        assertNotNull(context.getBean(InProcessReconerClient.class));
        assertNotNull(context.getBean(InProcessAnalyzerClient.class));
        assertNotNull(context.getBean(InProcessX12erClient.class));
    }
}
