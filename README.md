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
- macOS with Docker Desktop running and enough resources (suggested: 6+ CPU / 8+ GB RAM).
- `kubectl`, `helm`, `kind` installed.
- `git` for applying patches to the Online Boutique repo.

## Quick Start (Automated)
This uses `run_all.sh` to set up the cluster, deploy the stack, and print the remaining manual steps.

1. From this repo root, run:
   - `sh run_all.sh`
2. Follow the **manual** steps printed at the end:
   - Apply instrumentation patches.
   - Apply RUM patch (after setting APM server URL).
   - Import Kibana dashboards + alerting rules.
3. Expose Kibana and APM locally using port-forwarding (keep terminals open):
   - `kubectl -n elastic-stack port-forward svc/kibana 5601:5601 --address 127.0.0.1`
   - `kubectl -n elastic-stack port-forward svc/apm-server 8200:8200 --address 127.0.0.1`

Kibana UI: `http://127.0.0.1:5601`
APM Server: `http://127.0.0.1:8200` (API endpoint, not a UI)

## Manual Walkthrough
A complete step-by-step walkthrough is available in:
- `docs/WALKTHROUGH.md`

It includes:
- Cluster creation
- Deploying Online Boutique
- Deploying Elastic Stack
- Deploying OpenTelemetry Collector
- Instrumentation patches
- RUM integration
- Dashboard import
- Validation checks

## Credentials
Defaults are configured in `run_all.sh`:
- `ELASTIC_PASSWORD` (default: `lamilinux@`)
- `ROOT_USERNAME` (default: `root`)
- `ROOT_PASSWORD` (default: `lamilinux@`)

These are written into the `elastic-credentials` secret and used for Kibana and APM. Override by exporting env vars before running the script.

## Validation (Kubernetes-side)
If Kibana shows “server not ready,” validate Elasticsearch first:
- Check ES health inside the pod (auth required).
- Kibana should report `overall: available` on `/api/status`.

See `docs/TROUBLESHOOTING.md` for copy-paste checks and fixes.

## Cleanup
To destroy the environment:
- `sh destroy_all.sh`

This removes the kind cluster and deployed resources.
