FROM debian:buster-slim

ARG ruby_version=2.7.5
ARG ruby_build_version=20200520
ARG bundler_version=2.3.12

# just use a login shell.
SHELL [ "/bin/bash", "-l", "-c" ]

# install ruby-build
RUN apt-get update && apt-get install -y curl gnupg ; \
    curl https://codeload.github.com/rbenv/ruby-build/tar.gz/v${ruby_build_version} -O ; \
    tar xf v${ruby_build_version} ; \
    ruby-build-${ruby_build_version}/install.sh ; \
# install ruby dependencies
    apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev bzip2 shared-mime-info

# Add docker-compose-wait tool
ENV WAIT_VERSION 2.8.0
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
RUN chmod +x /wait ; \
# install ruby, skipping docs
    env RUBY_CONFIGURE_OPTS=--disable-install-doc ruby-build ${ruby_version} /usr/local ; \
    gem install bundler -v ${bundler_version} ;
# install apache2 and passenger
    apt-get update && apt-get install -y apache2 apt-transport-https ca-certificates ; \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7 ; \
    echo deb https://oss-binaries.phusionpassenger.com/apt/passenger buster main > /etc/apt/sources.list.d/passenger.list ; \
    apt-get update && apt-get install -y libapache2-mod-passenger ; \
    a2enmod passenger ; \
    /usr/bin/passenger-config validate-install ; \
# install idb
    apt-get update && apt-get install -y git libmariadb-dev ; \
    useradd -d /opt/idb -M -r idb && usermod -g idb idb ; \
    mkdir /opt/idb && chown idb:idb /opt/idb
    
WORKDIR /opt/idb

USER idb
COPY --chown=idb:idb . /opt/idb
RUN env RAILS_ENV=production bundle install --path=vendor/bundle
#RUN mv docker/build/config config

USER root
RUN adduser www-data idb
ADD docker/build/apache.conf /etc/apache2/sites-available/idb.conf
RUN a2dissite 000-default && a2ensite idb

EXPOSE 80


