import React, { Fragment } from "react";
import Hero from "./Hero";
import HomeContent from "./HomeContent";

export default function Home() {
  return (
    <Fragment>
      <Hero />
      <div className="box cta">
        <p className="has-text-centered">
          <span className="tag is-primary">New</span> Anything Is Possible.
        </p>
      </div>
      <HomeContent />
    </Fragment>
  );
}
