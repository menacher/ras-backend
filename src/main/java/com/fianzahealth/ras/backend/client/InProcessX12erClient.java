package com.fianzahealth.ras.backend.client;

import com.fianzahealth.rasapi.extmodel.X12FilePostInfo;
import com.fianzahealth.rasapi.service.x12er.X12erClient;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.DispatcherServlet;

/**
 * Bundled-mode {@link X12erClient}: dispatches the {@link X12FilePostInfo} POST
 * through the local DispatcherServlet to {@code /x12er/file} (the path the
 * RasBackendWebConfig prefixer puts the x12er controller at in bundled mode).
 */
@Component("x12erClient")
@Profile("bundled")
@Slf4j
public class InProcessX12erClient extends AbstractInProcessClient implements X12erClient {

    private static final String X12ER_FILE_PATH = "/x12er/file";

    public InProcessX12erClient(DispatcherServlet dispatcherServlet,
                                ServletContext servletContext,
                                ObjectMapper objectMapper) {
        super(dispatcherServlet, servletContext, objectMapper);
    }

    @Override
    public String submit(X12FilePostInfo postInfo) {
        log.info("In-process x12er submit: file={} ruleVersion={}", postInfo.getFilePath(), postInfo.getRuleVersion());
        return dispatch("POST", X12ER_FILE_PATH, postInfo);
    }
}
