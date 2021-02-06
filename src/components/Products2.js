import React, { Component } from "react";
import Product from "./Product";
import axios from "axios";
const config = require("../config.json");

export default class Products extends Component {
  state = {
    newproduct: null,
    products: [],
  };

  fetchProducts = async () => {
    // add call to AWS API Gateway to fetch products here
    // then set them in state
    try {
      // console.log(`'${config.api.invokeUrl}/products`);
      const res = await axios.get(`${config.api.invokeUrl}/products`);
      this.setState({ products: res.data });
    } catch (err) {
      console.log(`An error has occured: ${err}`);
    }
  };

  componentDidMount = () => {
    this.fetchProducts();
  };

  Products() {
    return (
      <>
        <section className="section">
          <div className="container">
            <h1>Energy Products</h1>
            <p className="subtitle is-5">
              Invest in a clean future with our efficient and cost-effective
              green energy products:
            </p>

            <select /*onChange={(e) => sortArray(e.target.value)}*/>
              <option value="product">id</option>
              <option value="productname">First Name</option>
              <option value="fullname">Full Name</option>
            </select>

            <h1> </h1>

            <br />
            <div className="columns">
              <div className="column">
                <div className="tile is-ancestor">
                  <div className="tile is-4 is-parent  is-vertical">
                    {console.log(this.state.products)}
                    {this.state.products && this.state.products.length > 0 ? (
                      this.state.products.map((product) => (
                        <Product
                          key={product.product}
                          name={product.productname}
                          id={product.product}
                          fullName={product.fullname}
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
}
