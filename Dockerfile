FROM docker.io/centos:7.4.1708

USER root

RUN yum clean all \
 && yum repolist \
 && yum -y update \
 && sed -i "s/en_US/all/" /etc/yum.conf  \
 && yum -y reinstall glibc-common

RUN  yum -y install tar unzip vi vim telnet net-tools curl openssl \
 && yum -y install apr apr-util apr-devel apr-util-devel \
 && yum -y install elinks locate python-setuptools \
 && yum clean all

RUN yum -y install sudo \
    && mkdir /home1 \
    && useradd -d /home1/irteam -m irteam \
    && useradd -d /home1/irteamsu -m irteamsu \
    && echo "irteamsu ALL=NOPASSWD:ALL" >> /etc/sudoers

RUN yum -y install gcc make gcc-c++ \
    && yum clean all

RUN yum -y install wget \
    && yum clean all


USER irteam

RUN mkdir /home1/irteam/apps /home1/irteam/logs

WORKDIR /home1/irteam/apps/
RUN wget http://apache.mirror.cdnetworks.com//apr/apr-1.7.0.tar.gz \
    && wget http://apache.mirror.cdnetworks.com//apr/apr-util-1.6.1.tar.gz \
    && wget ftp://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz \
    && wget http://mirror.navercorp.com/apache//httpd/httpd-2.4.41.tar.gz

RUN tar xvf httpd-2.4.41.tar.gz \
    && tar xvf apr-1.7.0.tar.gz \
    && tar xvf apr-util-1.6.1.tar.gz \
    && tar xvf pcre-8.43.tar.gz

RUN mv apr-1.7.0 ./httpd-2.4.41/srclib/apr \
    && mv apr-util-1.6.1 ./httpd-2.4.41/srclib/apr-util

WORKDIR /home1/irteam/apps/pcre-8.43
RUN ./configure --prefix=/home1/irteam/apps/pcre_8.43 \
    && make && make install

WORKDIR /home1/irteam/apps/httpd-2.4.41
RUN ./configure --prefix=/home1/irteam/apps/apache_2.4.41 --with-pcre=/home1/irteam/apps/pcre_8.43/bin/pcre-config \
    && make && make install

WORKDIR /home1/irteam/apps/
RUN ln -s pcre_8.43 pcre \
    && ln -s apache_2.4.41 apache

RUN rmdir ~/apps/apache/logs \
    && mkdir ~/logs/apache \
    && ln -s ~/logs/apache/ ~/apps/apache/logs


RUN mkdir /home1/irteam/apps/gz_dir \
    && mv /home1/irteam/apps/*.tar.gz /home1/irteam/apps/gz_dir

USER irteamsu
WORKDIR /home1/irteamsu/
RUN sudo chmod 755 /home1/irteam

RUN cd /home1/irteam/apps/apache/bin \
    && sudo chown root:irteam httpd \
    && sudo chmod 4755 httpd



USER irteam
WORKDIR /home1/irteam/

ENV LANG=ko_KR.utf8 TZ=Asia/Seoul

CMD ["/bin/bash"]

