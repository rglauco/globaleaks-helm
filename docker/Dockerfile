FROM debian:11

RUN apt-get update -q && \
    apt-get install -y gpg curl vim curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN echo "deb http://deb.globaleaks.org bullseye/" > /etc/apt/sources.list.d/globaleaks.list
RUN curl -sS https://deb.globaleaks.org/globaleaks.asc | apt-key add -
RUN apt-get update -q && \
    apt-get install -y globaleaks && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=globaleaks:root torrc /etc/tor/
#VOLUME [ "/var/globaleaks/" ]
ENV TORPIDDIR=/var/run/tor
ENV TORLOGDIR=/var/log/tor

RUN mkdir -m 02755 "$TORPIDDIR" && chown 103:root "$TORPIDDIR"
RUN chmod 02750 "$TORLOGDIR" && chown 103:root "$TORLOGDIR"

RUN chown 103:root /var/lib/tor
EXPOSE 8080
EXPOSE 8443

USER 103
#CMD ["/usr/bin/python3" ,"/usr/bin/globaleaks", "--devel-mode", "--socks-host=tor", "--socks-port=9050", "--ip=0.0.0.0", "--user=globaleaks" ,"--working-path=/var/globaleaks/","-n"]

COPY ./start ./entrypoint /

WORKDIR /

CMD ["/start"]
ENTRYPOINT ["/entrypoint"]
