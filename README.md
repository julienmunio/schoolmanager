# Introduction

Setup the analtics infractucture.

# API

## API Requirement

The API corresponds to the infrastructure components: Lambda, API Gateway, S3,... 
These components are managed by `terraform`.

- Terraform 0.14+
- NodeJS 14+
- Write access to bucket `bemyapp-terraform` on AWS account `249124023636`
- Full access to traget AWS account:
- - `077292163318`: Dev account
- - `753517461178`: Prod account

## Create Lambda layers

Only once, for each target AWS account (dev and production), create the Lambda layers. Layers are a kind of template or base image (such as `Docker`) for Lambda.
These layers need to to be created only one time, and are managed in separated terraform states.

``` bash
git clone https://github.com/BeMyAppTech/idt-scripts-aws-analytics
cd layers
for ENV in "dev" "prod"; do
    for LAYER in "mongodb" "nodejs" "nodejs_axios"; do
        bash -c '
        cd '$LAYER' \
        && terraform init -backend-config=backend-'$ENV'.tfvars \
        && terraform apply -auto-approve -var-file="main-'$ENV'.tfvars" \
        '
    done
done
```

## Create the main infrastructure

``` bash
git clone https://github.com/BeMyAppTech/idt-scripts-aws-analytics
cd api

# Target environment to create/update
ENV="dev"

# Initialize backend
terraform init -backend-config="backend-$ENV.tfvars"
echo "State will be in: s3://bemyapp-terraform/$ENV/main.tfstate"

# (Optionl) Terraform validation to check for syntax errors
terraform validate

# Update the infrastructure
terraform apply -auto-approve -var-file="main-$ENV.tfvars"
``` 

Expected outputs should look like:

``` text
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

api_gateway = "https://v1g4xjo2gh.execute-api.eu-west-1.amazonaws.com/dev/"
api_gateway_curl_metrics = "curl -X GET https://v1g4xjo2gh.execute-api.eu-west-1.amazonaws.com/dev/api/metric -H \"x-api-key:---\""
api_gateway_key = "---"
website = "https://dev.analytic.bemyappcloud.com/"
```

Note the CURL output you can use to check the API results.

## Metrics API

### Get metrics `GET /api/metric`

This API can be used to get some metrics.

#### Get metrics `GET /api/metric` options

Options are:
- `event`: Event identifier. When undefined, all events are retrieved.
- `start`: ISO Date or timestamp of first date of retrived metrics. Default is now minus 1 month.
- `end`: ISO Date or timestamp of last date of retrived metrics. Default is now.
- `period` Aggregation period. Accepted values are: `minute`, `hour` (default), `day`, `week`, `month` and `year`. 
- - Greater is this value, the smaller amount of data points is returned. 
- - For `week` (ISO week) period, the date resolution is the day: hours, minutes... are set to 0, and the day starts with Monday. The first week of the year may be another day. See ISO 8601 specification. For `month` period, day is set to the first day of the month. The same logic applies to `month` and `year` periods. 
- - A numeric value (seconds) is also accepted, for sample `period=7200` will aggregate the data points over `2 hours`. Although `period=2678400` corresponds to `31` full days, this is not equivalent to `period=month`. The first form produces aggregated data over group of `31` follonging days. The second form produces aggregated data over each month and may leads to more than `1` month: some months have less than `31` days.
- `metric`: Corresponds to the metric name. Up to `20` metrics can be retrieved. Case is sensitive. Multiple occurences are accepted, either with multiple query parameters, either with `,` separator.
- `aggregation` or `agg`: Aggregation mode for a period. Accepted values are: `Average` (default), `Sum`, `p99` (Percentile), `p95`, `Minimum` and `Maximum`. Alias `Min`, `Max` and `Avg` are accepted. Case is not sensitive. Multiple occurences are accepted. Either with multiple query parameters, either with `,` separator. Applies to the `metric` parameter(s) in the same order.

For multiple entries, the amount of data of each metric may differs. Depending on the aggregation, some timelines can have "holes": period of time without receiving data.

