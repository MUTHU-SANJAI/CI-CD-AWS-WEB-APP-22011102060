const express = require("express");
const app = express();

app.get("/", (req, res) => res.send("CI/CD pipeline successfully deployed!"));
app.get("/health", (req, res) => res.sendStatus(200));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Server running on port ${port}`));
