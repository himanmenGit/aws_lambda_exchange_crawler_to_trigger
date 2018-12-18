FROM lambci/lambda:python3.6
MAINTAINER tech@21buttons.com

USER root

ENV APP_DIR /var/task

WORKDIR $APP_DIR