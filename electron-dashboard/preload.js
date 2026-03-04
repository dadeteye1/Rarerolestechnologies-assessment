const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('dashboardConfig', {
  elasticUrl: process.env.ELASTIC_URL || '',
  kibanaUrl: process.env.KIBANA_URL || '',
});
