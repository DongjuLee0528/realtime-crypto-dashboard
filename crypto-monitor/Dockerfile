FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        curl \
        bc \
        jq \
        ca-certificates \
        tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY update.sh /usr/local/bin/update.sh

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/update.sh

RUN mkdir -p /var/log/crypto-monitor

ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

VOLUME /shared

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD test -f /shared/index.html || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]