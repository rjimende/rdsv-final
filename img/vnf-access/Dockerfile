FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
# install required packages
RUN apt-get clean
RUN apt-get update \
    && apt-get install -y \
    net-tools \
    traceroute \
    build-essential \
    inetutils-ping \
    bridge-utils \
    tcpdump \
    openvswitch-switch \
    openvswitch-common \
    iperf \
    iproute2 \
    curl \
    nano \
    vim \
    iperf3 \
    ryu-bin \
    arpwatch

COPY qos_simple_switch_13.py qos_simple_switch_13.py
COPY README.txt README.txt