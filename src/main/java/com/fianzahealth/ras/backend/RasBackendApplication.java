package com.fianzahealth.ras.backend;

import com.fianzahealth.rasapi.RasApiApplication;
import com.fianzahealth.ras.reconer.ReconerApplication;
import com.fianzahealth.x12er.X12erApplication;
import com.medvand.rasanalyzer.RasAnalyzerApplication;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.context.annotation.FullyQualifiedAnnotationBeanNameGenerator;
import org.springframework.retry.annotation.EnableRetry;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Single Spring Boot entrypoint that aggregates the four ras-* services into one
 * JVM. The four base packages are component-scanned together; the original
 * @SpringBootApplication classes are excluded from the scan so we don't end up
 * with four nested auto-configuration roots competing with each other.
 *
 * Controllers from each module are re-prefixed at request mapping time by
 * RasBackendWebConfig — this preserves the existing /ras-api/.., /reconer/..,
 * /x12er/.., /ras-analyzer/.. URL shape without rewriting controllers.
 */
@SpringBootConfiguration
@EnableAutoConfiguration
// We unpack @SpringBootApplication into its three constituent annotations so
// the implicit @ComponentScan it carries (with default short-name beans) does
// not run alongside our explicit @ComponentScan below — that double-scan
// otherwise registers every @Component twice (once FQN-named, once short-named).
@ComponentScan(
        basePackages = {
                "com.fianzahealth.rasapi",
                "com.fianzahealth.ras.reconer",
                "com.fianzahealth.x12er",
                "com.medvand.rasanalyzer",
                "com.fianzahealth.ras.backend"
        },
        // Names beans by FQN so e.g. com.fianzahealth.ras.reconer.AdhocReportController
        // and com.fianzahealth.rasapi.controller.AdhocReportController don't collide on
        // the auto-derived short name "adhocReportController".
        nameGenerator = FullyQualifiedAnnotationBeanNameGenerator.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {
                        // Don't boot four nested @SpringBootApplication contexts.
                        RasApiApplication.class,
                        ReconerApplication.class,
                        X12erApplication.class,
                        RasAnalyzerApplication.class,
                        // Three DslConfigs all define @Bean connectionProvider /
                        // jooqDefaultConfigurationCustomizer; ras-api's variant is
                        // the canonical one (tx-aware caching, FastRecordMapper /
                        // FastRecordUnmapper). The other two are superseded.
                        com.fianzahealth.ras.reconer.config.DslConfig.class,
                        com.medvand.rasanalyzer.config.DslConfig.class,
                        // Both reconer and ras-analyzer implement AsyncConfigurer.
                        // Spring permits only one such bean; ras-api uses the default
                        // executor (@EnableAsync without custom configurer) so we
                        // drop both peer module configs and fall back to the default
                        // Spring async executor. KNOWN LIMITATION: reconer's
                        // TenantAwareTaskDecorator that propagates TenantContext into
                        // @Async tasks is lost — restore via a backend-side
                        // AsyncConfigurer if any feature actually depends on it.
                        com.fianzahealth.ras.reconer.config.AsyncConfig.class,
                        com.medvand.rasanalyzer.config.AsyncConfig.class
                }
        )
)
@EnableTransactionManagement
@EnableRetry
public class RasBackendApplication {

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(RasBackendApplication.class);
        // Force FQN bean naming throughout the context, including for @ComponentScan
        // annotations on imported @Configuration classes (e.g. ras-api's AppConfig).
        // Otherwise the @Component default short names collide across modules (~14
        // class-name overlaps including AdhocReportController, MemberAuditService,
        // FilePathConfigProperties, etc.).
        app.setBeanNameGenerator(new FullyQualifiedAnnotationBeanNameGenerator());
        app.run(args);
    }
}
