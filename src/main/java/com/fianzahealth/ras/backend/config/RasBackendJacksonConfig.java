package com.fianzahealth.ras.backend.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Spring Boot 4 ships Jackson 3 (tools.jackson.databind.json.JsonMapper) as
 * the auto-configured JSON mapper, but reconer + ras-analyzer code paths
 * autowire the legacy Jackson 2 com.fasterxml.jackson.databind.ObjectMapper
 * directly (e.g. reconer.service.report.ReportConfigHandler). Each peer module
 * used to declare its own @Bean for this; ras-analyzer's lived inside its
 * DslConfig which is excluded in ras-backend, and reconer's was removed when
 * dropping @EnableWebMvc / @Primary. Re-provide a single instance here.
 */
@Configuration
public class RasBackendJacksonConfig {

    @Bean
    public ObjectMapper jackson2ObjectMapper() {
        return new ObjectMapper();
    }
}
