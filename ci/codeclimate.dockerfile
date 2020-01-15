FROM alpine:3.11
RUN wget https://codeclimate.com/downloads/test-reporter/test-reporter-0.6.3-linux-amd64 -O /opt/cc-test-reporter
RUN chmod +x /opt/cc-test-reporter
RUN apk update && apk upgrade && apk add --no-cache git

ENTRYPOINT ["/opt/cc-test-reporter"]
