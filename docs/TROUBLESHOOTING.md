# Troubleshooting

## Kibana shows “server not ready”
**Cause:** Elasticsearch not ready, or Kibana credentials don’t match `kibana_system` password.

**Checks**
1. Verify Elasticsearch pod is ready.
2. Verify ES HTTP responds with auth:
   - `curl -u elastic:<ELASTIC_PASSWORD> http://localhost:9200/_cluster/health`
3. Check Kibana status from inside the pod:
   - `curl http://localhost:5601/api/status`

**Fix**
1. Set `kibana_system` password to match `ELASTIC_PASSWORD`.
2. Restart the Kibana deployment.

## Elasticsearch pod is crashing / data corruption
**Cause:** Corrupt data on the persistent volume.

**Fix**
1. Delete the ES pod.
2. Delete the ES PVC `es-data-elasticsearch-0`.
3. Wait for the pod to recreate and become ready.

## Port-forward exits immediately
**Cause:** Port-forward process ends when the parent shell exits or kubectl can’t reach the API server.

**Fix**
1. Run port-forward in a dedicated terminal and keep it open.
2. Verify the API server is reachable (`kubectl get nodes`).

## APM Server shows blank page in browser
**Expected:** APM Server is an API endpoint, not a UI. Use Kibana APM app for the UI.

## Online Boutique `frontend` never becomes available
**Cause:** Cluster resource pressure or image pull failures.

**Fix**
1. Increase Docker Desktop resources (CPU/RAM).
2. Recreate the kind cluster and re-run.

## OTel Collector Helm install fails schema validation
**Cause:** Unsupported fields in values (e.g., `service.ports`).

**Fix**
1. Use the provided `otel-collector/values-agent.yaml` and `otel-collector/values-gateway.yaml` without adding unsupported keys.
