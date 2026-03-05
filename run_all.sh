#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KIND_CLUSTER_NAME="sre"
FAST_MODE="${FAST_MODE:-1}"
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-administrator1}"
APM_SECRET_TOKEN="${APM_SECRET_TOKEN:-changeme-apm-secret-token}"
ROOT_USERNAME="${ROOT_USERNAME:-admin}"
ROOT_PASSWORD="${ROOT_PASSWORD:-administrator1}"

run_with_timeout() {
  local timeout_seconds="$1"
  shift
  "$@" &
  local cmd_pid=$!
  local start_ts
  start_ts=$(date +%s)
  while kill -0 "${cmd_pid}" 2>/dev/null; do
    local now_ts
    now_ts=$(date +%s)
    if (( now_ts - start_ts >= timeout_seconds )); then
      kill -TERM "${cmd_pid}" 2>/dev/null || true
      sleep 1
      kill -KILL "${cmd_pid}" 2>/dev/null || true
      wait "${cmd_pid}" 2>/dev/null || true
      return 124
    fi
    sleep 2
  done
  wait "${cmd_pid}"
}

if [[ "${FAST_MODE}" == "1" ]]; then
  echo "[1/9] Creating 1-node kind cluster (fast mode, if needed)..."
else
  echo "[1/9] Creating 3-node kind cluster (if needed)..."
fi
if kubectl config get-contexts -o name 2>/dev/null | grep -qx "kind-${KIND_CLUSTER_NAME}"; then
  echo "  - kind context 'kind-${KIND_CLUSTER_NAME}' exists, checking API health"
  kubectl config use-context "kind-${KIND_CLUSTER_NAME}"
  if kubectl --request-timeout=10s get nodes >/dev/null 2>&1; then
    echo "  - kind cluster '${KIND_CLUSTER_NAME}' is reachable, skipping create"
  else
    echo "  - existing context is not reachable, recreating kind cluster '${KIND_CLUSTER_NAME}'"
    run_with_timeout 180 kind delete cluster --name "${KIND_CLUSTER_NAME}" >/dev/null 2>&1 || true
    if [[ "${FAST_MODE}" == "1" ]]; then
      cat > /tmp/kind-sre-1node.yaml <<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
YAML
      if ! run_with_timeout 420 kind create cluster --name "${KIND_CLUSTER_NAME}" --config /tmp/kind-sre-1node.yaml; then
        echo "ERROR: timed out creating kind cluster. Ensure Docker Desktop is running and has enough resources."
        exit 1
      fi
    else
      cat > /tmp/kind-sre-3node.yaml <<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
YAML
      if ! run_with_timeout 420 kind create cluster --name "${KIND_CLUSTER_NAME}" --config /tmp/kind-sre-3node.yaml; then
        echo "ERROR: timed out creating kind cluster. Ensure Docker Desktop is running and has enough resources."
        exit 1
      fi
    fi
    kubectl config use-context "kind-${KIND_CLUSTER_NAME}"
  fi
else
  if [[ "${FAST_MODE}" == "1" ]]; then
    cat > /tmp/kind-sre-1node.yaml <<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
YAML
    if ! run_with_timeout 420 kind create cluster --name "${KIND_CLUSTER_NAME}" --config /tmp/kind-sre-1node.yaml; then
      echo "ERROR: timed out creating kind cluster. Ensure Docker Desktop is running and has enough resources."
      exit 1
    fi
  else
    cat > /tmp/kind-sre-3node.yaml <<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
YAML
    if ! run_with_timeout 420 kind create cluster --name "${KIND_CLUSTER_NAME}" --config /tmp/kind-sre-3node.yaml; then
      echo "ERROR: timed out creating kind cluster. Ensure Docker Desktop is running and has enough resources."
      exit 1
    fi
  fi
  kubectl config use-context "kind-${KIND_CLUSTER_NAME}"
fi

echo "[2/9] Installing NGINX Ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
# Ensure nodes are labeled for the ingress controller in kind
kubectl label nodes --all ingress-ready=true --overwrite
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller

