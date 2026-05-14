FROM jekyll/jekyll:pages

RUN sed -i 's#https://dl-cdn.alpinelinux.org#https://mirrors.cloud.tencent.com#g' /etc/apk/repositories \
    && apk add --no-cache build-base
