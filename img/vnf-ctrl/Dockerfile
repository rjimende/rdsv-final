FROM      osrg/ryu

RUN apt-get clean
RUN	apt-get update && apt-get install -y \
	net-tools \
    arpwatch \
	iproute \
	inetutils-ping \
    openvswitch-switch \
    openvswitch-common \
    iperf \
    iperf3 \
    tcpdump \
    python-pip \
    curl \
    nano \
    bridge-utils \
    vim \
    git


COPY README.txt README.txt
COPY qos_simple_switch_13.py qos_simple_switch_13.py

#RUN pip install -r ryu/tools/optional-requires
RUN git clone https://github.com/martimy/flowmanager

