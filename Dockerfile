FROM alpine:latest
RUN apk upgrade --no-cache \
  &&  echo  https://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
  && apk add --no-cache --update ca-certificates aws-cli xz postgresql-client
WORKDIR /backup
COPY entrypoint.sh backup.sh /backup/
ENTRYPOINT ["sh", "/backup/entrypoint.sh"]
CMD [""]