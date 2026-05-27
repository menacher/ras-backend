package com.fianzahealth.ras.backend.client;

import com.fianzahealth.ras.tenant.TenantContext;
import com.fianzahealth.ras.tenant.TenantHeaders;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.servlet.DispatcherServlet;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

/**
 * Shared dispatch path for the ras-backend.s in-process clients. Builds a
 * {@link MockHttpServletRequest} from a method / path / body, propagates the
 * current {@link TenantContext} as request headers, and dispatches through
 * the local {@link DispatcherServlet} — no socket, no Tomcat, no JSON-over-wire.
 *
 * <p>Spring MVC arg resolvers + {@code HttpMessageConverter}s do the body
 * marshal/unmarshal exactly as if the request had arrived over HTTP, so
 * controllers don't know they're being dispatched in-process.
 *
 * <p>Each in-process request carries the {@link #INTERNAL_DISPATCH_ATTRIBUTE}
 * marker; {@code RasBackendExternalRequestFilter} uses this to distinguish
 * legitimate in-process invocations from would-be external HTTP requests
 * to the same paths (which are rejected).
 */
@Slf4j
public abstract class AbstractInProcessClient {

    /** Request attribute set on every in-process dispatch; checked by the external-request filter. */
    public static final String INTERNAL_DISPATCH_ATTRIBUTE = "ras.backend.internal";

    private final DispatcherServlet dispatcherServlet;
    private final ServletContext servletContext;
    private final ObjectMapper objectMapper;

    protected AbstractInProcessClient(DispatcherServlet dispatcherServlet,
                                      ServletContext servletContext,
                                      ObjectMapper objectMapper) {
        this.dispatcherServlet = dispatcherServlet;
        this.servletContext = servletContext;
        this.objectMapper = objectMapper;
    }

    protected String dispatch(String method, String url, Object jsonBody) {
        String pathAndQuery = stripHostPort(url);
        String path = pathAndQuery;
        String query = null;
        int q = pathAndQuery.indexOf('?');
        if (q >= 0) {
            path = pathAndQuery.substring(0, q);
            query = pathAndQuery.substring(q + 1);
        }

        MockHttpServletRequest req = new MockHttpServletRequest(servletContext, method, path);
        req.setRequestURI(path);
        if (query != null) {
            req.setQueryString(query);
            // setQueryString does NOT auto-populate getParameter(...) on the mock
            // the way real servlet containers do — parse the pairs ourselves so
            // @RequestParam / @ModelAttribute resolution finds the values.
            // addParameter (not setParameter) keeps multi-valued query params like
            // years=2023&years=2024 working.
            for (String pair : query.split("&")) {
                if (pair.isEmpty()) continue;
                int eq = pair.indexOf('=');
                String k = eq < 0 ? pair : pair.substring(0, eq);
                String v = eq < 0 ? "" : pair.substring(eq + 1);
                req.addParameter(
                        URLDecoder.decode(k, StandardCharsets.UTF_8),
                        URLDecoder.decode(v, StandardCharsets.UTF_8));
            }
        }
        req.setAttribute(INTERNAL_DISPATCH_ATTRIBUTE, Boolean.TRUE);

        // Snapshot the outer TenantContext BEFORE dispatch so we can restore it
        // afterwards. The inner request runs through TenantInterceptor whose
        // afterCompletion() unconditionally clears TenantContext — without this
        // save/restore, code that runs on the OUTER request thread after the
        // dispatch returns would see a null tenant (which then makes
        // SchemaSettingDataSourceConnectionProvider issue SET SCHEMA 'null' and
        // breaks subsequent DB queries).
        String savedTenantId = TenantContext.getTenantId();
        String savedPlanName = TenantContext.getPlanName();
        String savedUsername = TenantContext.getUsername();

        // Propagate tenant via headers exactly like the HTTP path does.
        // X-TENANT-ID feeds the (canonical) HealthPlanLookupTenantResolver in
        // ras-api — same lookup path the UI's outer request uses. The X-SCHEMA-ID
        // / X-PLAN-NAME pair is the contract HeaderPassthroughTenantResolver
        // expects; setting both keeps the in-process dispatch correct regardless
        // of which resolver bean ends up wired. MockHttpServletRequest.addHeader
        // rejects null, so coalesce to "".
        addHeaderSafe(req, TenantHeaders.X_TENANT_ID, savedPlanName);
        addHeaderSafe(req, TenantHeaders.X_SCHEMA_ID, savedTenantId);
        addHeaderSafe(req, TenantHeaders.X_PLAN_NAME, savedPlanName);
        addHeaderSafe(req, TenantHeaders.X_USERNAME,  savedUsername);

        if (jsonBody != null) {
            // Pass-through if the caller already serialized (matches HttpReconerClient's
            // RestClient behaviour where a String body is sent verbatim). Jackson-encode
            // anything else.
            byte[] body;
            if (jsonBody instanceof String s) {
                body = s.getBytes(StandardCharsets.UTF_8);
            } else if (jsonBody instanceof byte[] b) {
                body = b;
            } else {
                try {
                    body = objectMapper.writeValueAsBytes(jsonBody);
                } catch (Exception e) {
                    throw new RuntimeException("Failed to serialize body for " + path, e);
                }
            }
            req.setContent(body);
            req.addHeader("Content-Type", "application/json");
        }

        MockHttpServletResponse resp = new MockHttpServletResponse();
        try {
            dispatcherServlet.service(req, resp);
        } catch (Exception e) {
            throw new RuntimeException("In-process dispatch to " + path + " failed", e);
        } finally {
            // Restore the outer tenant so post-dispatch code on the same thread
            // sees what the outer interceptor put there. setTenantId(null) /
            // setPlanName(null) leave the ThreadLocals as null (matching pre-dispatch).
            TenantContext.setTenantId(savedTenantId);
            TenantContext.setPlanName(savedPlanName);
            TenantContext.setUsername(savedUsername);
        }

        int status = resp.getStatus();
        try {
            String body = resp.getContentAsString();
            if (status >= 400) {
                throw new RuntimeException("In-process dispatch to " + path
                        + " returned status " + status + ": " + body);
            }
            return body;
        } catch (java.io.UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }

    private static void addHeaderSafe(MockHttpServletRequest req, String name, String value) {
        req.addHeader(name, value == null ? "" : value);
    }

    private static String stripHostPort(String url) {
        if (url == null || url.isBlank()) return "/";
        try {
            URI u = URI.create(url);
            String path = u.getRawPath() == null ? "" : u.getRawPath();
            String q = u.getRawQuery();
            return q == null ? path : path + "?" + q;
        } catch (IllegalArgumentException ex) {
            // Treat as already a path/query string
            return url;
        }
    }
}
