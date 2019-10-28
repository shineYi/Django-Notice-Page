FROM docker.io/centos:7.4.1708
MAINTAINER Shinhye Yi <shinhye.yi@navercorp.com>

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

RUN yum -y install  java-1.8.0-openjdk-devel.x86_64 \
    && yum clean all

RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64' >> /etc/profile \
    && echo 'export CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar' >> /etc/profile \
    && echo 'export PATH=/bin:/usr/bin:/usr/local/bin:$JAVA_HOME/bin:/home1/irteam/apps/tomcat/bin' >> /etc/profile \
    && source /etc/profile


USER irteam

RUN mkdir /home1/irteam/apps /home1/irteam/logs

WORKDIR /home1/irteam/apps/
RUN wget http://apache.mirror.cdnetworks.com//apr/apr-1.7.0.tar.gz \
    && wget http://apache.mirror.cdnetworks.com//apr/apr-util-1.6.1.tar.gz \
    && wget ftp://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz \
    && wget http://mirror.navercorp.com/apache//httpd/httpd-2.4.41.tar.gz \
    && wget http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.4/bin/apache-tomcat-9.0.4.tar.gz

RUN tar xvfz httpd-2.4.41.tar.gz \
    && tar xvfz apr-1.7.0.tar.gz \
    && tar xvfz apr-util-1.6.1.tar.gz \
    && tar xvfz pcre-8.43.tar.gz \
    && tar xvfz apache-tomcat-9.0.4.tar.gz

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
    && ln -s apache_2.4.41 apache \
    && ln -s apache-tomcat-9.0.4 tomcat

RUN rmdir ~/apps/apache/logs \
    && mkdir ~/logs/apache \
    && ln -s ~/logs/apache/ ~/apps/apache/logs

RUN rmdir ~/apps/tomcat/logs \
    && mkdir ~/logs/tomcat \
    && ln -s ~/logs/tomcat/ ~/apps/tomcat/logs

RUN mkdir ~/apps/gz_dir \
    && mv ~/apps/*.tar.gz ~/apps/gz_dir    


USER irteamsu

WORKDIR /home1/irteamsu/
RUN sudo chmod 755 /home1/irteam

WORKDIR /home1/irteam/apps/
RUN sudo chown root:irteam ./apache/bin/httpd \
    && sudo chmod 4755 ./apache/bin/httpd

RUN sudo chown root:irteam ./tomcat/bin/startup.sh \
    && sudo chmod 4755 ./tomcat/bin/startup.sh


USER irteam
WORKDIR /home1/irteam/


ENV LANG=ko_KR.utf8 TZ=Asia/Seoul
 
CMD ["/bin/bash"]
