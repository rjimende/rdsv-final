FROM educaredes/vnf-access
# install required packages
RUN apt-get clean
RUN apt-get update \
    && apt-get install -y \
    iptables \
    arpwatch 

COPY vnx_config_nat vnx_config_nat
COPY README.txt README.txt

RUN chmod +x vnx_config_nat
