FROM debian:buster-slim

# we use rvm so much, just use a login shell
SHELL [ "/bin/bash", "-l", "-c" ]

# install rvm
RUN apt-get update && apt-get install -y curl procps gnupg
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable --ruby
# install ruby 2.6.3
RUN rvm install ruby-2.6.3
RUN rvm use --default ruby-2.6.3

# install apache2 and passenger
RUN apt-get update && apt-get install -y apache2 apt-transport-https ca-certificates
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN echo deb https://oss-binaries.phusionpassenger.com/apt/passenger buster main > /etc/apt/sources.list.d/passenger.list
RUN apt-get update && apt-get install -y libapache2-mod-passenger
RUN a2enmod passenger
RUN /usr/bin/passenger-config validate-install

# install idb
RUN apt-get update && apt-get install -y git libmariadb-dev
RUN useradd -d /opt/idb -M -r idb && usermod -g idb -G rvm idb

RUN mkdir /opt/idb && chown idb:idb /opt/idb
WORKDIR /opt/idb

USER idb
RUN rvm use --default ruby-2.6.3
RUN rvm ruby-2.6.3 exec gem install bundler -v 2.0.2
COPY --chown=idb:idb Gemfile Gemfile.lock /opt/idb/
RUN rvm ruby-2.6.3 exec bundle install
COPY --chown=idb:idb . .

USER root
ADD apache.conf /etc/apache2/sites-available/idb.conf
RUN a2dissite 000-default && a2ensite idb
EXPOSE 80
ENTRYPOINT apachectl -D FOREGROUND


