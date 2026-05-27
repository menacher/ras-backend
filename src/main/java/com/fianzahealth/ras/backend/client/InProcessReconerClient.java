package com.fianzahealth.ras.backend.client;

import com.fianzahealth.rasapi.service.reconer.ReconerClient;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.DispatcherServlet;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * Bundled-mode {@link ReconerClient}: dispatches via the local
 * {@link DispatcherServlet} instead of HTTP. Replaces {@code HttpReconerClient}
 * when the {@code bundled} profile is active.
 *
 * <p>URL construction is a no-op (host/port are placeholders); the dispatcher
 * tunnel strips them before invocation. Tenant headers come from
 * {@link com.fianzahealth.ras.tenant.TenantContext} in
 * {@link AbstractInProcessClient#dispatch}.
 */
@Component("reconerClient")
@Profile("bundled")
@Slf4j
public class InProcessReconerClient extends AbstractInProcessClient implements ReconerClient {

    public InProcessReconerClient(DispatcherServlet dispatcherServlet,
                                  ServletContext servletContext,
                                  ObjectMapper objectMapper) {
        super(dispatcherServlet, servletContext, objectMapper);
    }

    @Override
    public UriComponentsBuilder uri(String path) {
        return UriComponentsBuilder.newInstance()
                .scheme("http")
                .host("backend")
                .port(8080)
                .path(path);
    }

    @Override
    public String legacyUrl(String pathAndQuery) {
        return pathAndQuery.startsWith("/") ? "http://backend:8080" + pathAndQuery
                                            : "http://backend:8080/" + pathAndQuery;
    }

    @Override
    public String get(String url) {
        return dispatch("GET", url, null);
    }

    @Override
    public String post(String url, Object requestBody) {
        return dispatch("POST", url, requestBody);
    }

    @Override
    public void postEmptyTolerateSocketTimeout(String url) {
        // No socket → no timeout to tolerate; just dispatch and ignore result.
        dispatch("POST", url, null);
    }
}
