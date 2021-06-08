/*jshint esversion: 6 */
// 'use strict';
const AWS = require('aws-sdk');
const moment = require('moment');
const REGION = process.env.REGION;
const TABLE = process.env.TABLE;
const NAMESPACE = process.env.NAMESPACE;
const DEFAULT_WINDOW = 3600 * 24 * 7 * 1000; // 7 days
const DEFAULT_PERIOD_LENGTH = 'hour';
const DEFAULT_AGGREGATION = 'Average';
const LOG_LEVEL = 'DEBUG'; // DEBUG, INFO, WARN
const ACCEPTED_AGGREGATES = ['Average', 'Sum', 'Minimum', 'Maximum', 'p99', 'p95'];
const ALIAS_AGGREGATES = {Avg: 'Average', Min: 'Minimum', Max: 'Maximum', Mini: 'Minimum', Maxi: 'Maximum'};
const ALIAS_PERIODS = ['minute', 'hour', 'day', 'week', 'month', 'year'];
const PERIODS_TO_SECONDS = {minute: 60, hour: 3600, day: 3600 * 24};

/* Multi dimension metric have to follow this structure:
 * Key is the query parameter name of the metrics. For multi dimension metrics, often the plural form of the actual Cloudwatch dimension name.
 */
const MULTI_DIM_METRICS = {
  Tags: {dimension: 'Tag', cache: 'tags', metric: 'Tags'},
  'Replay talks started': {dimension: 'Talk', cache: 'talks', metric: 'Replay talks started'},
};

const AGGREGATORS = {
  Average: (values) => values.reduce((a, b) => a + b, 0) / values.length,
  Sum: (values) => values.reduce((a, b) => a + b, 0),
  Minimum: (values) => Math.min(...values),
  Maximum: (values) => Math.max(...values),
};

/**
 * Lambda requesting data from cloudwatch and using REST parameters
 */
