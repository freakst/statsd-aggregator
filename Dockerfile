FROM alpine:latest

# Install basic dependencies
RUN apk update && apk add \
    gcc \
    g++ \
    make \
    libev \
    libev-dev \
    libconfig

COPY . /usr/src/statsd-aggregator/

RUN cd  /usr/src/statsd-aggregator

#&& make install

WORKDIR /usr/src/statsd-aggregator

CMD ["/bin/bash"]
