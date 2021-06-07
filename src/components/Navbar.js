import React, { Component } from "react";
import "./Navbar.css";

export default class Navbar extends Component {
  render() {
    return (
      <nav
        className="navbar"
        role="navigation"
        aria-label="main navigation"
      >
        <div className="navbar-brand">
          <a className="navbar-item" href="/">
            <img
              src="hexal-logo-sm.png"
              width="28"
              height="28"
              alt="hexal logo"
            />
            <h4 className="logo text-light font-weight-bold"> Jul' Corp</h4>
          </a>
        </div>

        <div id="navbarBasic" className="navbar-menu">
          <div className="navbar-start d-flex flex-column ">
            <a href="/" className="navbar-item text-light text-left font-weight-bold text-decoration-none">
              Home
            </a>
            <a href="/products" className="navbar-item text-light font-weight-bold text-decoration-none">
              Products
            </a>
            <a href="/admin" className="navbar-item text-light font-weight-bold text-decoration-none">
              Admin
            </a>
          </div>

          <div className="navbar-end">
            <div className="navbar-item ">
              <div className="buttons d-flex flex-column">
                <a href="/register" className="text-light text-decoration-none">
                  Sign up
                </a>
                <a href="/login" className="text-light text-decoration-none">
                  Log in
                </a>
              </div>
            </div>
          </div>
        </div>
      </nav>
    );
  }
}
