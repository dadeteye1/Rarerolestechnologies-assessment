# SRE Practical Assessment — Implementation Repo

This repository contains the Kubernetes manifests, OpenTelemetry configs, instrumentation patches, RUM integration, and Kibana assets needed to implement end-to-end observability for the Online Boutique microservices using the Elastic Stack and OpenTelemetry.

## Repository Structure
```
sre-assessment/
├── otel-collector/                 # Helm values, collector configs
│   ├── values-agent.yaml
│   ├── values-gateway.yaml
│   └── sampling-policy.yaml
├── instrumentation/                # Per-service instrumentation code/patches
│   ├── frontend/
│   ├── cartservice/
│   └── paymentservice/
├── rum/                            # Browser SDK integration code
│   ├── rum-snippet.js
│   ├── frontend-patch.diff
│   └── dashboards/                 # Kibana Saved Objects (NDJSON exports)
│       ├── service-health.ndjson
│       ├── rum-performance.ndjson
│       └── business-transactions.ndjson
├── infrastructure/                 # Agent/Beat configs, alert rules
│   ├── elastic-agent-policies/     # Fleet policy exports or agent.yml
│   ├── postgres-integration/
│   ├── redis-integration/
│   ├── nginx-integration/
│   └── alerting-rules/             # Kibana rule exports (NDJSON)
├── docs/
│   ├── DECISIONS.md                # Architectural decision log
│   ├── WALKTHROUGH.md              # Step-by-step walkthrough
│   └── TROUBLESHOOTING.md          # Common issues + fixes
└── README.md                       # Setup instructions
```

## Prerequisites
- Docker Desktop or Docker Engine with enough resources (suggested: 6+ CPU / 8+ GB RAM).
- `kubectl`, `helm`, `kind` installed.
- `git` for applying patches to the Online Boutique repo.

## Quick Start (Automated)
This uses `run_all.sh` to set up the cluster, deploy the stack, and print the remaining manual steps.

1. From this repo root, run:
   - `sh run_all.sh`
   - `FAST_MODE=0 sh run_all.sh` if you want a 3-node cluster instead of the default 1-node fast mode.
2. Follow the **manual** steps printed at the end:
   - Apply instrumentation patches.
   - Apply RUM patch (after setting APM server URL).
   - Import Kibana dashboards.
   - Create alerting rules (see Phase 8 below).
3. Expose Kibana and APM locally using port-forwarding (keep terminals open):
   - `kubectl -n elastic-stack port-forward svc/kibana 5601:5601 --address 127.0.0.1`
   - `kubectl -n elastic-stack port-forward svc/apm-server 8200:8200 --address 127.0.0.1`

Kibana UI: `http://127.0.0.1:5601`
APM Server: `http://127.0.0.1:8200` (API endpoint, not a UI)

Credentials:
- Set `ELASTIC_PASSWORD`, `ROOT_USERNAME`, and `ROOT_PASSWORD` in your shell if you want to override defaults.

## Manager-Friendly Walkthrough
This section mirrors `docs/WALKTHROUGH.md` but is included here for quick review.

### Phase 0 — Prerequisites (5 minutes)
**Outcome:** You have a ready local environment to run the demo.
- Ensure Docker Desktop is running and has sufficient resources (suggested: 6+ CPU, 8+ GB RAM).
- Verify CLI tools are installed: `kubectl`, `helm`, `kind`, `git`.

### Phase 1 — Cluster + Ingress (10–15 minutes)
**Outcome:** Kubernetes cluster is running, ingress is ready.
- Create a 1-node kind cluster (fast mode default) or 3-node (set `FAST_MODE=0`).
- Install NGINX Ingress for routing.
- Validate nodes and ingress controller are `Ready`.

### Phase 2 — Online Boutique (5–10 minutes)
**Outcome:** The demo microservices are running and generating traffic.
- Deploy the Online Boutique manifests.
- Wait for the `frontend` deployment to be available.

### Phase 3 — Elastic Stack (10–20 minutes)
**Outcome:** Elasticsearch, Kibana, and APM are running and reachable inside the cluster.
- Apply `elastic-stack/00-namespace.yaml`.
- Create or update the `elastic-credentials` secret.
- Apply `elastic-stack/01-elasticsearch.yaml`, `02-kibana.yaml`, `03-apm-server.yaml`.
- Wait for Elasticsearch HTTP to respond.
- Set `kibana_system` password to match `ELASTIC_PASSWORD`.
- Restart Kibana.
Notes:
- Kibana encryption keys are configured via environment variables in `elastic-stack/02-kibana.yaml` to enable alerting APIs.

### Phase 4 — OpenTelemetry Collector (5–10 minutes)
**Outcome:** Telemetry flows from services to Elastic.
- Install `otel-agent` and `otel-gateway` with the Helm values in `otel-collector/`.
- Validate agent DaemonSet and gateway deployment are `Running`.

### Phase 5 — Infra Monitoring (5–10 minutes)
**Outcome:** Node and platform metrics are collected.
- Apply Metricbeat and Filebeat configs under `infrastructure/`.

### Phase 6 — Service Instrumentation (10–15 minutes)
**Outcome:** Traces appear for key backend services.
- Apply patches for cart, payment, and recommendation services.
- Patch deployments with the provided env patches.

### Phase 7 — RUM Integration (5–10 minutes)
**Outcome:** Browser performance and errors show up in Kibana.
- Replace `APM_SERVER_URL` in `rum/frontend-patch.diff` and apply it.

### Phase 8 — Dashboards and Alerts (10–15 minutes)
**Outcome:** Management dashboards and alerts are visible in Kibana.
- Import NDJSON dashboards from `rum/dashboards/`.
- Create alert rules via the Kibana alerting API using the definitions in `infrastructure/alerting-rules/alerts.ndjson`.
  - Use a superuser account and the `.index-threshold` rule type.

### Phase 9 — Local Access (2 minutes)
**Outcome:** Kibana is reachable on your laptop for dashboard review.
- Port-forward Kibana and APM services and open `http://127.0.0.1:5601`.

### Phase 10 — Electron Dashboard (5 minutes)
**Outcome:** A desktop view of the executive dashboard is running for presentation/demo.
- Run `npm install` in `electron-dashboard/`.
- Start with `npm run app`.

## Validation (Kubernetes-side)
If Kibana shows “server not ready,” validate Elasticsearch first:
- Check ES health inside the pod (auth required).
- Kibana should report `overall: available` on `/api/status`.

See `docs/TROUBLESHOOTING.md` for copy-paste checks and fixes.

## Cleanup
To destroy the environment:
- `sh destroy_all.sh`

This removes the kind cluster and deployed resources.
