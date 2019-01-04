#!/bin/bash

while read LINE; do
    eval $LINE
done < .aws.env

FUNCTION_NAME=${AWS_LAMBDA_FUNC_NAME}
ZIP_FILE=fileb://trigger.zip
BUCKET_NAME=${AWS_BUCKET_NAME}
KEY=trigger.zip
PROFILE=${AWS_PROFILE}

# 파일을 패키징하여 s3에 업로드 후
make make-trigger-s3-upload BUCKET_NAME=${BUCKET_NAME} PROFILE=${PROFILE}


aws lambda update-function-code \
--function-name ${FUNCTION_NAME} \
--s3-bucket ${BUCKET_NAME} \
--s3-key ${KEY} \
--profile ${PROFILE}
