FROM alpine:latest
RUN apk --no-cache add curl coreutils bash


COPY entrypoint.sh /groundhog/
RUN ["chmod","755","/groundhog/entrypoint.sh"]
ENTRYPOINT /bin/sh -c /groundhog/entrypoint.sh
