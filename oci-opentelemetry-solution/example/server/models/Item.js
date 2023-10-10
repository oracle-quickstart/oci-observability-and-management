// Copyright (c) 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema({
  name: String,
  description: String,
});

module.exports = mongoose.model('Item', itemSchema);
