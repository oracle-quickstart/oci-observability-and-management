// Copyright (c) 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React, { Component } from 'react';
import axios from 'axios';

class App extends Component {
  constructor() {
    super();
    this.state = {
      items: [],
      name: '',
      description: '',
      editItem: null,
    };
  }

  componentDidMount() {
    this.getItems();
  }

  getItems = () => {
    axios.get('/items').then((response) => {
      this.setState({ items: response.data });
    });
  };

  // Function to handle form submission for creating or updating items
  handleSubmit = (e) => {
    e.preventDefault();

    const { name, description, editItem } = this.state;

    if (!name || !description) {
      alert('Please fill in all fields');
      return;
    }

    if (editItem) {
      // Update an existing item
      axios
        .put(`/items/${editItem._id}`, { name, description })
        .then(() => {
          this.getItems();
          this.setState({ name: '', description: '', editItem: null });
        })
        .catch((error) => console.error('Error updating item:', error));
    } else {
      // Create a new item
      axios
        .post('/items', { name, description })
        .then(() => {
          this.getItems();
          this.setState({ name: '', description: '' });
        })
        .catch((error) => console.error('Error creating item:', error));
    }
  };

  // Function to handle item deletion
  handleDelete = (id) => {
    axios
      .delete(`/items/${id}`)
      .then(() => {
        this.getItems();
      })
      .catch((error) => console.error('Error deleting item:', error));
  };

  // Function to handle item editing
  handleEdit = (item) => {
    this.setState({ name: item.name, description: item.description, editItem: item });
  };

  // Function to clear the form
  handleCancel = () => {
    this.setState({ name: '', description: '', editItem: null });
  };

  render() {
    const { items, name, description, editItem } = this.state;

    return (
      <div>
      <h1>Product Inventory</h1>
        
        {/* Form for creating/updating items */}
        <form onSubmit={this.handleSubmit}>
          <input
            type="text"
            placeholder="Product Name"
            value={name}
            onChange={(e) => this.setState({ name: e.target.value })}
          />
          <input
            type="text"
            placeholder="Product Description"
            value={description}
            onChange={(e) => this.setState({ description: e.target.value })}
          />
          <button type="submit">{editItem ? 'Update Product' : 'Add Product'}</button>
          <button type="button" onClick={this.handleCancel}>
            Cancel
          </button>
        </form>

        {/* List of items */}
        <ul>
          {items.map((item) => (
            <li key={item._id}>
              {item.name} - {item.description}
              <button onClick={() => this.handleEdit(item)}>Edit</button>
              <button onClick={() => this.handleDelete(item._id)}>Delete</button>
            </li>
          ))}
        </ul>
      </div>
    );
  }
}

export default App;
