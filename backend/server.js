const express = require("express");
const multer = require("multer");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static("uploads"));

let activities = [];

// Multer config (image upload)
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/");
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + "-" + file.originalname);
  }
});
const upload = multer({ storage: storage });

// POST: Add Activity
app.post("/activity", upload.single("image"), (req, res) => {
  const { latitude, longitude, timestamp } = req.body;

  const newActivity = {
    id: Date.now().toString(),
    latitude: parseFloat(latitude),
    longitude: parseFloat(longitude),
    timestamp,
    imagePath: req.file ? `/uploads/${req.file.filename}` : null
  };

  activities.push(newActivity);
  res.json(newActivity);
});

// GET: All Activities
app.get("/activity", (req, res) => {
  res.json(activities);
});

// DELETE: Activity by ID
app.delete("/activity/:id", (req, res) => {
  const id = req.params.id;
  activities = activities.filter(a => a.id !== id);
  res.json({ success: true });
});

// Start Server
app.listen(3000, () => {
  console.log("Server running on port 3000");
});