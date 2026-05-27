# ras-backend

Single Spring Boot 4 process that aggregates **ras-api**, **reconer**,
**x12er**, and **ras-analyzer** into one JVM, one HikariCP pool, one Tomcat,
one fat jar.

In bundled mode (default profile), inter-service calls between ras-api and
the peer modules no longer go over HTTP at all — they are dispatched through
the local `DispatcherServlet` in the same JVM. Peer paths (`/reconer/**`,
`/x12er/**`, `/ras-analyzer/**`) are blocked from external HTTP by a filter.

The four peer repositories stay as they are. Each publishes **two** jars:
- `<artifact>-<version>.jar` — library jar (no `BOOT-INF/`), consumed by this bundled
- `<artifact>-<version>-boot.jar` — executable Spring Boot fat jar for standalone deploy

py-ras (Python) stays in its own container.

## Architecture

### Module graph (phase 2)

```
ras-common  (pom; multi-module aggregator + parent)
   │  parent: spring-boot-starter-parent:4.0.0
   │  manages all common deps + plugin config (boot-classifier convention)
   │  submodules: ras-core, ras-rule, ras-tenant
   │
   └─ used as <parent> by:
        ├── ras-api
        ├── reconer
        ├── x12er
        ├── ras-analyzer
        └── ras-backend
```

`ras-tenant` (new in phase 2) holds `TenantContext`, `TenantInterceptor` +
`TenantResolver`, the tx-cached `SchemaSettingDataSourceConnectionProvider`,
and `TenantAwareTaskDecorator`.

### Tenant infrastructure (phase 2A)

A new `ras-tenant` submodule under `ras-common` holds:
- `TenantContext` — single canonical class; all four modules import it
- `TenantInterceptor` — single Spring MVC `HandlerInterceptor` parameterised by a `TenantResolver` strategy
- `TenantResolver` + `HeaderPassthroughTenantResolver` — peers use the default; ras-api wires its own `HealthPlanLookupTenantResolver` (DAO lookup + Spring Security username)
- `SchemaSettingDataSourceConnectionProvider` — the tx-cached variant that was previously only in ras-api; reconer + ras-analyzer get the perf upgrade
- `TenantAwareTaskDecorator` — propagates tenant + MDC + Micrometer trace context to `@Async` pool threads

### In-process clients (phase 2B)

Three `ras-api` HTTP clients are now interfaces with two implementations each:

| Interface | HTTP impl (default) | In-process impl (`bundled` profile) |
|---|---|-------------------------------------|
| `ReconerClient` | `HttpReconerClient` | `InProcessReconerClient`            |
| `AnalyzerClient` | `HttpAnalyzerClient` | `InProcessAnalyzerClient`           |
| `X12erClient` (NEW) | `HttpX12erClient` | `InProcessX12erClient`              |

The in-process variants extend `AbstractInProcessClient` which builds a
`MockHttpServletRequest` (carrying tenant headers from `TenantContext`),
tags it with an internal-dispatch marker, and feeds it through the local
`DispatcherServlet` — no socket, no Tomcat, no JSON-over-wire.

`X12FileDataService` and `BatchProcessService` previously called raw
`RestClient` directly; they now go through the `X12erClient` interface so they
benefit from the in-process dispatch too.

### HTTP suppression (phase 2B)

`RasBackendExternalRequestFilter` (active only in `bundled` profile) rejects
external requests to `/reconer/**`, `/x12er/**`, `/ras-analyzer/**` with
404. Internal in-process dispatch carries the `ras.backend.internal` request
attribute and bypasses the rejection.

**Note: deviation from the original "exclude controllers from component scan"
choice.** Excluding controllers from scan would mean dispatching to *services*
directly (mapping all ~46 peer endpoints by hand). The filter+tunnel approach
achieves the same external-visibility outcome with O(1) code while preserving
full Spring MVC dispatch semantics (validation, content negotiation, arg
resolvers) for in-process calls. Switch to strict service-direct dispatch
as a phase 2C refinement if you want to fully drop the marshal/unmarshal hop.

### Profile activation

`ras-backend/src/main/resources/application.yml` sets
`spring.profiles.active: bundled` by default. Additional profiles can be
appended via `SPRING_PROFILES_ACTIVE` (e.g. `bundled,hamaspik`).

When `bundled` is **inactive** (i.e. ras-api running standalone), the
`@Profile("!bundled")` HTTP clients are wired and behaviour is identical to
phase 1.

## Building locally

```bash
# from clean checkouts of each repo as siblings
cd ../ras-common && mvn install -DskipTests    # builds the parent + ras-core + ras-rule + ras-tenant
cd ../ras-api && mvn install -DskipTests
cd ../reconer && mvn install -DskipTests
cd ../x12er && mvn install -DskipTests
cd ../ras-analyzer && mvn install -DskipTests
cd ../ras-backend && mvn package -DskipTests
```

## Running locally against the docker postgres

```bash
java -Xms1g -Xmx2g \
  -Dspring.profiles.active=bundled,hamaspik \
  -DPOSTGRES_URL=jdbc:postgresql://localhost:5432/ras \
  -DPOSTGRES_USER=ras \
  -DPOSTGRES_PASSWORD=12345 \
  -jar target/ras-backend-0.0.1-SNAPSHOT.jar
```

Expected smoke-test results once `Started RasBackendApplication` appears:
- `GET /actuator/health` → `200 {"status":"UP"}`
- `GET /ras-api/<anything>` → `401` (Cognito-protected; auth required)
- `GET /reconer/**`, `/x12er/**`, `/ras-analyzer/**` → `404` (rejected by filter)
- Internal dispatch (via `ReconerClient`/`AnalyzerClient`/`X12erClient` autowired into ras-api code) → works in-process; no HTTP

## Phase 2 follow-ups (deferred)

1. **Strict service-direct in-process dispatch.** Replace the
   `DispatcherServlet` tunnel with hand-mapped peer-service calls, then
   exclude peer controller packages from `RasBackendApplication`'s component
   scan. Removes the JSON marshal/unmarshal hop. ~46 endpoint mappings.
2. **Multipart in-process dispatch** — `InProcessAnalyzerClient.uploadFile`
   currently throws `UnsupportedOperationException`. Build a multipart-capable
   `MockHttpServletRequest` if any bundled flow actually uses it.
3. **Postgres driver alignment** — done in phase 2 (ras-analyzer 42.7.8 →
   42.7.11 via `ras-common`'s managed version). No more divergence.

## Phase 1 limitations (still relevant)

- Reconer's `LinkedHashMap/LinkedHashSet` Jackson customisation is dropped.
  Re-introduce via a Jackson 3 `JsonMapperBuilderCustomizer` if needed.
- Reconer's `TenantAwareTaskDecorator` standalone wiring is replaced by the
  shared `ras-tenant` variant. ras-api's `AsyncConfig`-wired executors now
  use the unified decorator. KNOWN GAP: reconer's `AsyncConfig` is still
  excluded from the bundled scan — `@Async` reconer tasks in bundled mode
  use Spring's default executor. Restore via a bundled-side `AsyncConfigurer`
  if any feature depends on it.
- CI uses cross-repo checkouts; switching to `mvn -Pgithub deploy` + GitHub
  Packages would fully decouple module builds.
