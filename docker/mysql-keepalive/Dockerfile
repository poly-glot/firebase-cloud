FROM alpine:3.19

RUN apk add --no-cache mysql-client

COPY ping.sh /ping.sh
RUN chmod +x /ping.sh

ENTRYPOINT ["/ping.sh"]
