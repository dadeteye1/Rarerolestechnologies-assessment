# Kibana Dashboard Panel Specs (Concrete)

This file defines the exact panels, data views, and queries to build in Kibana Lens/TSVB/Vega.
Use these specs to create the visualizations, then export Saved Objects to replace the NDJSON placeholders.

## Data Views
- APM traces: `traces-apm*`
- APM metrics: `metrics-apm*` and `metrics-*`
- RUM: `rum-*` and `apm-*`
- Logs: `logs-*`
- Infra: `metrics-*`, `logs-*`, `filebeat-*`, `metricbeat-*`

## Dashboard 1: Service Health Overview
1. **RED Metrics (per service)**
   - Type: Lens (timeseries)
   - Data: `traces-apm*`
   - KQL: `processor.event: "transaction"`
   - Break down by: `service.name`
   - Metrics:
     - Rate: `counter: transaction.duration.summary.count` (per minute)
     - Errors: `filter transaction.result: "HTTP 5xx" OR event.outcome: "failure"`
     - Duration p95: `transaction.duration.us` (percentile 95)

2. **Apdex per service**
   - Type: TSVB or Lens (formula)
   - Formula: `apdex(transaction.duration.us, 300000)`
   - Break down by: `service.name`

3. **Service Dependency Map**
   - Type: APM Service Map (built-in) or Vega graph

4. **Error Rate Trend**
   - Type: Lens (timeseries)
   - KQL: `processor.event: "transaction"`
   - Metric: `count` filtered by `event.outcome: failure` / total

5. **Top Failing Transactions**
   - Type: Lens table
   - Metric: `count`
   - Rows: `transaction.name`, `service.name`
   - Filter: `event.outcome: failure`

6. **Latency p50/p95/p99**
   - Type: Lens (timeseries)
   - Metric: `transaction.duration.us` (p50/p95/p99)
   - Break down by `service.name`

## Dashboard 2: Frontend / RUM Performance
1. **Core Web Vitals (LCP, FID/INP, CLS, TTFB)**
   - Type: Lens gauge
   - Data: `rum-*`
   - Fields: `transaction.marks.*` or `user_experience.*` depending on RUM mapping

2. **Page Load Waterfall**
   - Type: Lens (stacked bar)
   - Fields: `transaction.marks.navigation_timing.*`

3. **Route Latencies p50/p90/p99**
   - Type: Lens (timeseries)
   - KQL: `transaction.type: "page-load"`
   - Break down by: `url.path`

4. **JS Errors Table**
   - Type: Lens table
   - Data: `apm-*` (errors)
   - KQL: `processor.event: "error" AND error.type: "Error"`
   - Rows: `error.message`, `service.name`, `user_agent.name`

5. **Geo Latency**
   - Type: Maps
   - Data: `client.geo.*`
   - Metric: avg `transaction.duration.us`

6. **Device Split**
   - Type: Lens (donut)
   - Field: `user_agent.device.name` or `user_agent.device.type`

## Dashboard 3: Business Transaction Monitoring
1. **Checkout Funnel**
   - Type: Lens or TSVB
   - Stages: `browse`, `add_to_cart`, `checkout`, `payment`, `confirmation`
   - Use `transaction.name` or custom span names

2. **Conversion Rate Trend**
   - Type: Lens (formula)
   - Formula: `count(confirmation) / count(browse)`

3. **Cart Abandonment**
   - Type: Lens (timeseries)
   - Formula: `count(add_to_cart) - count(confirmation)`

4. **Revenue vs Latency**
   - Type: Lens (dual axis)
   - Metric 1: avg `transaction.duration.us` (checkout)
   - Metric 2: sum `order.total` (custom attribute)

5. **Payment Failures by Reason**
   - Type: Lens table
   - KQL: `transaction.name: "payment" AND event.outcome: "failure"`
   - Rows: `error.message`, `service.name`

## Dashboard 4: Infrastructure / Platform (optional)
1. Node CPU/Memory/Disk/Network (Lens)
2. Pod restarts & crashloops (Lens)
3. NGINX 5xx rate, latency p95 (Lens)
4. Postgres connections + cache hit (Lens)
5. Redis memory + evictions (Lens)
6. Network policy denies (Lens)