exports.handler = async (req, context) => {
  info('New request', JSON.stringify(req, null, 2));
  debug('New context', JSON.stringify(context, null, 2));

  // Parameters:
  // - event
  // - list metric names
  // - start
  // - end
  // - period length (name)
  let eventId = req.queryStringParameters && req.queryStringParameters.event;
  if (typeof eventId !== 'string') {
    return error({code: 'missing-event', message: 'Missing required event identifier, "event"'});
  }
  eventId = eventId.toLowerCase().trim();

  // Metric names
  let metricNames = (req.multiValueQueryStringParameters.metric || [])
    .map((m) => m.split(','))
    .flat()
    .map((m) => m.trim());
  if (
    typeof metricNames === 'undefined' ||
    metricNames === null ||
    metricNames.length === 0 ||
    typeof metricNames[0] !== 'string' ||
    metricNames[0].trim().length === 0
  ) {
    return error({code: 'missing-metric', message: 'Missing required metric names, "metric"'});
  }
  if (metricNames.length > 20) {
    return error({code: 'invalid-metric-length', message: 'Too much requested metrics'});
  }

  // Aggregation options
  let metricAggregates = (
    req.multiValueQueryStringParameters.agg ||
    req.multiValueQueryStringParameters.aggregates ||
    []
  )
    .map((agg) => agg.split(','))
    .flat()
    .map((agg) => (ACCEPTED_AGGREGATES.includes(agg) ? agg : capitalized(agg.trim().toLowerCase())))
    .map((agg) => ALIAS_AGGREGATES[agg] || agg);
  if (metricAggregates.length > metricNames.length) {
    return error({code: 'invalid-aggregate-length', message: 'Too much requested metrics aggregation'});
  }
  if (metricAggregates.filter((agg) => !ACCEPTED_AGGREGATES.includes(agg)).length) {
    return error({code: 'invalid-aggregate-name', message: 'Invalid aggregation type'});
  }

  // Aggregation period
  let periodLength = (req.queryStringParameters.period || DEFAULT_PERIOD_LENGTH).toLowerCase();
  if (periodLength.match(/^[1-9]+[0-9]*$/)) {
    periodLength = parseInt(periodLength, 10);
    if (periodLength < 60) {
      return error({code: 'invalid-period-length', message: 'Invalid period length'});
    }
  } else if (!ALIAS_PERIODS.includes(periodLength)) {
    return error({code: 'invalid-period-length', message: 'Invalid period name'});
  }

  // Window
  let start = toDate(req.queryStringParameters.start) || new Date(new Date().getTime() - DEFAULT_WINDOW);
  let end = toDate(req.queryStringParameters.end) || new Date();
  if (start >= end) {
    return error({code: 'invalid-start', message: 'The parameter "end" must be greater than "start"'});
  }

  try {
    // Check event exists (and allowed next..)
    let ddb = new AWS.DynamoDB({apiVersion: '2012-10-08'});
    let event = await getEventData(ddb, eventId);
    debug(`Request metric(s) ${JSON.stringify(metricNames)} for event id ${eventId}/${event.name}`);

    // Get all requested metrics with a single "GetMetricData" call
    let cloudwatch = new AWS.CloudWatch({apiVersion: '2010-08-01'});

    /* 
            Transform (merge) these structures:
                metricNames = ['Accounts, 'Messages', 'Other']
                metricAggregates = ['Average', 'Sum']
            To this one:
                metrics = [{name:'Accounts', aggregate:'Average'}, {name:'Messages', aggregate:'Sum'},{name:'Other'}]
        */
    let metrics = metricNames
      .map((m, index) => {
        if (MULTI_DIM_METRICS[m]) {
          // Multiple dimensions metric
          let cacheProperty = MULTI_DIM_METRICS[m].cache;
          let cacheMetricDimensions = event[cacheProperty];
          if (cacheMetricDimensions && cacheMetricDimensions.length) {
            debug(`Handle multi dimensions ${MULTI_DIM_METRICS[m].metric} metric`, cacheMetricDimensions);
            return cacheMetricDimensions.map((t) => ({
              name: MULTI_DIM_METRICS[m].metric,
              dimensions: [
                {
                  Name: MULTI_DIM_METRICS[m].dimension,
                  Value: t,
                },
              ],
              aggregate: metricAggregates[index],
            }));
          }
        } else {
          // Single dimension metric
          return {name: m, aggregate: metricAggregates[index]};
        }
      })
      .filter((m) => m)
      .flat();
    return success(await getMetricData(cloudwatch, event.id, metrics, start, end, periodLength));
  } catch (err) {
    console.error('Unmanaged error', err);
    return error({code: 'data'});
  }
};

/**
 * Transform date from various type to a Date object.
 * @param {string|number} timestampOrDate ISO date or timestamp.
 * @returns The resolved date or null.
 */
function toDate(timestampOrDate) {
  if (typeof timestampOrDate === 'string') {
    if (timestampOrDate.match(/^[1-9]+[0-9]*$/)) {
      return new Date(parseInt(timestampOrDate, 10));
    }
    // ISO date
    return new Date(timestampOrDate);
  }
  if (typeof timestampOrDate === 'number') {
    return new Date(timestampOrDate);
  }
  return null;
}

// Upper case for the first char
function capitalized(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}
/**
 *
 * @param {obkect} cloudwatch Cloudwatch client.
 * @param {string} eventId Event identifier
 * @param {object[name, *aggregate]} metrics Metrics configuration to retrieve.
 * @param {int} start Start of the window.
 * @param {int} end End of the window.
 * @param {int|string} periodLength Length of a single period, exprimed in 'seconds' of named.
 * @returns The metrics data.
 */
