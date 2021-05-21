"use strict";
const AWS = require("aws-sdk");

exports.handler = async (event, context) => {
  const documentClient = new AWS.DynamoDB.DocumentClient();

  let responseBody = "";
  let statusCode = 0;

  const { product, productname } = JSON.parse(event.body);

  const params = {
    TableName: "hexal_products",
    Key: {
      product: product,
    },
    UpdateExpression: "set productname = :n",
    ExpressionAttributeValues: {
      ":n": productname,
    },
    ReturnValues: "UPDATED_NEW",
  };

  try {
    const data = await documentClient.update(params).promise();
    responseBody = JSON.stringify(data);
    statusCode = 204;
  } catch (err) {
    responseBody = `Unable to update product : $(err)`;
    statusCode = 403;
  }

  return {
    statusCode: statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: responseBody,
  };
};
