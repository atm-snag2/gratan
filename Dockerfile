FROM ruby:3.1.6

WORKDIR /usr/src/app

RUN mkdir -p /usr/src/app/lib/gratan
COPY Gemfile gratan.gemspec /usr/src/app/
COPY lib/gratan/version.rb /usr/src/app/lib/gratan/
RUN bundle install

COPY . .

ENTRYPOINT ["gratan"]
