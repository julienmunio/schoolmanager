import React, { Component, Fragment, useState } from "react";
import Product from "./Product";
import axios from "axios";
const config = require("../config.json");

export default class Products extends Component {
  state = {
    persons: [],
  };

  fetchProducts = async () => {
    try {
      let axiosConfig = {
        headers: {
          "x-api-key": config.api.key,
        },
      };

      const res = await axios.get(
        `${config.api.invokeUrl}/products`,
        axiosConfig
      );
      this.setState({ products: res.data });
      console.log(this.state);
    } catch (err) {
      console.log(`An error has occured: ${err}`);
    }
  };

  componentDidMount = () => {
    this.fetchProducts();
  };

  render() {
    return (
      <div>
        <section className="section">
          <div className="container">
            <h1>Energy Products</h1>
            <p className="subtitle is-5">
              Invest in a clean future with our efficient and cost-effective
              green energy products:
            </p>
            <br />
            <select>
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
                    {this.state.products && this.state.products.length > 0 ? (
                      this.state.products.map((product) => (
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
      </div>
    );
  }
}