async function getMetricData(cloudwatch, eventId, metrics, start, end, periodLength) {
  if (metrics.length === 0) {
    // No metric to get
    return {};
  }
  let needPostAggregation = periodLength === 'month' || periodLength === 'week' || periodLength === 'year';
  let metricsById = {};
  let params = {
    StartTime: start,
    EndTime: end,
    MetricDataQueries: metrics.map((m, index) => {
      let get = {
        Id: `metric_${index}`,
        MetricStat: {
          Metric: {
            Dimensions: [
              {
                Name: 'Event',
                Value: eventId,
              },
              ...(m.dimensions || []),
            ],
            MetricName: m.name,
            Namespace: NAMESPACE,
          },
          Period: PERIODS_TO_SECONDS[needPostAggregation ? 'day' : periodLength] || periodLength,
          Stat: m.aggregate || DEFAULT_AGGREGATION,
          Unit: 'Count',
        },
        //Period: 60,
        ReturnData: true,
      };
      metricsById[get.Id] = m;
      return get;
    }),
    ScanBy: 'TimestampAscending',
    //MaxDatapoints: 'NUMBER_VALUE',
    //NextToken: 'STRING_VALUE',
  };

  // TODO In order to save some useless 'put', create a diff of hash of data with a state hash stored in DynamoDB
  debug(`Cloudwatch getMetricData params ${eventId}`, params);
  let data = await cloudwatch.getMetricData(params).promise();
  info(`Cloudwatch data of ${eventId}`, data);
  let result = {};
  data.MetricDataResults.forEach((cwResult) => {
    debug(`Cloudwatch Timestamps of ${eventId}`, cwResult.Timestamps);
    let metric = metricsById[cwResult.Id];
    let agg = metric.aggregate || DEFAULT_AGGREGATION;
    let dim = metric.dimensions && metric.dimensions[0];
    let values = aggregateValues(
      cwResult.Values.map((v, index) => ({
        value: v,
        date: cwResult.Timestamps[index],
      })),
      periodLength,
      needPostAggregation,
      agg
    );

    if (dim) {
      // Multiple series, additional dimensions
      if (typeof result[metric.name] === 'undefined') {
        result[metric.name] = {};
      }
      result[metric.name][dim.Value] = values;
    } else {
      // Single serie, no dimension
      result[metric.name] = values;
    }
  });
  return result;
}

function aggregateValues(values, periodLength, needPostAggregation, agg) {
  if (!needPostAggregation) {
    return values;
  }
  // Need to aggregate the data to suit to the request period
  let periodValues = {};
  let momentPeriod = periodLength === 'week' ? 'isoWeek' : periodLength;
  values.forEach((v) => {
    let period = moment(v.date).startOf(momentPeriod).toISOString();
    if (typeof periodValues[period] === 'undefined') {
      periodValues[period] = [];
    }
    periodValues[period].push(v.value);
  });

  return Object.keys(periodValues).map((p) => ({
    date: p,
    value: AGGREGATORS[agg](periodValues[p]),
  }));
}

/**
 * Get a single event profile
 * @param {object} ddb
 * @param {string} eventId Event identifier. See DynamoDB key.
 */
async function getEventData(ddb, eventId) {
  let multiDimensions = Object.values(MULTI_DIM_METRICS).map((d) => d.cache);
  let params = {
    TableName: TABLE,
    Key: {
      id: {S: eventId},
    },
    ProjectionExpression: ['title', ...multiDimensions].join(','),
  };

  // Call DynamoDB to add the item to the table
  let data = await ddb.getItem(params).promise();
  if (typeof data.Item === 'undefined') {
    throw new HttpError(404, 'data', `Invalid event ${eventId}`);
  }

  // Flatten the DynamoDB result
  return multiDimensions.reduce(
    (acc, dim) => {
      acc[dim] = data.Item[dim] && data.Item[dim].SS;
      return acc;
    },
    {
      id: eventId,
      name: data.Item.title && data.Item.title.S,
    }
  );
}

function error(result, statusCode = 400) {
  return {
    statusCode: statusCode,
    headers: {
      'Content-type': 'application/json',
      'Access-Control-Allow-Origin': '*',
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
      'Content-type': 'application/json',
      'Access-Control-Allow-Origin': '*',
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
    this.name = 'HttpError';
    this.statusCode = statusCode;
    this.code = code;
    this.date = new Date();
    this.params = params;
  }
}

function debug(message, arg) {
  if (LOG_LEVEL === 'DEBUG') {
    if (typeof arg === 'undefined') {
      console.debug(`${message}`);
    } else {
      console.debug(`${message}`, arg);
    }
  }
}
function info(message, arg) {
  if (LOG_LEVEL === 'DEBUG' || LOG_LEVEL === 'INFO') {
    if (typeof arg === 'undefined') {
      console.info(`${message}`);
    } else {
      console.info(`${message}`, arg);
    }
  }
}
