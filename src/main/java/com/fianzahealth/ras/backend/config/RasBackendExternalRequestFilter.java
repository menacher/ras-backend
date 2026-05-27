package com.fianzahealth.ras.backend.config;

import com.fianzahealth.ras.backend.client.AbstractInProcessClient;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.Ordered;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Set;

/**
 * Rejects external HTTP requests to peer-module paths ({@code /reconer/**},
 * {@code /x12er/**}, {@code /ras-analyzer/**}) when running inside
 * ras-backend. Internal in-process dispatch via
 * {@link AbstractInProcessClient#dispatch} carries the
 * {@link AbstractInProcessClient#INTERNAL_DISPATCH_ATTRIBUTE} marker and is
 * allowed through.
 *
 * <p>This is the backend-side substitute for the
 * "exclude controllers from component scan" design pick: controllers remain
 * registered (so the in-process dispatcher tunnel works) but their HTTP-facing
 * routes are inaccessible from outside the JVM.
 */
@Slf4j
@Configuration
@Profile("bundled")
public class RasBackendExternalRequestFilter {

    private static final Set<String> BLOCKED_PREFIXES = Set.of(
            "/reconer/",
            "/x12er/",
            "/ras-analyzer/");

    @Bean
    public FilterRegistrationBean<OncePerRequestFilter> rasBackendExternalRequestFilter() {
        FilterRegistrationBean<OncePerRequestFilter> reg = new FilterRegistrationBean<>();
        reg.setFilter(new OncePerRequestFilter() {
            @Override
            protected void doFilterInternal(HttpServletRequest request,
                                            HttpServletResponse response,
                                            FilterChain chain) throws ServletException, IOException {
                if (request.getAttribute(AbstractInProcessClient.INTERNAL_DISPATCH_ATTRIBUTE) != null) {
                    chain.doFilter(request, response);
                    return;
                }
                String uri = request.getRequestURI();
                for (String prefix : BLOCKED_PREFIXES) {
                    if (uri.startsWith(prefix)) {
                        log.warn("Rejected external request to backend-internal path: {} {}",
                                request.getMethod(), uri);
                        // Commit the response directly (no sendError) so the container
                        // doesn't dispatch to ERROR — which would re-run Spring
                        // Security's filter chain and replace our 404 with a 401.
                        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                        response.setContentType("text/plain;charset=UTF-8");
                        response.getWriter().write("Not Found");
                        response.getWriter().flush();
                        return;
                    }
                }
                chain.doFilter(request, response);
            }
        });
        reg.addUrlPatterns("/*");
        reg.setOrder(Ordered.HIGHEST_PRECEDENCE + 10);
        reg.setName("rasBackendExternalRequestFilter");
        return reg;
    }
}
