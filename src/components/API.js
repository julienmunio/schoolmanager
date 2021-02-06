// utils/API.js

import axios from "axios";

export default axios.create({
  baseURL: `${config.api.invokeUrl}/products`,
  responseType: "json",
});
