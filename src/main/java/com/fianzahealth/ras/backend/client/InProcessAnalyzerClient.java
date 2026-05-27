package com.fianzahealth.ras.backend.client;

import com.fianzahealth.rasapi.service.analyzer.AnalyzerClient;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.DispatcherServlet;

/**
 * Bundled-mode {@link AnalyzerClient}: dispatches via the local DispatcherServlet.
 *
 * <p>{@link #uploadFile} is not yet supported in bundled mode — multipart in-process
 * dispatch requires a different request-building path. Throws
 * {@code UnsupportedOperationException} for now; the only caller is the manual
 * "load file" UI commands which can fall back to a temp directory drop if needed.
 */
@Component("analyzerClient")
@Profile("bundled")
@Slf4j
public class InProcessAnalyzerClient extends AbstractInProcessClient implements AnalyzerClient {

    public InProcessAnalyzerClient(DispatcherServlet dispatcherServlet,
                                   ServletContext servletContext,
                                   ObjectMapper objectMapper) {
        super(dispatcherServlet, servletContext, objectMapper);
    }

    @Override
    public String url(String pathAndQuery) {
        return pathAndQuery.startsWith("/")
                ? "http://backend:8080/ras-analyzer" + pathAndQuery
                : "http://backend:8080/ras-analyzer/" + pathAndQuery;
    }

    @Override
    public String uploadFile(String url, MultipartFile file) {
        throw new UnsupportedOperationException(
                "Multipart in-process dispatch is not implemented yet. Call this in standalone mode "
                + "or drop the file directly into ras-analyzer's input directory.");
    }

    @Override
    public String postBody(String url, Object postBody) {
        return dispatch("POST", url, postBody);
    }

    @Override
    public String call(String url, String method) {
        return dispatch("POST".equalsIgnoreCase(method) ? "POST" : "GET", url, null);
    }
}
