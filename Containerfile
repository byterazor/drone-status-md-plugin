FROM alpine:latest

RUN apk update && apk add --no-cache tini bash ca-certificates

ADD templates /templates
ADD plugin.sh /
RUN chmod a+x /plugin.sh


ENTRYPOINT ["/sbin/tini", "--", "/plugin.sh"]