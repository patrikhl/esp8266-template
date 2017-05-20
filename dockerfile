FROM debian:jessie-slim

# install dependencies
RUN apt-get update && \
    apt-get install -y make unrar-free autoconf automake libtool gcc g++ gperf \
    flex bison texinfo gawk ncurses-dev libexpat-dev python-dev python \
    python-serial sed git unzip bash help2man wget bzip2 libtool-bin && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# add user to build sdk (cannot be done as root)
RUN adduser --disabled-password --gecos "" user && chown -R user /opt
USER user

# install sdk
RUN git clone --recursive https://github.com/pfalcon/esp-open-sdk /opt/esp && \
    cd /opt/esp && \
    make && \
    mv Makefile sdk.mk && \
    rm -rf ./crosstool-NG/.build *.zip

# add sdk to path
ENV PATH $PATH:/opt/esp/xtensa-lx106-elf/bin

# switch back to root
USER root

# set workdir
WORKDIR /home