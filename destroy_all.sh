#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="sre"

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

echo "Deleting kind cluster '${KIND_CLUSTER_NAME}' (if present)..."
if kubectl config get-contexts -o name 2>/dev/null | grep -qx "kind-${KIND_CLUSTER_NAME}"; then
  if ! run_with_timeout 180 kind delete cluster --name "${KIND_CLUSTER_NAME}"; then
    echo "ERROR: timed out deleting kind cluster. Check Docker Desktop and retry."
    exit 1
  fi
else
  echo "  - kind cluster '${KIND_CLUSTER_NAME}' not found, skipping"
fi

echo "Done."
