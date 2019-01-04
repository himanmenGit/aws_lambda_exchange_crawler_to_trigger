#!/bin/bash


while read LINE; do
    eval $LINE
done < .aws.env

REGION=${AWS_DEFAULT_REGION}
FUNCTION_NAME=${AWS_LAMBDA_FUNC_NAME}
BUCKET_NAME=${AWS_BUCKET_NAME}
S3Key=trigger.zip
CODE=S3Bucket=${BUCKET_NAME},S3Key=${S3Key}
ROLE=${AWS_LAMBDA_ROLE}
HANDLER=src.trigger.trigger_func
RUNTIME=python3.6
TIMEOUT=60
MEMORY_SIZE=512
PROFILE=${AWS_PROFILE}

make make-trigger-s3-upload BUCKET_NAME=${BUCKET_NAME} PROFILE=${PROFILE}

# 함수 만듬
aws lambda create-function \
--region ${REGION} \
--function-name ${FUNCTION_NAME} \
--code ${CODE} \
--role ${ROLE} \
--handler ${HANDLER} \
--runtime ${RUNTIME} \
--timeout ${TIMEOUT} \
--memory-size ${MEMORY_SIZE} \
--profile ${PROFILE}

# CLOUD WATCH EVENT 를 만듬
RULE_NAME=${AWS_CLOUD_WATCH_EVENT_NAME}

aws events put-rule \
--name ${RULE_NAME} \
--schedule-expression 'cron(* * * * ? *)' \
--profile ${PROFILE}

# 만든 이벤트에 퍼미션을 줌
SOURCE_ARN=${AWS_CLOUD_WATCH_EVENT_RULE}
ACTION='lambda:*'

aws lambda add-permission \
--function-name ${FUNCTION_NAME} \
--statement-id ${RULE_NAME} \
--action ${ACTION} \
--principal events.amazonaws.com \
--source-arn ${SOURCE_ARN} \
--profile ${PROFILE}

# 이벤트를 trigger 연결
TARGETS_FILE=file://targets.json
aws events put-targets \
--rule ${RULE_NAME} \
--targets ${TARGETS_FILE} \
--profile ${PROFILE}