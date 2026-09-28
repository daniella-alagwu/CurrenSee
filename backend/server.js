import express from "express";
import cors from "cors";
import "./config/env.js";
import userRoutes from "./routes/userRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";

const app = express();
app.use(cors());
app.use(express.json());


app.use((req, res, next) => {
  const startedAt = Date.now();
  res.on("finish", () => {
    console.log(
      `${req.method} ${req.originalUrl} ${res.statusCode} ${Date.now() - startedAt}ms`
    );
  });
  next();
});

app.get("/", (req, res) => {
  res.send("Backend running");
});

app.use("/api/users", userRoutes);
app.use("/api/admin", adminRoutes);


app.use((req, res) => {
  res.status(404).json({ error: { code: "NOT_FOUND", message: "Route not found." } });
});


app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: { code: "SERVER_ERROR", message: "Something went wrong." } });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
