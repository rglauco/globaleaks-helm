FROM debian:11

RUN apt-get update -q && \
    apt-get install -y gpg vim curl supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN echo "deb http://deb.globaleaks.org bullseye/" > /etc/apt/sources.list.d/globaleaks.list
RUN curl -sS https://deb.globaleaks.org/globaleaks.asc | apt-key add -
RUN apt-get update -q && \
    apt-get install -y globaleaks && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#VOLUME [ "/var/globaleaks/" ]
EXPOSE 8080
EXPOSE 8443
ADD data/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
USER globaleaks
CMD ["/usr/bin/python3" ,"/usr/bin/globaleaks", "--socks-host=tor", "--socks-port=9050", "--ip=0.0.0.0", "--user=globaleaks" ,"--working-path=/var/globaleaks/","-n"]