#### Test metric API

Directly using API Gateway with the required API key as outputed by the Terraform command.

``` bash
curl -X GET -v "https://v1g4xjo2gh.execute-api.eu-west-1.amazonaws.com/dev/api/metric" -H "x-api-key:---"
```

Calling API Gateway via Cloudfront. No API is required since the Cloudfront distribution is protected by a WAF with IP protection.

``` bash
curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/metric"
```

Single metric data:
``` bash
curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/metric?event=ideation-code-love-hack&metric=Accounts"
```

Multiple metrics data:
``` bash
curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/metric?event=ideation-code-love-hack&metric=Room%20Size&metric=Accounts"
```

Multiple metrics data sample with `aggregation` options:
``` bash
EVENT="ideation-code-love-hack"
PERIOD="hour"
START="2021-02-23 02:45 UTC"
END="2021-03-10 02:45 UTC"
START=$(echo "$START"|sed 's/ /%20/g')
END=$(echo "$END"|sed 's/ /%20/g')
AGG1="Average"
AGG2="Sum"
curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/metric?event=$EVENT&metric=Room%20Size&metric=Accounts&start=$START&end=$END&agg=$AGG1&agg2=$AGG2&period=$PERIOD"
```

Sample data:
``` json
{
    "Room Size": [
        {
            "value": 78,
            "date": "2021-02-23T05:41:00.000Z"
        },
        {
            "value": 82,
            "date": "2021-02-23T11:41:00.000Z"
        },
        {
            "value": 82,
            "date": "2021-02-23T12:41:00.000Z"
        },
        {
            "value": 99,
            "date": "2021-02-23T13:41:00.000Z"
        }
    ],
    "Room Users": [
        {
            "value": 122,
            "date": "2021-02-23T05:41:00.000Z"
        },
        {
            "value": 132,
            "date": "2021-02-23T12:41:00.000Z"
        },
        {
            "value": 152,
            "date": "2021-02-23T13:41:00.000Z"
        }
    ]
}
```

#### Multi-dimension metrics

Multiple dimensions metrics are metrics having a sub category.
For sample, the metric `Tags` has the dimensions `event` and the `tag` name itself. Each tag within a single event has it's own timeline and data points. Instead of querying each tag from the HTTP API `/api/metric`, the API exposes all `Tags` metrics (CloudWatch) with a single `GET /api/metric?metric=Tags`. The API makes underlyingly the CloudWatch calls to retrieve data and groups the values by actual tage name.

Sample:
``` bash
curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/metric?event=ideation-code-love-hack&metric=Tags&metric=Accounts&period=day"
```

``` json
{
    "Tags":{
        "AI/ML":[
            {"value":194.76,"date":"2021-03-30T09:06:00.000Z"},
            {"value":195,"date":"2021-03-31T09:06:00.000Z"}
        ],
        "App Development":[
            {"value":259.76,"date":"2021-03-30T09:06:00.000Z"},
            {"value":261.5416666666667,"date":"2021-03-31T09:06:00.000Z"}
        ]
    },
    "Accounts": [
        {"value":122,"date":"2021-03-30T09:06:00.000Z"},
        {"value":134,"date":"2021-03-31T09:06:00.000Z"}
    ]
}
```

Note the different structure of `Tags` metric (multi-dimension) and `Accounts` metric (single dimension). 
For now only one additional dimension is supported, but more dimensions could be added, adding more nested structures.

### Put metrics `POST /api/metric`

This API can be used to put some metrics.

Options must me post in the body with the following structure:
``` json
{
    "event" : "ideation-code-love-hack",
    "metrics" : [
        {
            "name" : "Messages",
            "value": 34,
            "date" : "2021-03-22T14:49:35.874Z"
        }
    ]
}
```
Several metrics related to a single event can be publiched with a single API call. `date` attribute is optionnal, when ommited is set to current date, and timestamp format is also accepted.

