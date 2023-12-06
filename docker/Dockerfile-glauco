FROM debian:12

RUN apt-get update -q && \
    apt-get install -y gpg curl vim curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN echo "deb http://deb.globaleaks.org bookworm/" > /etc/apt/sources.list.d/globaleaks.list
RUN curl -sS https://deb.globaleaks.org/globaleaks.asc | apt-key add -
RUN apt-get update -q && \
    apt-get install -y globaleaks && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8080
EXPOSE 8443
HEALTHCHECK --timeout=3s --start-period=60s \
    CMD curl --fail localhost:8080 || exit 1

USER 1337

COPY ./start ./entrypoint /

WORKDIR /

CMD ["/start"]
ENTRYPOINT ["/entrypoint"]
