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
    && mkdir home1 \
    && useradd -d /home1/irteam -m irteam \
    && useradd -d /home1/irteamsu -m irteamsu \
    && echo "irteamsu ALL=NOPASSWD: ALL" >> /etc/sudoers


RUN yum -y install gcc make gcc-c++ wget

ENV LANG=ko_KR.utf8 TZ=Asia/Seoul

CMD ["/bin/bash"]