Sample
``` bash
curl -X POST -v "https://dev.analytic.bemyappcloud.com/api/metric" \
    -H "content-type:application/json" \
    -d '{
            "event" : "ideation-code-love-hack",
            "metrics" : [
                {
                    "name" : "Messages",
                    "value": 2
                }
            ]
        }'
```

### Get tracked events `POST /api/events`

Return details of all active events. An active event is an evant with `stop` date greater than the current time minus 1 month. 
This list is continuously updated (every 12 hours) by a backend process looking for new databases in the MongoDB server. See the NodeJS code of `lambda-track_events.js`for more information.

``` bash
curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/event"
```
Sample data:

```json
[
    {"id":"ideation-calibre-regression","title":"BeMyApp","labels":["Business","Education","Healthcare"],"start":"2021-02-25T10:33:46.000Z","stop":"2021-03-27T10:33:46.000Z"},
    {"id":"ideation-instep","title":"Infosys InStep Internship Program","start":"2020-07-01T00:00:00.000Z","stop":"2021-07-07T00:00:00.000Z"}
]
```

Note : `labels` and `start` attributes may not be available.

## Kinesis / Firehose

### Agent setup

``` bash
ssh ec2-user@52.208.130.76
sudo -i
yum install –y aws-kinesis-agent

WATCH_CONF='/etc/aws-kinesis/agent.json'
WATCH_LOG="/var/log/kinesis-watch.log"

KINESIS_STREAM="bemyapp-analytics-dev"
KINESIS_ENDPOINT="kinesis.eu-west-1.amazonaws.com"
FIREHOSE_STREAM="bemyapp-analytics-dev"
FIREHOSE_ENDPOINT="firehose.eu-west-1.amazonaws.com"

cat $WATCH_CONF
touch "$WATCH_LOG"
# awsAccessKeyId
# awsSecretAccessKey
echo '{
  "cloudwatch.emitMetrics": true,
  "kinesis.endpoint": "'$KINESIS_ENDPOINT'",
  "firehose.endpoint": "'$FIREHOSE_ENDPOINT'",
  "flows": [
    {
      "filePattern": "'$WATCH_LOG'",
      "deliveryStream": "'$FIREHOSE_STREAM'",
      "dataProcessingOptions": [
        {
            "optionName": "LOGTOJSON",
            "logFormat": "COMMONAPACHELOG",
            "matchPattern": "^METRIC\\s+\\[([^]]+)\\]\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)\\s+(.*)",
            "customFieldNames": [ "date", "event", "metric", "value","message" ]
        }
      ]
    }
  ]
}' > $WATCH_CONF

# Both Firehose and Kinesis Data streams
#echo '{
#  "cloudwatch.emitMetrics": true,
#  "kinesis.endpoint": "'$KINESIS_ENDPOINT'",
#  "firehose.endpoint": "'$FIREHOSE_ENDPOINT'",
#  "flows": [
#    {
#      "filePattern": "'$WATCH_LOG'",
#      "kinesisStream": "'$KINESIS_STREAM'"
#    },{
#      "filePattern": "'$WATCH_LOG'",
#      "deliveryStream": "'$FIREHOSE_STREAM'"
#    }
#  ]
#}' > $WATCH_CONF

chkconfig aws-kinesis-agent on
service aws-kinesis-agent restart
#service aws-kinesis-agent stop
#service aws-kinesis-agent start

EVENT='ideation-code-love-hack'
METRIC='Messages'

echo "METRIC [2021-03-27 17:22:23] ${EVENT} ${METRIC} 50 ${METRIC}\tFROM KINESIS AGENT v7" >> $WATCH_LOG
echo "METRIC [2021-03-18 09:1:23] ${EVENT} ${METRIC} 1 ${METRIC}\tFROM KINESIS AGENT v8" >> $WATCH_LOG
tail -f /var/log/aws-kinesis-agent/aws-kinesis-agent.log
```

### Put records from nodeJS

