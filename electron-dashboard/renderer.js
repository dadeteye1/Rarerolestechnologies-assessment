const lastRefresh = document.getElementById('lastRefresh');
const refreshBtn = document.getElementById('refreshBtn');

function updateLastRefresh() {
  lastRefresh.textContent = new Date().toLocaleTimeString();
}

updateLastRefresh();

const tabs = document.getElementById('tabs');
const sections = {
  apm: document.getElementById('tab-apm'),
  rum: document.getElementById('tab-rum'),
  biz: document.getElementById('tab-biz'),
  infra: document.getElementById('tab-infra')
};

tabs.addEventListener('click', (e) => {
  if (!e.target.matches('button.tab')) return;
  document.querySelectorAll('.tab').forEach((t) => t.classList.remove('active'));
  e.target.classList.add('active');
  Object.values(sections).forEach((s) => s.classList.remove('active'));
  sections[e.target.dataset.tab].classList.add('active');
});

refreshBtn.addEventListener('click', () => {
  updateLastRefresh();
  // Placeholder: hook into live data refresh when data sources are wired.
});

const baseColors = {
  teal: 'rgb(47, 210, 162)',
  amber: 'rgb(255, 176, 46)',
  red: 'rgb(255, 92, 102)',
  blue: 'rgb(58, 208, 255)',
  purple: 'rgb(140, 120, 255)'
};

function lineChart(id, labels, datasets) {
  const ctx = document.getElementById(id);
  if (!ctx) return;
  new Chart(ctx, {
    type: 'line',
    data: { labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: '#8aa0b6' } } },
      scales: {
        x: { ticks: { color: '#8aa0b6' }, grid: { color: '#1f2a37' } },
        y: { ticks: { color: '#8aa0b6' }, grid: { color: '#1f2a37' } }
      }
    }
  });
}

function barChart(id, labels, datasets) {
  const ctx = document.getElementById(id);
  if (!ctx) return;
  new Chart(ctx, {
    type: 'bar',
    data: { labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: '#8aa0b6' } } },
      scales: {
        x: { ticks: { color: '#8aa0b6' }, grid: { color: '#1f2a37' } },
        y: { ticks: { color: '#8aa0b6' }, grid: { color: '#1f2a37' } }
      }
    }
  });
}

function doughnut(id, labels, data, colors) {
  const ctx = document.getElementById(id);
  if (!ctx) return;
  new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels,
      datasets: [{ data, backgroundColor: colors }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: '#8aa0b6' } } }
    }
  });
}

function simpleTable(id, headers, rows) {
  const table = document.getElementById(id);
  if (!table) return;
  table.innerHTML = '';
  const thead = document.createElement('thead');
  const tr = document.createElement('tr');
  headers.forEach(h => {
    const th = document.createElement('th');
    th.textContent = h;
    tr.appendChild(th);
  });
  thead.appendChild(tr);
  table.appendChild(thead);
  const tbody = document.createElement('tbody');
  rows.forEach(r => {
    const tr = document.createElement('tr');
    r.forEach(c => {
      const td = document.createElement('td');
      td.textContent = c;
      tr.appendChild(td);
    });
    tbody.appendChild(tr);
  });
  table.appendChild(tbody);
}

const labels = ['-30m','-25m','-20m','-15m','-10m','-5m','now'];
lineChart('apmRed', labels, [
  { label: 'Request Rate', data: [120,132,140,128,150,162,170], borderColor: baseColors.teal },
  { label: 'Error Rate', data: [2,3,4,3,6,4,5], borderColor: baseColors.red },
  { label: 'p95 Latency (ms)', data: [220,210,240,260,230,280,300], borderColor: baseColors.amber }
]);

lineChart('apmErrors', labels, [
  { label: 'Errors', data: [4,6,3,8,10,7,5], borderColor: baseColors.red },
  { label: 'Anomaly Score', data: [0,0.1,0.2,0.6,0.9,0.4,0.2], borderColor: baseColors.purple }
]);

barChart('apmApdex', ['frontend','cart','payment','reco','product'], [
  { label: 'Apdex', data: [0.91,0.88,0.84,0.90,0.87], backgroundColor: baseColors.teal }
]);

barChart('apmBurn', ['1h','6h'], [
  { label: 'Burn Rate', data: [2.2,1.4], backgroundColor: [baseColors.red, baseColors.amber] }
]);

simpleTable('apmFailing', ['transaction', 'service', 'error %', 'p95 ms'], [
  ['checkout', 'frontend', '3.2', '410'],
  ['charge', 'payment', '4.8', '520'],
  ['addToCart', 'cart', '2.1', '360']
]);

