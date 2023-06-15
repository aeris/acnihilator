FROM ruby:3.2-slim-bookworm

ENV NO_MONGODB=true

RUN <<EOF
	apt update -qq
	apt install -qq -y build-essential chromium
	gem install bundler
EOF

ADD . /app
WORKDIR /app

RUN <<EOF
	bundle config set --local without development
	bundle install
EOF

ENTRYPOINT [ "./bin/acnihilator" ]
