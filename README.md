# Julien
cd api

terraforn init
    Enter a value
    S3 bucket

    Correction :
        provider.tf

backend "s3" {
    bucket  = "tf-julien-munio"
    key     = "dev/schoolmanager.tfstate"
    region  = "eu-west-1"
    profile = "schoolmanager-tf-dev"
}

terraform plan
    Enter a value
    var.client

terraform init -backend-config="backend-dev.tfvars"


## Target environment to create/update
ENV="dev"

## Initialize backend
terraform init -backend-config="backend-${ENV:-dev}.tfvars"
echo "State will be in: s3://bemyapp-terraform/${ENV:-dev}/main.tfstate"

## (Optionl) Terraform validation to check for syntax errors
terraform validate

## Update the infrastructure
terraform apply -auto-approve -var-file="main-${ENV:-dev}.tfvars"

# Introduction

Setup the analtics infractucture.

# API

## API Requirement

The API corresponds to the infrastructure components: Lambda, API Gateway, S3,... 
These components are managed by `terraform`.

- Terraform 0.15+
- NodeJS 14+

## Create Lambda layers

Only once, for each target AWS account (dev and production), create the Lambda layers. Layers are a kind of template or base image (such as `Docker`) for Lambda.
These layers need to to be created only one time, and are managed in separated terraform states.

``` bash
git clone 
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
cd api

# Target environment to create/update
ENV="dev"

# Initialize backend
terraform init -backend-config="backend-$ENV.tfvars"

# (Optionl) Terraform validation to check for syntax errors
terraform validate

# Update the infrastructure
terraform apply -auto-approve -var-file="main-$ENV.tfvars"
``` 

Expected outputs should look like:

``` text
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

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
```

Calling API Gateway via Cloudfront. No API is required since the Cloudfront distribution is protected by a WAF with IP protection.

``` bash
```

Single metric data:
``` bash
```

Multiple metrics data:
``` bash
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
```
Sample data:

```json
[
    {"id":"ideation-instep","title":"Infosys InStep Internship Program","start":"2020-07-01T00:00:00.000Z","stop":"2021-07-07T00:00:00.000Z"}
]
```

Note : `labels` and `start` attributes may not be available.


# Website

## Website Requirement

The API corresponds to the infrastructure components: Lambda, API Gateway, S3,... 
These components are managed by `terraform`.

- Terraform 0.14+
- NodeJS 12+
- Write access to bucket `-terraform` on AWS account ``
- S3 access, bucket `-analytics-dev`or `-analytics-prod` depending on the target environment.

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
This task requires an AWS profile such as `-dev` having the right access to S3 and Cloudfront.

```
gulp deploy
```
