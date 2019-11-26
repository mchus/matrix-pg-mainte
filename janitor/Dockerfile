FROM alpine:3.7
RUN apk --update add postgresql-client && rm -rf /var/cache/apk/*

COPY synapse_janitor.sql /
ENTRYPOINT ["/bin/sh","-c" ]
CMD ["psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -a -f synapse_janitor.sql; sleep 604800"]
