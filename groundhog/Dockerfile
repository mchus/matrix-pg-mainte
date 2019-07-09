FROM alpine:latest
RUN apk --no-cache add postgresql-client curl coreutils bash


COPY groundhog/entrypoint.sh /groundhog/
RUN ["chmod","755","/groundhog/entrypoint.sh"]
ENTRYPOINT /bin/sh -c /groundhog/entrypoint.sh
