FROM debian:9 as builder

ARG BRANCH=v0.6.0
ENV BRANCH=${BRANCH}

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      gdb \
      libreadline-dev \
      python-dev \
      gcc \
      g++\
      git \
      cmake \
      libboost-all-dev \
      librocksdb-dev && \
    git clone --branch $BRANCH https://github.com/monkeytips/monkeytips.git /opt/monkeytips && \
    cd /opt/monkeytips && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    #cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

FROM debian:9

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/funkypenguin/monkeytips.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"

# monkeytipsd needs libreadline 
RUN apt-get update && \
    apt-get install -y \
      libreadline-dev \
     && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/bin && mkdir -p /tmp/checkpoints 

WORKDIR /usr/local/bin
COPY --from=builder /opt/monkeytips/build/src/monkeytipsd .
COPY --from=builder /opt/monkeytips/build/src/monkey-service .
COPY --from=builder /opt/monkeytips/build/src/zedwallet .
COPY --from=builder /opt/monkeytips/build/src/miner .
RUN mkdir -p /var/lib/monkeytips
WORKDIR /var/lib/monkeytips
ENTRYPOINT ["/usr/local/bin/monkeytipsd"]
CMD ["--no-console","--data-dir","/var/lib/monkeytips","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","13002","--p2p-bind-port","13001"]
