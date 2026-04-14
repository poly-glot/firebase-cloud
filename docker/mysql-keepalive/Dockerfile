FROM mysql:8.4

COPY ping.sh /ping.sh
RUN chmod +x /ping.sh

ENTRYPOINT ["/ping.sh"]