FROM ruby:3.2.2-slim-bookworm

ENV NO_MONGODB=true SELENIUM_ARGS="--no-sandbox --disable-dev-shm-usage"

RUN <<EOF
	apt update -qq
	apt install -qq -y build-essential chromium-driver
	gem install bundler
	useradd user
EOF

ADD . /app
WORKDIR /app

RUN <<EOF
	bundle config set deployment true
	bundle config set without development
	bundle install
EOF

USER user
ENTRYPOINT [ "./bin/acnihilator" ]
