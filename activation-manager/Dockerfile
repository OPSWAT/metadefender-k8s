FROM alpine

RUN apk add curl jq

ADD entrypoint.sh ./

RUN chmod +x /entrypoint.sh

CMD /entrypoint.sh