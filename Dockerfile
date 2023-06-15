FROM ruby:3.2.2-slim-bullseye

RUN apt-get update -qq \
    && apt-get install -y wget make gcc g++

RUN cd /tmp &&\
    wget https://github.com/maxmind/geoipupdate/releases/download/v5.1.1/geoipupdate_5.1.1_linux_amd64.deb &&\
    apt install -y --fix-broken /tmp/geoipupdate_5.1.1_linux_amd64.deb &&\
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&\
    apt install -y --fix-broken /tmp/google-chrome-stable_current_amd64.deb;

ADD . /Rails-Docker
WORKDIR /Rails-Docker

ENV HOME /Rails-Docker
RUN bundle install

CMD ["/bin/bash", "-c", "bundle exec rake && bundle exec ./bin/acnihilator inspect https://api64.ipify.org/?format=json"]
