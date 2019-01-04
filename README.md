# 거래소 공지 트리거

* 1분에 한번씩 거래소 공지 크롤러 람다 함수를 비동기 호출 함.
* role 권한은 s3,lambda FullAccess로 해 놓음.

## 참고 사이트
[링크](http://robertorocha.info/setting-up-a-selenium-web-scraper-on-aws-lambda-with-python/)


## 아키텍쳐
>Git -> CI(Bitbucket Pipeline)-> AWS CLI-> AWS Lambda(trigger, repeat 1min)-> AWS Lambda(trigger, s3)-> 텔레그램 공지봇


## 내용
* `python version` - 3.6.5, `(aws lambda runtime-3.6)`
* 기본적으로 `aws`에 현재 `lambda` 프로젝트가 없는 것으로 가정
* `aws credentials`은 로컬 컴퓨터의 `.~/aws/credential`의 개인 프로필로 사용함.
* 프로젝트에 있는 `Docker`관련 파일은 `lambda`와 최대한 동일한 환경에서 로컬 빌드를 해보기 위한 장치
* 폴더의 구조는 바꾸면 안된다. 다른 부분을 수정하지 않는 이상은.
 
 
## Requirements
* [Docker](https://docs.docker.com/install/)
* [Docker-Compose](https://docs.docker.com/compose/install/#install-compose)


## Make파일 사용법
* `make docker-build`로 도커 빌드
* `make docker-run`으로 도커 실행
* `Dockerfile`의 내용이 변경되면 `make docker-build`를 하고 `make docker-run`을 해야 결과가 반영됨.
* `build-trigger-package`는 프로젝트를 s3에 올리기 위해 `trigger.zip`으로 프로젝트를 압축함
* `make-trigger-s3-upload`는 처음시작시 디렉터리구조와 종속파일을 받아 압축하여 s3에 업로드 함. `--profile` 설정 해야함.

* `make docker-run`을 실행시 `aws credential`이 없기 때문에 도커로 테스트가 힘들다 
* 이를 해결 하기 위해 `docker-compose.yml`에 `env_file` 속성을 사용하여 `aws credential`을 넣어 보자
* 최상위 폴더에 `.aws.env` 을 만들고 자격증명 키를 넣는다
 
# 중요!!!!!
# 세번 읽으시오!
## 여기서 중요한것 `.gitignore`에 해당 파일을 추가하여 깃에 올리지 말것!!!!!!!
`.aws.env`를 ignore 시킨다. 해당 저장소는 설명을 위해 삽입 한것. 
`.aws.env`파일을 보면
```bash
AWS_DEFAULT_REGION=<AWS_DEFAULT_REGION>
AWS_BUCKET_NAME=<AWS_BUCKET_NAME>
AWS_LAMBDA_ROLE=<AWS_LAMBDA_ROLE>
AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
AWS_PROFILE=<AWS_PROFILE>
AWS_LAMBDA_FUNC_NAME=<AWS_LAMBDA_FUNC_NAME>
AWS_CLOUD_WATCH_EVENT_NAME=<AWS_CLOUD_WATCH_EVENT_NAME>
AWS_CLOUD_WATCH_EVENT_RULE=<AWS_CLOUD_WATCH_EVENT_RULE>

```
도커의 환경변수를 `env_file`로 파일을 읽어와 사용하게 한다.

## create_lambda.sh
* 람다 함수를 만들기 위한 자동화 파일.
* `make-trigger-s3-upload`를 호출하여 패키징하여 `s3`d업로드 까지 함.
```bash
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

```


## update_code_lambda.sh
코드를 수정한 후 `make-trigger-s3-upload`를 사용하여 변경된 코드를 `s3`에 업로드후
해당 스크립트로 `lambda` 함수에 변경사항 적용
```bash
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

```