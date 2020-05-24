FROM python:3.8-alpine

LABEL "com.github.actions.name"="Cloudfront Update"
LABEL "com.github.actions.description"="Update CF Setting"
LABEL "com.github.actions.icon"="refresh-cw"
LABEL "com.github.actions.color"="green"

ENV AWSCLI_VERSION='1.18.14'
RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}
RUN apk add jq

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]