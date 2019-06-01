FROM ruby:2.3.1-alpine
MAINTAINER bakir@atlantbh.com

ENV APP_BASE_DIR /example
ENV APP_LOG_DIR /var/log/cron-example-application
ENV APP_LOG $APP_LOG_DIR/app.log

RUN mkdir -p $APP_BASE_DIR/cron
RUN mkdir -p $APP_LOG_DIR

COPY "./example_application.rb" $APP_BASE_DIR/
COPY "./run_example_application" $APP_BASE_DIR/cron/

RUN chmod a+x $APP_BASE_DIR/example_application.rb
RUN chmod a+x $APP_BASE_DIR/cron/run_example_application

RUN echo -n "* * * * * run-parts ${APP_BASE_DIR}/cron" >> /etc/crontabs/root
RUN touch $APP_LOG

# Run the command on container startup
CMD ["sh", "-c", "crond -f"]