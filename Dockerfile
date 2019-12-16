FROM snoophogg/ubuntujava

# ADD https://www.crushftp.com/early9/CrushFTP9.zip /tmp/CrushFTP9.zip
# COPY ./CrushFTP9_NoJava.zip /tmp/CrushFTP9.zip

COPY ./post_setup.sh /tmp/post_setup.sh
COPY ./crushftp_init.sh /var/opt/run-crushftp.sh
COPY ./setup.sh /var/opt/setup.sh

RUN chmod +x /tmp/post_setup.sh
RUN chmod +x /var/opt/setup.sh
RUN chmod +x /var/opt/run-crushftp.sh

RUN curl -o /tmp/CrushFTP9.zip https://www.crushftp.com/early9/CrushFTP9.zip

ENTRYPOINT [ "/bin/bash", "/var/opt/setup.sh" ]
CMD ["-c"]

HEALTHCHECK --interval=1m --timeout=3s \
  CMD curl $CRUSH_ADMIN_PROTOCOL://localhost:$CRUSH_ADMIN_PORT/favicon.ico -H 'Connection: close' || exit 1

ENV CRUSH_ADMIN_USER crushadmin
ENV CRUSH_ADMIN_PASSWORD crushadmin
ENV CRUSH_ADMIN_PROTOCOL http
ENV CRUSH_ADMIN_PORT 8080
ENV CONNECT 0
ENV MYSQL_HOST db
ENV MYSQL_PORT 3306
ENV MYSQL_DATABASE crushftp
ENV MYSQL_USER crushftp
ENV MYSQL_PASSWORD crushftp
ENV MYSQL_USESSL false

EXPOSE 21 2222 8080 8888 9022 9090
