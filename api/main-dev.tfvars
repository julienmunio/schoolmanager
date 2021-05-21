project     = "schoolmanager"
client      = "perso"
region      = "eu-west-1"
profile = "schoolmanager-tf-dev"
environment = "DEV"
#collect_schedule_cron="cron(0 8 ? * MON-FRI *)"
#collect_schedule_cron="rate(1 minute)"
collect_schedule_cron      = "rate(1 hour)"
track_events_schedule_cron = "rate(12 hours)"
#mongo_uri="mongodb+srv://rwuser:---@da.mongodb.net/ideation-charge?ssl=true&replicaSet=Dev-shard-0&authSource=admin"
mongo_uri = "mongodb+srv://rwuser:---@a.mongodb.net/ideation-natixis?ssl=true&replicaSet=Prod-shard-0&authSource=admin"
allowed_ips = {
  "julien" : ["93.25.187.164/32"]
}
dns_zone             = "julien.kloudy.fr"
cloudwatch_namespace = "BeMyApp"
# metrics = {
#   "Accounts": "CRON"
#   "Metric2" : "CRONS2"
# }