const gaugeOptions = {
  type: 'doughnut',
  options: { circumference: 180, rotation: -90, plugins: { legend: { display: false } } }
};

function gauge(id, value, max, color) {
  const ctx = document.getElementById(id);
  if (!ctx) return;
  new Chart(ctx, {
    ...gaugeOptions,
    data: {
      labels: ['value','rest'],
      datasets: [{
        data: [value, Math.max(0, max - value)],
        backgroundColor: [color, '#1f2a37']
      }]
    }
  });
}

gauge('rumLcp', 2.4, 5, baseColors.teal);
gauge('rumInp', 180, 500, baseColors.amber);
gauge('rumCls', 0.08, 0.3, baseColors.teal);
gauge('rumTtfb', 0.7, 2, baseColors.blue);

barChart('rumWaterfall', ['DNS','TCP','TLS','TTFB','Download','DOM'], [
  { label: 'ms', data: [20,40,60,180,220,140], backgroundColor: baseColors.blue }
]);

lineChart('rumRoutes', ['/', '/cart', '/checkout', '/confirmation'], [
  { label: 'p50', data: [220,310,480,260], borderColor: baseColors.teal },
  { label: 'p90', data: [320,450,680,380], borderColor: baseColors.amber },
  { label: 'p99', data: [520,680,980,520], borderColor: baseColors.red }
]);

simpleTable('rumErrors', ['error.message','count','last seen'], [
  ['TypeError: undefined', '18', '2m'],
  ['NetworkError', '12', '5m'],
  ['ChunkLoadError', '6', '12m']
]);

doughnut('rumDevices', ['mobile','desktop'], [42,58], [baseColors.blue, baseColors.teal]);

barChart('bizFunnel', ['browse','cart','checkout','payment','confirmation'], [
  { label: 'count', data: [1200,780,520,490,455], backgroundColor: baseColors.teal }
]);

lineChart('bizConversion', labels, [
  { label: 'Conversion %', data: [38,40,41,39,42,43,44], borderColor: baseColors.teal },
  { label: 'Abandonment %', data: [22,20,19,21,18,17,16], borderColor: baseColors.red }
]);

lineChart('bizRevenue', labels, [
  { label: 'p95 latency', data: [420,460,480,520,500,540,560], borderColor: baseColors.amber },
  { label: 'revenue', data: [3200,3500,3300,3600,3800,4100,4300], borderColor: baseColors.teal }
]);

barChart('bizCart', labels, [
  { label: 'cart ops', data: [220,240,260,230,250,270,290], backgroundColor: baseColors.blue },
  { label: 'checkouts', data: [120,140,150,135,160,170,180], backgroundColor: baseColors.teal }
]);

simpleTable('bizPayments', ['reason','count'], [
  ['insufficient_funds', '12'],
  ['invalid_card', '7'],
  ['timeout', '3']
]);

barChart('bizProducts', ['p1','p2','p3','p4','p5'], [
  { label: 'add/remove', data: [120,96,80,72,64], backgroundColor: baseColors.purple }
]);

lineChart('infraNodes', labels, [
  { label: 'CPU %', data: [40,45,50,48,55,60,58], borderColor: baseColors.teal },
  { label: 'Mem %', data: [60,62,65,63,68,70,69], borderColor: baseColors.amber },
  { label: 'Disk %', data: [30,32,34,36,38,39,40], borderColor: baseColors.blue }
]);

barChart('infraK8s', ['Pending','CrashLoop','Restarts'], [
  { label: 'count', data: [2,1,5], backgroundColor: baseColors.red }
]);

lineChart('infraNginx', labels, [
  { label: '5xx %', data: [0.8,1.1,0.6,1.3,1.5,0.9,0.7], borderColor: baseColors.red },
  { label: 'p95 latency', data: [180,200,220,240,230,210,190], borderColor: baseColors.amber }
]);

lineChart('infraPg', labels, [
  { label: 'conn %', data: [40,45,50,55,60,62,58], borderColor: baseColors.teal },
  { label: 'cache hit %', data: [98,97,96,97,98,98,99], borderColor: baseColors.blue }
]);

lineChart('infraRedis', labels, [
  { label: 'mem %', data: [50,55,58,60,62,64,63], borderColor: baseColors.amber },
  { label: 'evictions', data: [1,2,1,3,2,1,1], borderColor: baseColors.red }
]);

lineChart('infraNetpol', labels, [
  { label: 'denied', data: [3,4,5,6,4,3,2], borderColor: baseColors.red }
]);

simpleTable('infraAlerts', ['rule','status','last'], [
  ['High CPU', 'active', '1m'],
  ['Disk <10%', 'ok', '10m'],
  ['NGINX 5xx spike', 'ok', '3m']
]);
