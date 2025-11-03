const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('🚀 CI/CD Pipeline working successfully done...!');
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
