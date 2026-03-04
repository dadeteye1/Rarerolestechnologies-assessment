# Walkthrough

This walkthrough is written to be run end-to-end on macOS using `kind`. It is organized by phases with validation steps after each phase.

## Phase 0 — Prerequisites
1. Ensure Docker Desktop is running and has sufficient resources (suggested: 6+ CPU, 8+ GB RAM).
2. Verify CLI tools are installed: `kubectl`, `helm`, `kind`, `git`.

## Phase 1 — Cluster + Ingress
1. Create a 3-node kind cluster (or use the automated script).
2. Install NGINX Ingress for routing.
3. Validate:
   - All nodes are `Ready`.
   - `ingress-nginx-controller` is `Ready`.

## Phase 2 — Online Boutique
1. Deploy the Online Boutique manifests.
2. Wait for the `frontend` deployment to be available.
3. Validate:
   - `kubectl -n default get deploy frontend` shows available replicas.

## Phase 3 — Elastic Stack
1. Apply `elastic-stack/00-namespace.yaml`.
2. Create or update the `elastic-credentials` secret.
3. Apply `elastic-stack/01-elasticsearch.yaml`, `02-kibana.yaml`, `03-apm-server.yaml`.
4. Wait for Elasticsearch pod to be ready and for HTTP to respond.
5. Set `kibana_system` password to match `ELASTIC_PASSWORD`.
6. Restart Kibana.
7. Validate:
   - Elasticsearch health API returns `status`.
   - Kibana `/api/status` reports `overall: available`.

## Phase 4 — OpenTelemetry Collector
1. Add and update the OpenTelemetry Helm repo.
2. Install `otel-agent` and `otel-gateway` from:
   - `otel-collector/values-agent.yaml`
   - `otel-collector/values-gateway.yaml`
3. Validate:
   - Agent DaemonSet pods are `Running`.
   - Gateway deployment is `Running`.

## Phase 5 — Infra Monitoring
1. Apply Metricbeat and Filebeat configs under `infrastructure/`.
2. Validate:
   - Metricbeat DaemonSet is `Running` on all nodes.
   - Postgres/Redis/Nginx metricbeat deployments are `Running`.

## Phase 6 — Service Instrumentation
1. From the Online Boutique repo root, apply the service patches:
   - `instrumentation/cartservice/patch.diff`
   - `instrumentation/paymentservice/patch.diff`
   - `instrumentation/recommendationservice/patch.diff`
2. Patch deployments with the provided env patches.
3. Validate:
   - New pods are created for these services.
   - APM traces appear in Kibana (APM app).

## Phase 7 — RUM Integration
1. Edit `rum/frontend-patch.diff` and replace `APM_SERVER_URL` with the local APM endpoint.
2. Apply the patch to the frontend source.
3. Validate:
   - Browser traffic is visible in Kibana RUM/UX.

## Phase 8 — Dashboards and Alerts
1. In Kibana, import the NDJSON files from `rum/dashboards/`.
2. Import alerting rules from `infrastructure/alerting-rules/`.
3. Use `rum/dashboards/panel-specs.md` to build the required panels and re-export if needed.

## Phase 9 — Local Access
1. Port-forward Kibana and APM services (keep terminals open):
   - `kubectl -n elastic-stack port-forward svc/kibana 5601:5601 --address 127.0.0.1`
   - `kubectl -n elastic-stack port-forward svc/apm-server 8200:8200 --address 127.0.0.1`
2. Open Kibana at `http://127.0.0.1:5601`.

## Optional — Automated Flow
If you prefer an automated flow, run:
- `sh run_all.sh`

It runs phases 1–6 and prints the remaining manual steps (phases 6–9).
