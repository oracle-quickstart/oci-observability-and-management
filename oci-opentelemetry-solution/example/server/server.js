// Copyright (c) 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// MongoDB connection setup
mongoose.connect('[MONGODB CONNECTION STRING]', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const connection = mongoose.connection;
connection.once('open', () => {
  console.log('MongoDB database connection established successfully');
});

// Use your routes
const itemsRouter = require('./routes/items');
app.use('/items', itemsRouter);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
