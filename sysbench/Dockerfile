FROM ubuntu:22.04

COPY start.sh /start.sh

RUN apt update && apt -y install curl && curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | bash && apt -y install sysbench && apt -y install make automake libtool pkg-config libaio-dev && apt -y install libpq-dev

ENTRYPOINT ["sh", "/start.sh"]