FROM ruby:stretch
LABEL maintainer="Scott Moe<smoe@threewings.com>"

RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - ; \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - ; \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list ; \
    apt-get -y update; apt-get -yq upgrade; apt-get -yq install git vim wget unzip ack-grep fontconfig lua5.3 python3.5 nodejs yarn ; \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ; \
    groupadd -r app && useradd -r  -m -c "developer" -g app app

COPY newhome.sh /tmp
USER app
WORKDIR /home/app

CMD ["bash", "-l"]
