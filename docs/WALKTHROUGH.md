# Walkthrough

This walkthrough is written for a manager-level reader who wants to understand *what* to do and *what to expect* at each step. It is organized by phases with clear outcomes and validation points. You can follow it end-to-end on any OS with Docker and `kind`, or use it as a checklist during the demo.

## Phase 0 — Prerequisites (5 minutes)
**Outcome:** You have a ready local environment to run the demo.

1. Ensure Docker Desktop is running and has sufficient resources (suggested: 6+ CPU, 8+ GB RAM).
2. Verify CLI tools are installed: `kubectl`, `helm`, `kind`, `git`.

## Phase 1 — Cluster + Ingress (10–15 minutes)
**Outcome:** Kubernetes cluster is running, ingress is ready.

1. Create a 1-node kind cluster for fast local iteration (or use the automated script). Use `FAST_MODE=0` for 3 nodes.
2. Install NGINX Ingress for routing.
3. Validate:
   - All nodes are `Ready`.
   - `ingress-nginx-controller` is `Ready`.

## Phase 2 — Online Boutique (5–10 minutes)
**Outcome:** The demo microservices are running and generating traffic.

1. Deploy the Online Boutique manifests.
2. Wait for the `frontend` deployment to be available.
3. Validate:
   - `kubectl -n default get deploy frontend` shows available replicas.

## Phase 3 — Elastic Stack (10–20 minutes)
**Outcome:** Elasticsearch, Kibana, and APM are running and reachable inside the cluster.

1. Apply `elastic-stack/00-namespace.yaml`.
2. Create or update the `elastic-credentials` secret.
3. Apply `elastic-stack/01-elasticsearch.yaml`, `02-kibana.yaml`, `03-apm-server.yaml`.
4. Wait for Elasticsearch pod to be ready and for HTTP to respond.
5. Set `kibana_system` password to match `ELASTIC_PASSWORD`.
6. Restart Kibana.
7. Validate:
   - Elasticsearch health API returns `status`.
   - Kibana `/api/status` reports `overall: available`.

## Phase 4 — OpenTelemetry Collector (5–10 minutes)
**Outcome:** Telemetry flows from services to Elastic.

1. Add and update the OpenTelemetry Helm repo.
2. Install `otel-agent` and `otel-gateway` from:
   - `otel-collector/values-agent.yaml`
   - `otel-collector/values-gateway.yaml`
3. Validate:
   - Agent DaemonSet pods are `Running`.
   - Gateway deployment is `Running`.

## Phase 5 — Infra Monitoring (5–10 minutes)
**Outcome:** Node and platform metrics are collected.

1. Apply Metricbeat and Filebeat configs under `infrastructure/`.
2. Validate:
   - Metricbeat DaemonSet is `Running` on all nodes.
   - Postgres/Redis/Nginx metricbeat deployments are `Running`.

## Phase 6 — Service Instrumentation (10–15 minutes)
**Outcome:** Traces appear for key backend services.

1. From the Online Boutique repo root, apply the service patches:
   - `instrumentation/cartservice/patch.diff`
   - `instrumentation/paymentservice/patch.diff`
   - `instrumentation/recommendationservice/patch.diff`
2. Patch deployments with the provided env patches.
3. Validate:
   - New pods are created for these services.
   - APM traces appear in Kibana (APM app).

## Phase 7 — RUM Integration (5–10 minutes)
**Outcome:** Browser performance and errors show up in Kibana.

1. Edit `rum/frontend-patch.diff` and replace `APM_SERVER_URL` with the local APM endpoint.
2. Apply the patch to the frontend source.
3. Validate:
   - Browser traffic is visible in Kibana RUM/UX.

## Phase 8 — Dashboards and Alerts (10–15 minutes)
**Outcome:** Management dashboards and alerts are visible in Kibana.

1. In Kibana, import the NDJSON files from `rum/dashboards/`.
2. Create alerting rules via the Kibana alerting API using the definitions in `infrastructure/alerting-rules/alerts.ndjson`.
   - Use a superuser account and the `.index-threshold` rule type.
3. Use `rum/dashboards/panel-specs.md` to build the required panels and re-export if needed.

## Phase 9 — Local Access (2 minutes)
**Outcome:** Kibana is reachable on your laptop for dashboard review.

1. Port-forward Kibana and APM services (keep terminals open):
   - `kubectl -n elastic-stack port-forward svc/kibana 5601:5601 --address 127.0.0.1`
   - `kubectl -n elastic-stack port-forward svc/apm-server 8200:8200 --address 127.0.0.1`
2. Open Kibana at `http://127.0.0.1:5601`.

## Phase 10 — Electron Dashboard (5 minutes)
**Outcome:** A desktop view of the executive dashboard is running for presentation/demo.

1. Install dependencies inside `electron-dashboard/`:
   - `npm install`
2. Start the Electron app:
   - `npm run app`
3. Validate:
   - The dashboard opens in a native window.
   - Tiles and charts render without scrolling or layout jumps.

If you want the Electron view to point to Kibana data, keep the Kibana port-forward running and configure the Electron data source accordingly.

## Optional — Automated Flow
If you prefer an automated flow, run:
- `sh run_all.sh`

It runs phases 1–6 and prints the remaining manual steps (phases 6–10).
