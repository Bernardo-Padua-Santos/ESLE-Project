FROM ubuntu:latest

COPY start.sh /start.sh

RUN apt update && apt -y install default-jre && apt -y install wget && wget https://github.com/yugabyte/yb-sample-apps/releases/download/v1.4.1/yb-sample-apps.jar -O yb-sample-apps.jar

ENTRYPOINT ["sh", "/start.sh"]