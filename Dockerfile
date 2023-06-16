FROM ubuntu

RUN apk add --no-cache wget curl \
    && wget -O speedtest-cli.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz \
    && tar zxvf speedtest-cli.tgz \
    && rm speedtest-cli.tgz \
    && mv speedtest* /usr/bin/

 HEALTHCHECK --interval=5m --timeout=5s --retries=1 \
    CMD ./healthcheck.sh

WORKDIR /opt/speedtest

ADD scripts/ .

RUN chmod +x ./init_test_connection.sh \
    && chmod +x ./healthcheck.sh

CMD ./init_test_connection.sh
