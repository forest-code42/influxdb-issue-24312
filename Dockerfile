
# this Dockerfile was roughly constructed from quay.io/influxdb/cross-builder
# the  Dockerfile for that image isn't published :( 
# but we can get a lot of clues from the following commands, like:
# $ docker history quay.io/influxdb/cross-builder:go1.20.5-b76a62e4c08e4a01ccfc02d6e7b7b4720ebed2ef --no-trunc
# $ docker run --rm --entrypoint /bin/bash quay.io/influxdb/cross-builder:go1.20.5-b76a62e4c08e4a01ccfc02d6e7b7b4720ebed2ef -c 'cat /install-rust.sh'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN uname -a

# https://askubuntu.com/questions/1344314/failing-to-configure-tex-common-on-ubuntu-20-04-2-lts
RUN apt clean && apt update && apt -y install locales && export LC_ALL="en_US.UTF-8" && dpkg-reconfigure locales 

RUN apt -y install asciidoc build-essential  bzr clang cmake curl devscripts gcc gcc-aarch64-linux-gnu gcc-x86-64-linux-gnu git jq libssl-dev \
          libxml2-dev llvm-dev lzma-dev patch pkg-config tzdata  wget xmlto xz-utils zlib1g-dev rpm ruby-dev


ENV GO_VERSION=1.20.5

COPY install-go.sh /install-go.sh
RUN mkdir /go && /install-go.sh  

COPY install-rust.sh /install-rust.sh
RUN /install-rust.sh && . $HOME/.cargo/env && \
    rustup target add  x86_64-unknown-linux-musl
    # maybe one day we might want aarch64-unknown-linux-musl  

ENV PATH=/root/.cargo/bin:/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# docker run --rm --entrypoint /bin/bash quay.io/influxdb/cross-builder:go1.20.5-b76a62e4c08e4a01ccfc02d6e7b7b4720ebed2ef -c 'cat /usr/local/src/musl-gcc/musl-gcc.specs.sh.patch'
COPY musl-gcc.specs.sh.patch /usr/local/src/musl-gcc/musl-gcc.specs.sh.patch

RUN git clone git://git.musl-libc.org/musl /tmp/musl  --branch v1.2.3 --depth 1 && \ 
   patch /tmp/musl/tools/musl-gcc.specs.sh  /usr/local/src/musl-gcc/musl-gcc.specs.sh.patch 
   
# this would be if we were running on x86_64
# RUN cd /tmp/musl                 && \
#    export CC=gcc                && \
#    export AR=ar                 && \
#    export RANLIB=ranlib         && \
#    ./configure  --enable-wrapper=gcc   --prefix=/musl/x86_64  --target=x86_64-linux-musl && \
#    make clean                   && \
#    make -j"$(nprocs)" install 

RUN cd /tmp/musl                 && \
   export CC=x86_64-linux-gnu-gcc                && \
   export AR=x86_64-linux-gnu-ar                 && \
   export RANLIB=x86_64-linux-gnu-ranlib         && \
   ./configure  --enable-wrapper=gcc   --prefix=/musl/x86_64  --target=x86_64-linux-musl && \
   make clean                   && \
   make -j"$(nprocs)" install 

# this would be for compiling for 64 bit arm
# RUN  cd /tmp/musl                           && \     
#    export CC=aarch64-linux-gnu-gcc        && \       
#    export AR=aarch64-linux-gnu-ar         && \        
#    export RANLIB=aarch64-linux-gnu-ranlib && \        
#    ./configure  --enable-wrapper=gcc  --prefix=/musl/aarch64  --target=aarch64-linux-musl  &&  \       
#    make clean                             && \
#    make -j"$(nprocs)" install 

ENV PROTO_VERSION=3.17.3
ENV PROTO_BUILD_TIME=2021100120071633118879

# this will try to install the x86_64 version, RIP
# RUN PROTO_ARCHIVE=protoc-${PROTO_VERSION}-${PROTO_BUILD_TIME}.tar.gz && \ 
#    wget https://edge-xcc-archives.s3-us-west-2.amazonaws.com/${PROTO_ARCHIVE} && \       
#    tar xzf ${PROTO_ARCHIVE} -C /usr && \
#    rm ${PROTO_ARCHIVE}             

# # lets try this instead???
RUN apt install -y protobuf-compiler

ENV PROTOC_GEN_GO_VER=v1.27.1   

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@${PROTOC_GEN_GO_VER} && \
    go install github.com/influxdata/pkg-config@v0.2.11 && \
    go install github.com/jstemmer/go-junit-report@v0.9.1

RUN gem install --no-document fpm

RUN git clone -b v2.7.1 --single-branch https://github.com/influxdata/influxdb.git /go/src/github.com/influxdata/influxdb
WORKDIR /go/src/github.com/influxdata/influxdb

RUN cd ./cmd/influxd && go get && cd ../../

ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc
# 

COPY xcc /bin/xcc
COPY build-version.sh /bin/build-version.sh

# this said it was already installed :shrug:
# RUN apt install -y libprotobuf-dev

ENV TMPL_VER=v1.0.0 
ENV STRINGER_VER=latest 
ENV EASYJSON_VER=v0.7.7 
ENV GOIMPORTS_VER=latest 

RUN go install github.com/benbjohnson/tmpl@${TMPL_VER} && \
    go install golang.org/x/tools/cmd/stringer@${STRINGER_VER} && \
    go install github.com/mailru/easyjson/easyjson@${EASYJSON_VER} && \
    go install golang.org/x/tools/cmd/goimports@${GOIMPORTS_VER} 

# I forgot to add /root/go/bin to path before, oops
ENV PATH=/root/.cargo/bin:/go/bin:/root/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV RUSTFLAGS='-C linker=x86_64-linux-gnu-gcc'

RUN export GOOS=linux && \
    export GOARCH=amd64 && \
    uname -a && make  SHELL='sh -x'
    # this was failing with  "Package flux was not found in the pkg-config search path"
    # ./scripts/ci/build.sh "bin/influxd_$(go env GOOS)_$(go env GOARCH)" "release" ./cmd/influxd

ENV BASH_ENV=/tmp/bash_env

RUN PREFIX=2.x /go/src/github.com/influxdata/influxdb/.circleci/scripts/get-version

RUN sed -i 's/sudo //' /go/src/github.com/influxdata/influxdb/.circleci/scripts/build-package && \
    sed -i 's|&& chown -R circleci: /artifacts||' /go/src/github.com/influxdata/influxdb/.circleci/scripts/build-package

RUN export PLAT=linux && export ARCH=amd64 && /go/src/github.com/influxdata/influxdb/.circleci/scripts/build-package