Ses code sample in `firehose-sample/index.js`. 
Sample NodeJS:
```javascript
const AWS = require('aws-sdk');
const KINESIS_STREAM = "bemyapp-analytics-dev";
const EVENT = 'ideation-code-love-hack';
const METRIC = 'Messages';

AWS.config.update({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
});
AWS.config.apiVersions = {
    firehose: '2015-08-04',
    region: process.env.AWS_REGION
};
const firehose = new AWS.Firehose();

let params = {
    Record: {
        //Data: `${EVENT};${METRIC};1;${METRIC}\tFROM LAMBDA PROXY`,
        Data: JSON.stringify({
            event: EVENT,
            metric: METRIC,
            value: value,
            date: new Date(),
        })
    },
    DeliveryStreamName: KINESIS_STREAM
};
firehose.putRecord(params, function (err) {
    if (err) {
        console.error("couldn't stream", err.stack);
    } else {
        console.log("INFO - successfully send stream");
    }
});

```

## API request Athena report

Requesting an export of the whole analytics table. Note that requesting a report from Athena is an asynchronous operation. The API result is only an execution query identifier: `QueryExecutionId`. This identifier can be used to download the actual report file when available, and can also be used to track the status of the execution.

A repport requires up to 15 minutes to be completed.

### API Request Athena with a specific query

``` bash
RESULT_ID="$(curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/athena" | jq -r '.QueryExecutionId')"
# {"QueryExecutionId":"3f85cd01-7b10-4e69-a14a-c50f7786eb76"}

curl -X GET -v "https://dev.analytic.bemyappcloud.com/exports/$RESULT_ID.csv"
```

By default, without the query attribute, the executed query is `SELECT * FROM bemyapp-analytics-dev.bemyapp-analytics-dev-datalake;`.
The following sample code overrides this behavior:
``` bash
RESULT_ID="$(curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/athena?query=SELECT%20DISTINCT%20event%20%20FROM%20%22bemyapp-analytics-dev%22.%22bemyapp-analytics-dev-datalake%22%3B" \
  | jq -r '.QueryExecutionId')"
curl -X GET -v "https://dev.analytic.bemyappcloud.com/exports/$RESULT_ID.csv"
```

`POST` method is also accepted:
``` bash
RESULT_ID="$(curl -X POST -v "https://dev.analytic.bemyappcloud.com/api/athena" \
  -H "content-type:application/json" \
  -d '{
        "query" : "SELECT DISTINCT event FROM \"bemyapp-analytics-dev\".\"bemyapp-analytics-dev-datalake\";"
      }'\
  | jq -r '.QueryExecutionId')"
curl -X POST -v "https://dev.analytic.bemyappcloud.com/exports/$RESULT_ID.csv"
```

### API Request Athena with a named query

Using a named query simplifies the API usage by providing a logic name instead of a full SQL query.

The saved Athena queries are the ones defined there : https://eu-west-1.console.aws.amazon.com/athena/saved-queries/home
Administrators can create their own queries and name them. Currently there is no filter, but a naming convention could be creted to control the exposed Athena queries.

``` bash
RESULT_ID="$(curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/athena?name=saved-query1" \
  | jq -r '.QueryExecutionId')"
curl -X GET -v "https://dev.analytic.bemyappcloud.com/exports/$RESULT_ID.csv"
```

`POST` method is also accepted:
``` bash
RESULT_ID="$(curl -X POST -v "https://dev.analytic.bemyappcloud.com/api/athena" \
  -H "content-type:application/json" \
  -d '{
        "name" : "saved-query1"
      }'\
  | jq -r '.QueryExecutionId')"
curl -X POST -v "https://dev.analytic.bemyappcloud.com/exports/$RESULT_ID.csv"
```

### Tracking the Athena query result

The returned `QueryExecutionId` can be used to check the status of requested report.

``` bash
curl -X GET -v "https://dev.analytic.bemyappcloud.com/api/athena?id=4b69f9f4-3834-411a-bcea-b8e3889874c5"
```

