import React, { Component, Fragment, useState } from "react";
import Product from "./Product";
import axios from "axios";
const config = require("../config.json");

export default class Products extends Component {
  state = {
    persons: []
  };

  componentDidMount() {
    fetchProducts = async () => {
      try {
        const res = await axios.get(`${config.api.invokeUrl}/products`);
        this.setState({ products: res.data });
        console.log(this.state);
      } catch (err) {
        console.log(`An error has occured: ${err}`);
      }
    };
  };

  // ! Hook
  const [sortedField, setSortedField] = useState(null);

  // ! Sorting function
  let sortedProducts = [...products];
  if (sortedField !== null) {
    sortedProducts.sort((a, b) => {
      if (a[sortedField] < b[sortedField]) {
        return -1;
      }
      if (a[sortedField] > b[sortedField]) {
        return 1;
      }
      return 0;
    });
  }

  return (
    <>
      <section className="section">
        <div className="container">
          <h1>Energy Products</h1>
          <p className="subtitle is-5">
            Invest in a clean future with our efficient and cost-effective green
            energy products:
          </p>
          <br />
          <select onChange={(e) => setSortedField(e.target.value)}>
            <option value="product">product</option>
            <option value="productname">productname</option>
            <option value="fullname">fullname</option>
          </select>
          <h1>" "</h1>
          <br />
          <div className="columns">
            <div className="column">
              <div className="tile is-ancestor">
                <div className="tile is-4 is-parent  is-vertical">
                  {this.state.sortedProducts &&
                  this.state.sortedProducts.length > 0 ? (
                    this.state.sortedProducts.map((product) => (
                      <Product
                        name={product.productname}
                        id={product.id}
                        key={product.id}
                      />
                    ))
                  ) : (
                    <div className="tile notification is-warning">
                      No products available
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}