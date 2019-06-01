FROM ruby:2.3.1-alpine
MAINTAINER bakir@atlantbh.com

ENV APP_BASE_DIR /example
ENV APP_LOG $APP_BASE_DIR/log/app.log
RUN mkdir -p $APP_BASE_DIR/log
COPY "./example_application.rb" $APP_BASE_DIR/

CMD ["sh", "-c", "/usr/local/bin/ruby $APP_BASE_DIR/example_application.rb 100000 $APP_LOG"]