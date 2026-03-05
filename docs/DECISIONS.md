# Architectural Decisions

This log captures the major architectural decisions made for the assessment, along with the primary trade-offs.

## 1. Elastic Stack on Kubernetes (self-hosted)
- **Decision:** Deploy Elasticsearch, Kibana, and APM Server directly into the Kubernetes cluster.
- **Why:** Ensures reproducibility and removes external dependencies for the assessment environment.
- **Trade-off:** More setup complexity versus a managed service.

## 2. OpenTelemetry Collector Topology (Agent + Gateway)
- **Decision:** Use a DaemonSet agent and a centralized gateway.
- **Why:** Agents collect node-local telemetry; the gateway consolidates exports and is the right place for tail sampling.
- **Trade-off:** Additional moving pieces compared to a single collector.

## 3. Tail-Based Sampling Policy
- **Decision:** Tail-sample at the gateway with a higher priority for errors.
- **Why:** Preserves the most valuable traces (errors, slow requests) while reducing volume.
- **Trade-off:** Slightly higher latency before a trace is exported.

## 4. Instrumentation Scope (Polyglot)
- **Decision:** Instrument three services across different languages.
- **Why:** Demonstrates that instrumentation works across languages and stack diversity.
- **Trade-off:** Requires multiple agent configs and patch sets.

## 5. RUM via Elastic RUM Agent
- **Decision:** Use Elastic RUM for browser telemetry.
- **Why:** Native correlation to APM, minimal configuration, quick to validate.
- **Trade-off:** Tied to the Elastic ecosystem rather than a vendor-neutral JS agent.

## 6. Dashboards via NDJSON Exports
- **Decision:** Provide NDJSON exports and panel specifications.
- **Why:** Allows easy import and reproducible dashboards in Kibana.
- **Trade-off:** Requires manual panel construction when using panel specs.

## 7. Operational Scripts
- **Decision:** Provide `run_all.sh` and `destroy_all.sh` for repeatability.
- **Why:** Reduces setup time and makes the environment reproducible.
- **Trade-off:** Some steps must remain manual (patches and Kibana imports).

## 8. Fast Mode (1-node kind + reduced Elastic resources)
- **Decision:** Default to a 1-node kind cluster with reduced ES/Kibana resource requests for local speed.
- **Why:** Avoids slow image loads and scheduling failures on resource-constrained laptops.
- **Trade-off:** Lower headroom and occasional tuning for Kibana memory limits.

## 9. Alert Rules via Kibana API
- **Decision:** Create alert rules via the Kibana alerting API instead of NDJSON import.
- **Why:** Encrypted saved objects and rule-type registration vary by version; API creation is more reliable.
- **Trade-off:** Requires API calls after Kibana is ready.
