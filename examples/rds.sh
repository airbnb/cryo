#!/bin/bash -ex

cd $(dirname $0) && cd ..

./bin/cryo redis\
  --host localhost \
  --user me \
  --password verysafe \
  --sns-topic arn:aws:sns:us-east-1:172631448019:martin-redis-test \
  --key somekey \
  --aws-access-key some_aws_access_key \
  --aws-secret-key some_secret \
  --bucket some_buck \
  --path /mnt/redis/foo \


# or


export CRYO_AWS_ACCESS_KEY=some_key
export CRYO_AWS_SECRET_KEY=some_secret
export CRYO_BUCKET=some_other_buk
export CRYO_SNS_TOPIC=some_sns_topic
export CRYO_HOST=some_server_somewhere
export CRYO_USER=some_user
export CRYO_PASSWORD=some_good_password
export CRYO_PATH=/some/path/to/redis/db

./bin/cryo mysql
