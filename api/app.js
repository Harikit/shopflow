const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({ message: 'ShopFlow API is running' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

module.exports = app;