echo "[3/9] Deploying Online Boutique..."
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml
# Avoid watch-stream hangs by polling deployment readiness directly.
echo "  - Waiting for frontend deployment to become available (polling mode)..."
frontend_timeout_seconds=900
frontend_start_time=$(date +%s)
while true; do
  # Handle transient API timeouts without failing the whole script.
  ready_replicas=$(kubectl -n default get deploy frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  available_replicas=$(kubectl -n default get deploy frontend -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)
  desired_replicas=$(kubectl -n default get deploy frontend -o jsonpath='{.spec.replicas}' 2>/dev/null || true)

  ready_replicas=${ready_replicas:-0}
  available_replicas=${available_replicas:-0}
  desired_replicas=${desired_replicas:-1}

  if [[ "${available_replicas}" -ge "${desired_replicas}" ]]; then
    echo "  - Frontend is available (${available_replicas}/${desired_replicas})"
    break
  fi

  now=$(date +%s)
  elapsed=$((now - frontend_start_time))
  if [[ "${elapsed}" -ge "${frontend_timeout_seconds}" ]]; then
    echo "ERROR: frontend did not become available within ${frontend_timeout_seconds}s"
    kubectl -n default get deploy frontend -o wide || true
    kubectl -n default get pods -o wide || true
    exit 1
  fi

  echo "  - Frontend readiness ${available_replicas}/${desired_replicas}; retrying..."
  sleep 10
done

echo "[4/9] Deploying Elastic Stack..."
kubectl apply -f "${ROOT_DIR}/elastic-stack/00-namespace.yaml"

kubectl -n elastic-stack create secret generic elastic-credentials \
  --from-literal=elastic_password="${ELASTIC_PASSWORD}" \
  --from-literal=apm_secret_token="${APM_SECRET_TOKEN}" \
  --from-literal=kibana_password="${ELASTIC_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "${ROOT_DIR}/elastic-stack/01-elasticsearch.yaml"
kubectl apply -f "${ROOT_DIR}/elastic-stack/02-kibana.yaml"
kubectl apply -f "${ROOT_DIR}/elastic-stack/03-apm-server.yaml"

echo "  - Waiting for Elasticsearch pod to be ready..."
kubectl -n elastic-stack wait --for=condition=ready pod -l app=elasticsearch --timeout=300s

echo "  - Waiting for Elasticsearch HTTP to accept connections..."
ES_POD=$(kubectl -n elastic-stack get pods -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}')
kubectl -n elastic-stack exec "$ES_POD" -- /bin/sh -c "\
for i in 1 2 3 4 5 6 7 8 9 10; do \
  if curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health >/dev/null; then exit 0; fi; \
  sleep 5; \
done; \
exit 1"

echo "  - Creating '${ROOT_USERNAME}' superuser in Elasticsearch..."
kubectl -n elastic-stack exec "$ES_POD" -- /bin/sh -c \
  "curl -s -u elastic:${ELASTIC_PASSWORD} -X POST http://localhost:9200/_security/user/${ROOT_USERNAME} -H 'Content-Type: application/json' -d '{\"password\":\"${ROOT_PASSWORD}\",\"roles\":[\"superuser\"]}'"

echo "  - Setting kibana_system password to match ELASTIC_PASSWORD..."
kubectl -n elastic-stack exec "$ES_POD" -- /bin/sh -c \
  "curl -s -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -X POST http://localhost:9200/_security/user/kibana_system/_password -d '{\"password\":\"${ELASTIC_PASSWORD}\"}'"

echo "  - Restarting Kibana to pick up credentials..."
kubectl -n elastic-stack rollout restart deployment/kibana
kubectl -n elastic-stack rollout status deployment/kibana --timeout=300s

echo "[5/9] Installing OpenTelemetry Collector (agent + gateway)..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm upgrade --install otel-agent open-telemetry/opentelemetry-collector \
  -n elastic-stack -f "${ROOT_DIR}/otel-collector/values-agent.yaml"
helm upgrade --install otel-gateway open-telemetry/opentelemetry-collector \
  -n elastic-stack -f "${ROOT_DIR}/otel-collector/values-gateway.yaml"

echo "[6/9] Deploying infra monitoring (Metricbeat/Filebeat)..."
kubectl apply -n elastic-stack -f "${ROOT_DIR}/infrastructure/elastic-agent-policies/metricbeat-system.yaml"
kubectl apply -n elastic-stack -f "${ROOT_DIR}/infrastructure/postgres-integration/postgres-secret.yaml"
kubectl apply -n elastic-stack -f "${ROOT_DIR}/infrastructure/postgres-integration/metricbeat-postgres.yaml"
kubectl apply -n elastic-stack -f "${ROOT_DIR}/infrastructure/redis-integration/metricbeat-redis.yaml"
kubectl apply -n elastic-stack -f "${ROOT_DIR}/infrastructure/nginx-integration/metricbeat-nginx.yaml"
kubectl apply -n elastic-stack -f "${ROOT_DIR}/infrastructure/nginx-integration/filebeat-nginx.yaml"

cat <<'NOTE'
[7/9] APPLY INSTRUMENTATION PATCHES (manual)
Run the following from the Online Boutique repo root:
  git apply ~/Desktop/SRE/sre-assessment/instrumentation/cartservice/patch.diff
  git apply ~/Desktop/SRE/sre-assessment/instrumentation/paymentservice/patch.diff
  git apply ~/Desktop/SRE/sre-assessment/instrumentation/recommendationservice/patch.diff

Then patch deployments:
  kubectl patch deployment cartservice --patch-file ~/Desktop/SRE/sre-assessment/instrumentation/cartservice/deployment-env-patch.yaml
  kubectl patch deployment paymentservice --patch-file ~/Desktop/SRE/sre-assessment/instrumentation/paymentservice/deployment-env-patch.yaml
  kubectl patch deployment recommendationservice --patch-file ~/Desktop/SRE/sre-assessment/instrumentation/recommendationservice/deployment-env-patch.yaml
NOTE

cat <<'NOTE'
[8/9] RUM INTEGRATION (manual)
Edit rum/frontend-patch.diff to replace APM_SERVER_URL with a reachable APM endpoint,
then apply to the Online Boutique repo:
  git apply ~/Desktop/SRE/sre-assessment/rum/frontend-patch.diff
NOTE

cat <<'NOTE'
[9/9] Dashboards & Alerts (manual)
Import NDJSON files in Kibana:
  rum/dashboards/service-health.ndjson
  rum/dashboards/rum-performance.ndjson
  rum/dashboards/business-transactions.ndjson
  infrastructure/alerting-rules/alerts.ndjson
Then build panels per rum/dashboards/panel-specs.md and re-export.
NOTE

echo "[10/10] Exposing Kibana and APM locally..."
cat <<'NOTE'
Run these in separate terminals and keep them open:
  kubectl -n elastic-stack port-forward svc/kibana 5601:5601 --address 127.0.0.1
  kubectl -n elastic-stack port-forward svc/apm-server 8200:8200 --address 127.0.0.1

Kibana UI: http://127.0.0.1:5601
APM Server: http://127.0.0.1:8200 (API endpoint, not a UI)
NOTE

echo "Done."
