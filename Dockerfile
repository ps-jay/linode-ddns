FROM alpine:3.2

MAINTAINER Philip Jay <phil@jay.id.au>

ENV TZ Australia/Melbourne

RUN apk update \
 && apk upgrade \
 && apk add \
      bash \
      openssl \
 && rm -rf /var/cache/apk/*

ADD linode-ddns.sh /opt/

RUN chmod a+rx /opt/linode-ddns.sh

RUN adduser -H -S linode-ddns

USER linode-ddns

CMD [ "/opt/linode-ddns.sh" ]
