// Elastic RUM initialization
// Replace APM_SERVER_URL with the public URL to your APM Server (e.g., via Ingress)
import { init as initApm } from '@elastic/apm-rum'

export const apm = initApm({
  serviceName: 'frontend',
  serverUrl: 'APM_SERVER_URL',
  environment: 'assessment',
  distributedTracingOrigins: ['*'],
  breakdownMetrics: true,
  instrument: true,
})
