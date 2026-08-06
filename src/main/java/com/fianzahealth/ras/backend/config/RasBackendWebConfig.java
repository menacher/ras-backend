package com.fianzahealth.ras.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Re-prefixes controllers from each peer module at the dispatcher level so the
 * existing inter-service URLs (which already include /ras-api, /reconer,
 * /x12er, /ras-analyzer in their configured paths) continue to route correctly
 * when everything lives in one Spring Boot process on port 8080.
 *
 * Without these prefixes there would be path collisions — both reconer and
 * ras-analyzer mount @RequestMapping("/payment") and @RequestMapping("/files")
 * style controllers that previously relied on server.servlet.context-path for
 * namespacing.
 */
@Configuration
public class RasBackendWebConfig implements WebMvcConfigurer {

    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        // ras-api ships controllers in sibling packages beyond
        // com.fianzahealth.rasapi.*: the flow framework
        // (com.fianzahealth.flow.controller.FlowController), the MODD
        // dashboard / upload pair (com.fianzahealth.modd.controller.*) and the
        // Coding Workbench (com.fianzahealth.coding.controller.*).
        // All of them need the /ras-api prefix in bundled mode — in standalone
        // ras-api they'd inherit it from server.servlet.context-path=/ras-api.
        // A package missing from this list is invisible in standalone dev and
        // 404s only here, so keep it in step with the controller packages in
        // ras-api (`grep -rl @RestController src/main/java`).
        configurer.addPathPrefix("/ras-api", c -> {
            String pkg = c.getPackageName();
            return pkg.startsWith("com.fianzahealth.rasapi")
                    || pkg.startsWith("com.fianzahealth.flow")
                    || pkg.startsWith("com.fianzahealth.modd")
                    || pkg.startsWith("com.fianzahealth.coding");
        });
        configurer.addPathPrefix("/reconer",
                c -> c.getPackageName().startsWith("com.fianzahealth.ras.reconer"));
        configurer.addPathPrefix("/x12er",
                c -> c.getPackageName().startsWith("com.fianzahealth.x12er"));
        configurer.addPathPrefix("/ras-analyzer",
                c -> c.getPackageName().startsWith("com.medvand.rasanalyzer"));
    }
}
