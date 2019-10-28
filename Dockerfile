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
    && echo 'export PATH=/bin:/usr/bin:/usr/local/bin:$JAVA_HOME/bin:/home1/irteam/apps/tomcat1/bin:/home1/irteam/apps/tomcat2/bin' >> /etc/profile \
    && source /etc/profile


USER irteam

RUN mkdir /home1/irteam/apps /home1/irteam/logs

WORKDIR /home1/irteam/apps/
RUN wget http://apache.mirror.cdnetworks.com//apr/apr-1.7.0.tar.gz \
    && wget http://apache.mirror.cdnetworks.com//apr/apr-util-1.6.1.tar.gz \
    && wget ftp://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz \
    && wget http://mirror.navercorp.com/apache//httpd/httpd-2.4.41.tar.gz \
    && wget http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.4/bin/apache-tomcat-9.0.4.tar.gz \
    && wget http://apache.tt.co.kr/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz

RUN tar xvfz httpd-2.4.41.tar.gz \
    && tar xvfz apr-1.7.0.tar.gz \
    && tar xvfz apr-util-1.6.1.tar.gz \
    && tar xvfz pcre-8.43.tar.gz \
    && tar xvfz apache-tomcat-9.0.4.tar.gz \
    && mv apache-tomcat-9.0.4 tomcat1-9.0.4 \
    && tar xvfz apache-tomcat-9.0.4.tar.gz \
    && mv apache-tomcat-9.0.4 tomcat2-9.0.4 \
    && tar xvfz tomcat-connectors-1.2.46-src.tar.gz

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
    && ln -s tomcat1-9.0.4 tomcat1 \
    && ln -s tomcat2-9.0.4 tomcat2 \
    && ln -s tomcat-connectors-1.2.46-src mod_jk

RUN rmdir ~/apps/apache/logs \
    && mkdir ~/logs/apache \
    && ln -s ~/logs/apache/ ~/apps/apache/logs

RUN rmdir ~/apps/tomcat1/logs \
    && mkdir ~/logs/tomcat1 \
    && ln -s ~/logs/tomcat1/ ~/apps/tomcat1/logs

RUN rmdir ~/apps/tomcat2/logs \
    && mkdir ~/logs/tomcat2 \
    && ln -s ~/logs/tomcat2/ ~/apps/tomcat2/logs

RUN cd mod_jk/native \
	&& ./configure --with-apxs=/home1/irteam/apps/apache/bin/apxs \
	&& make && make install

RUN mkdir ~/apps/gz_dir \
    && mv ~/apps/*.tar.gz ~/apps/gz_dir    


WORKDIR /home1/irteam/apps/apache/conf/
RUN echo 'LoadModule jk_module modules/mod_jk.so' >> httpd.conf \
	&& echo '<IfModule jk_module>' >> httpd.conf \
	&& echo '    JkWorkersFile    conf/workers.properties' >> httpd.conf \
	&& echo '    JkLogFile        logs/mod_jk.log' >> httpd.conf \
	&& echo '    JkLogLevel       info' >> httpd.conf \
	&& echo '    JkMount /* load_balancer' >> httpd.conf \
	&& echo '</IfModule>' >> httpd.conf

WORKDIR /home1/irteam/apps/apache/conf/
RUN touch workers.properties \
	&& echo 'worker.list=load_balancer' >> workers.properties \
	&& echo 'worker.load_balancer.type=lb' >> workers.properties \
	&& echo 'worker.load_balancer.balance_workers=tomcat1,tomcat2' >> workers.properties \
	&& echo 'worker.tomcat1.port=18009' >> workers.properties \
	&& echo 'worker.tomcat1.host=localhost' >> workers.properties \
	&& echo 'worker.tomcat1.type=ajp13' >> workers.properties \
	&& echo 'worker.tomcat1.lbfactor=1' >> workers.properties \
	&& echo 'worker.tomcat2.port=28009' >> workers.properties \
	&& echo 'worker.tomcat2.host=localhost' >> workers.properties \
	&& echo 'worker.tomcat2.type=ajp13' >> workers.properties \
	&& echo 'worker.tomcat2.lbfactor=1' >> workers.properties

WORKDIR /home1/irteam/apps/tomcat1/conf/
RUN sed -i "22s/8005/18005/" server.xml \
	&& sed -i "69s/8080/18080/" server.xml \
	&& sed -i "116s/8009/18009/" server.xml

WORKDIR /home1/irteam/apps/tomcat2/conf/
RUN sed -i "22s/8005/28005/"  server.xml \
	&& sed -i "69s/8080/28080/" server.xml \
	&& sed -i "116s/8009/28009/" server.xml


USER irteamsu

WORKDIR /home1/irteamsu/
RUN sudo chmod 755 /home1/irteam

WORKDIR /home1/irteam/apps/
RUN sudo chown root:irteam ./apache/bin/httpd \
    && sudo chmod 4755 ./apache/bin/httpd

RUN sudo chown root:irteam tomcat1/bin/startup.sh \
    && sudo chmod 4755 tomcat1/bin/startup.sh \
    && sudo chown root:irteam tomcat2/bin/startup.sh \
    && sudo chmod 4755 tomcat2/bin/startup.sh


#USER irteam




ENV LANG=ko_KR.utf8 TZ=Asia/Seoul
 
CMD ["/bin/bash"]