Sample output of an not yet finished export:
``` json
{
    "QueryExecution":{
        "QueryExecutionId":"4b69f9f4-3834-411a-bcea-b8e3889874c5",
        "Query":"SELECT DISTINCT event  FROM \"bemyapp-analytics-dev\".\"bemyapp-analytics-dev-datalake\"",
        "StatementType":"DML",
        "ResultConfiguration":{
            "OutputLocation":"s3://bemyapp-analytics-dev-datalake/exports/4b69f9f4-3834-411a-bcea-b8e3889874c5.csv"},
            "QueryExecutionContext":{
                "Status":{
                    "State":"RUNNING",
                    "SubmissionDateTime":"2021-04-04T10:40:03.468Z"
                },
                "Statistics":{
                    "TotalExecutionTimeInMillis":395,
                    "QueryQueueTimeInMillis":275
                }
                ...
            }
        }
    }
```

Sample output of afinished export:
``` json
{
    "QueryExecution":{
        "QueryExecutionId":"4b69f9f4-3834-411a-bcea-b8e3889874c5",
        "Query":"SELECT DISTINCT event  FROM \"bemyapp-analytics-dev\".\"bemyapp-analytics-dev-datalake\"",
        "StatementType":"DML",
        "ResultConfiguration":{
            "OutputLocation":"s3://bemyapp-analytics-dev-datalake/exports/4b69f9f4-3834-411a-bcea-b8e3889874c5.csv"},
            "QueryExecutionContext":{
                "Status":{
                    "State":"SUCCEEDED",
                    "SubmissionDateTime":"2021-04-04T10:25:57.240Z",
                    "CompletionDateTime":"2021-04-04T10:25:58.185Z"
                },
                "Statistics":{
                        "EngineExecutionTimeInMillis":780,
                        "DataScannedInBytes":1309,
                        "TotalExecutionTimeInMillis":945,
                        "QueryQueueTimeInMillis":113,
                        "QueryPlanningTimeInMillis":398,
                        "ServiceProcessingTimeInMillis":52
                }
                ...
            }
        }
    }
```

When the requested export does not exist, the result is a `400` http error code:
``` json
{"code":"InvalidRequestException"}
```

# Website

## Website Requirement

The API corresponds to the infrastructure components: Lambda, API Gateway, S3,... 
These components are managed by `terraform`.

- Terraform 0.14+
- NodeJS 12+
- Write access to bucket `bemyapp-terraform` on AWS account `249124023636`
- S3 access, bucket `bemyapp-analytics-dev`or `bemyapp-analytics-prod` depending on the target environment.

This part covers the setup, test and the deployment of the website.
The code is deployed to the S3 bucket created in the previous steps by Terraform.

## Website Setup

The website lifecycle is managed by `gulp`. All tasks are also ported in `npm`

```
cd website
npm install gulp-cli -g
npm install
```

# Test

Serves the website, open the browser in `http://localhost:3000/`

```
gulp
```

While the gulp command is running, files in the `assets/scss/`, `assets/js/` and `components/` folders will be monitored for changes. Files from the `assets/scss/` folder will generate injected CSS.

Hit `CTRL+C` to terminate the gulp command. This will stop the local server from running.

## Theme without Sass, Gulp or npm

If you'd like to get a version of our theme without Sass, Gulp or npm, run the following command:

```
gulp build:dev
```

This will generate a folder `html&css` which will have unminified CSS, HTML and JavaScript.

## Minified version

If you'd like to compile the code and get a minified version of the HTML and CSS just run the following Gulp command:

```
gulp build:dist
```

This will generate a folder `dist` which will have minified CSS, HTML and JavaScript.

## Website notes

Sample barchart cross-event idea: http://bl.ocks.org/charlesdguthrie/11356441
BillboardJS: https://naver.github.io/billboard.js/demo/#API.AxisRange

## Deployment

This task builds the website, deploys it to S3 and invalidates the Cloudfront cache.
This task requires an AWS profile such as `bemyapp-dev` having the right access to S3 and Cloudfront.

```
gulp deploy
```
