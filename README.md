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


## create_lambda.sh
* 람다 함수를 만들기 위한 자동화 파일.
* `make-trigger-s3-upload`를 호출하여 패키징하여 `s3`d업로드 까지 함.
```bash
#!/bin/bash

REGION=<리전>
FUNCTION_NAME=<람다 함수 이름>
BUCKET_NAME=<버켓 네임>
S3Key=<버켓 파일 KEY>
CODE=S3Bucket=${BUCKET_NAME},S3Key=${S3Key}
ROLE=<롤>(arn:aws:iam::123455678:role/lambda-user>)
HANDLER=<함수 핸들러 경로>(crawler.crawler_func)
RUNTIME=python3.6
TIMEOUT=60
MEMORY_SIZE=512
PROFILE=<프로필 명>


make make-crawler-s3-upload


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


RULE_NAME=<CloudWatch 규칙 이름>

aws events put-rule \
--name ${RULE_NAME} \
--schedule-expression 'cron(* * * * ? *)' \
--profile ${PROFILE}


SOURCE_ARN=<위에서 만든 RULE의 ARN>(arn:aws:events:ap-northeast-2:123456789:rule/${RULE_NAME})
ACTION='lambda:*'

aws lambda add-permission \
--function-name ${FUNCTION_NAME} \
--statement-id ${RULE_NAME} \
--action ${ACTION} \
--principal events.amazonaws.com \
--source-arn ${SOURCE_ARN} \
--profile ${PROFILE}


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

FUNCTION_NAME=<람다 함수 이름>
ZIP_FILE=<람수 함수 패키지 파일>(fileb://trigger.zip)
BUCKET=<패키지 파일이 올라갈 S3 버켓 네임>
KEY=<버켓에 올라갈 파일 네임>


make make-trigger-s3-upload


aws lambda update-function-code \
--function-name ${FUNCTION_NAME} \
--s3-bucket ${BUCKET} \
--s3-key ${KEY} \

```