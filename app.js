const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello from demo-service 🚀');
});

app.get('/health', (req, res) => {
  res.status(200).send('ok');
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Demo service listening on port ${port}`);
});
