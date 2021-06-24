/*jshint esversion: 6 */
"use strict";
const AWS = require("aws-sdk");
const REGION = process.env.REGION;
const TABLE = process.env.TABLE;
const NAMESPACE = process.env.NAMESPACE;
const IP_ADDRESS = process.env.IP_ADDRESS;
const LOG_LEVEL = "DEBUG"; // DEBUG, INFO, WARN

/**
 * Lambda requesting data from cloudwatch and using REST parameters
 */
exports.handler = async (req, context) => {
  info("New request", JSON.stringify(req, null, 2));
  debug("New context", JSON.stringify(context, null, 2));

  try {
    if (req.headers["X-Forwarded-For"] == IP_ADDRESS) {
      let eventId = "0211540K";
      let classroom = "a";
      let ddb = new AWS.DynamoDB({ apiVersion: "2012-10-08" });
      let studentList = await getStudentList(ddb, eventId, classroom);

      debug(`Request metric(s) for event id ${eventId}`);

      return success(studentList);
    }
  } catch (err) {
    console.error("Unmanaged error", err);
    return error({ code: "data" });
  }
};

async function getStudentList(ddb, eventId, classroom) {
  debug(`Key used ${eventId}`);
  debug(`Key used ${typeof eventId}`);

  let params = {
    Key: {
      school: { S: eventId },
      classroom: { S: classroom },
    },
    TableName: TABLE,
  };
  return await ddb.getItem(params).promise();
}

/**
 * Transform date from various type to a Date object.
 * @param {string|number} timestampOrDate ISO date or timestamp.
 * @returns The resolved date or null.
 */
function toDate(timestampOrDate) {
  if (typeof timestampOrDate === "string") {
    if (timestampOrDate.match(/^[1-9]+[0-9]*$/)) {
      return new Date(parseInt(timestampOrDate, 10));
    }
    // ISO date
    return new Date(timestampOrDate);
  }
  if (typeof timestampOrDate === "number") {
    return new Date(timestampOrDate);
  }
  return null;
}

// Upper case for the first char
function capitalized(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function error(result, statusCode = 400) {
  return {
    statusCode: statusCode,
    headers: {
      "Content-type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify(result),
  };
}

function success(result, statusCode = 200, message = null) {
  if (message) {
    info(message);
  }
  return {
    statusCode: statusCode,
    headers: {
      "Content-type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify(result),
  };
}

class HttpError extends Error {
  constructor(statusCode = 400, code = null, ...params) {
    super(...params);
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, HttpError);
    }
    this.name = "HttpError";
    this.statusCode = statusCode;
    this.code = code;
    this.date = new Date();
    this.params = params;
  }
}

function debug(message, arg) {
  if (LOG_LEVEL === "DEBUG") {
    if (typeof arg === "undefined") {
      console.debug(`${message}`);
    } else {
      console.debug(`${message}`, arg);
    }
  }
}

function info(message, arg) {
  if (LOG_LEVEL === "DEBUG" || LOG_LEVEL === "INFO") {
    if (typeof arg === "undefined") {
      console.info(`${message}`);
    } else {
      console.info(`${message}`, arg);
    }
  }
}
