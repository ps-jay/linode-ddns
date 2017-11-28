FROM python:3

MAINTAINER Philip Jay <phil@jay.id.au>

ENV TZ Australia/Melbourne

ADD requirements.txt /tmp/

RUN pip install -U \
      -r /tmp/requirements.txt \
 && rm -rf /root/.cache

ADD pylint.conf     /tmp/
ADD route53_ddns.py /app/

RUN adduser --system route53_ddns
USER route53_ddns

RUN pylint --rcfile /tmp/pylint.conf /app/route53_ddns.py

CMD python /app/route53_ddns.py
