FROM docker.io/centos:7.4.1708
MAINTAINER Shinhye Yi <shinhye.yi@navercorp.com>

USER root

RUN yum clean all \
    && yum repolist \
    && yum -y update \
    && yum -y install sudo

RUN mkdir /home1 \
    && useradd -d /home1/irteam -m irteam \
    && useradd -d /home1/irteamsu -m irteamsu \
    && echo "irteamsu ALL=NOPASSWD:ALL" >> /etc/sudoers

RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64' >> /etc/profile \
    && echo 'export CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar' >> /etc/profile \
    && echo 'PATH=/bin:/usr/bin:/usr/local/bin:$JAVA_HOME/bin:/home1/irteam/apps/tomcat1/bin:/home1/irteam/apps/tomcat2/bin' >> /etc/profile \
    && source /etc/profile

RUN /usr/bin/localedef --force --inputfile en_US --charmap UTF-8 en_US.UTF-8 && \
    echo "export LANG=en_US.UTF-8" > /etc/profile.d/locale.sh


USER irteamsu

RUN sudo yum clean all \
  && sudo yum -y reinstall glibc-common


RUN sudo yum -y install tar vim telnet net-tools curl openssl openssl-devel \
 && sudo yum -y install apr apr-util apr-devel apr-util-devel \
 && sudo yum -y install elinks locate python-setuptools \
 && sudo yum -y install gcc make gcc-c++ wget \
 && sudo yum -y install java-1.8.0-openjdk-devel.x86_64 \
 && sudo yum -y install cmake ncurses ncurses-devel \
 && sudo yum clean all

RUN sudo yum -y install libxml2 libxml2-devel \
    && sudo yum -y install gd gd-devel postfix unzip \
    && sudo yum -y install gettext autoconf automake net-snmp net-snmp-utils \
    && sudo yum -y install glibc epel-release perl-Net-SNMP \
    && sudo yum install -y perl-XML-XPath perl-libwww-perl \
    && sudo yum remove -y mariadb-libs-5.5.64-1.el7.x86_64

RUN sudo chmod 755 /home1/irteam

USER irteam

RUN mkdir /home1/irteam/apps /home1/irteam/logs

# install and unzip tar files
WORKDIR /home1/irteam/apps/
RUN wget http://apache.mirror.cdnetworks.com//apr/apr-1.7.0.tar.gz \
    && wget http://apache.mirror.cdnetworks.com//apr/apr-util-1.6.1.tar.gz \
    && wget ftp://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz \
    && wget http://mirror.navercorp.com/apache//httpd/httpd-2.4.41.tar.gz \
    && wget http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.4/bin/apache-tomcat-9.0.4.tar.gz \
    && wget http://apache.tt.co.kr/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz \
    && wget https://downloads.mysql.com/archives/get/file/mysql-5.7.27.tar.gz \
    && wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.18.tar.gz \
    && wget http://museum.php.net/php5/php-5.5.0.tar.gz \
    && wget https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.5.tar.gz \
    && wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz

RUN find . -name "*.tar.gz" -exec tar xvfz {} \;

RUN mv apache-tomcat-9.0.4 tomcat1 \
    && tar xvfz apache-tomcat-9.0.4.tar.gz \
    && mv apache-tomcat-9.0.4 tomcat2


# locate libraries

RUN mv apr-1.7.0 ./httpd-2.4.41/srclib/apr \
    && mv apr-util-1.6.1 ./httpd-2.4.41/srclib/apr-util

RUN cp mysql-connector-java-8.0.18/mysql-connector-java-8.0.18.jar tomcat1/lib/ \
    && cp mysql-connector-java-8.0.18/mysql-connector-java-8.0.18.jar tomcat2/lib/

RUN ln -s tomcat-connectors-1.2.46-src mod_jk


# Makefile

WORKDIR /home1/irteam/apps/pcre-8.43
RUN ./configure --prefix=/home1/irteam/apps/pcre \
    && make && make install

WORKDIR /home1/irteam/apps/httpd-2.4.41
RUN ./configure --prefix=/home1/irteam/apps/apache --enable-module=so --enable-mods-shared=ssl --with-ssl=/usr/lib64/openssl --enable-ssl=shared --with-pcre=/home1/irteam/apps/pcre/bin/pcre-config \
    && make && make install

WORKDIR /home1/irteam/apps/mod_jk/native/ \
RUN ./configure --with-apxs=/home1/irteam/apps/apache/bin/apxs \
    && make && make install

WORKDIR /home1/irteam/apps/php-5.5.0/
RUN ./configure --prefix=/home1/irteam/apps/php --with-apxs2=/home1/irteam/apps/apache/bin/apxs \
    && make && make install

RUN cp php.ini-development ~/apps/apache/conf/php.ini

WORKDIR /home1/irteam/apps/mysql-5.7.27/
RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/home1/irteam/apps/mysql \
    -DMYSQL_DATADIR=/home1/irteam/apps/mysql/data \
    -DMYSQL_UNIX_ADDR=/home1/irteam/apps/mysql/tmp/myqld.sock \
    -DSYSCONFDIR=/home1/irteam/apps/mysql/etc \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS=all \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=$HOME/apps/my_boost

RUN make && make install

WORKDIR /home1/irteam/apps/nagioscore-nagios-4.4.5/
RUN ./configure --prefix=/home1/irteam/apps/nagios --with-nagios-user=irteam --with-nagios-group=irteam --with-command-user=irteam --with-command-group=irteam --with-httpd-conf=/home1/irteam/apps/apache/conf --with-logdir=/home1/irteam/logs/nagios --with-initdir=/home1/irteam/apps/nagios/init.d 

RUN make all && make install

RUN make install-config && make install-commandmode \
    && make install-webconf

USER irteamsu
RUN sudo make install-init

WORKDIR /home1/irteam/apps/nagios/
RUN sudo chown irteam:irteam init.d \
    && sudo chown root:irteam init.d/nagios \
    && sudo chmod 4755 init.d/nagios


USER irteam
WORKDIR /home1/irteam/apps/nagios-plugins-release-2.2.1/
RUN ./tools/setup \
    && ./configure --prefix=/home1/irteam/apps/nagios --with-mysql=/home1/irteam/apps/mysql/bin/mysql_config \
    && make && make install


# Create link for logs
USER irteam
RUN rmdir ~/apps/apache/logs \
    && mkdir ~/logs/apache \
    && ln -s ~/logs/apache/ ~/apps/apache/logs

RUN rmdir ~/apps/tomcat1/logs \
    && mkdir ~/logs/tomcat1 \
    && ln -s ~/logs/tomcat1/ ~/apps/tomcat1/logs

RUN rmdir ~/apps/tomcat2/logs \
    && mkdir ~/logs/tomcat2 \
    && ln -s ~/logs/tomcat2/ ~/apps/tomcat2/logs


# Move gzip files to directory

RUN mkdir ~/apps/gz_dir \
    && mv ~/apps/*.tar.gz ~/apps/gz_dir



# Settings

WORKDIR /home1/irteam/apps/apache/conf/

RUN sed -i "199s/#//" httpd.conf \
    && sed -i "199s/www.example.com:80/localhost/" httpd.conf

# Connect tomcat1,2 and apache

RUN echo 'LoadModule jk_module modules/mod_jk.so' >> httpd.conf \
    && echo '<IfModule jk_module>' >> httpd.conf \
    && echo '    JkWorkersFile    conf/workers.properties' >> httpd.conf \
    && echo '    JkLogFile        logs/mod_jk.log' >> httpd.conf \
    && echo '    JkLogLevel       info' >> httpd.conf \
    && echo '    JkMountFile      conf/uriworkermap.properties' >> httpd.conf \
    && echo '</IfModule>' >> httpd.conf

RUN touch uriworkermap.properties \
    && echo '/*.jsp=load_balancer' >> uriworkermap.properties

RUN touch workers.properties \
    && echo 'worker.list=load_balancer' >> workers.properties \
    && echo 'worker.load_balancer.type=lb' >> workers.properties \
    && echo 'worker.load_balancer.balance_workers=tomcat1,tomcat2' >> workers.properties \
    && echo 'worker.tomcat1.port=8109' >> workers.properties \
    && echo 'worker.tomcat1.host=localhost' >> workers.properties \
    && echo 'worker.tomcat1.type=ajp13' >> workers.properties \
    && echo 'worker.tomcat1.lbfactor=1' >> workers.properties \
    && echo 'worker.tomcat2.port=8209' >> workers.properties \
    && echo 'worker.tomcat2.host=localhost' >> workers.properties \
    && echo 'worker.tomcat2.type=ajp13' >> workers.properties \
    && echo 'worker.tomcat2.lbfactor=1' >> workers.properties


# Set SSL on apache

RUN sed -i "89s/#//" httpd.conf \
    && sed -i "137s/#//" httpd.conf \
    && sed -i "499s/#//" httpd.conf
    
RUN openssl genrsa -aes256 -out tmp-server.key -passout pass:1234 2048 \
    && openssl rsa -in tmp-server.key -out server.key -passin pass:1234 \
    && openssl req -new -key server.key -out server.csr -subj "/C=KR/ST=Gyeonggi-do/L=Seongnam-si/O=global Security/OU=IT" \
    && openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

RUN sed -i "122s/.*/JkMountFile conf\/uriworkermap.properties/g" ./extra/httpd-ssl.conf


# Connect php and apache

RUN sed -i "1198s/=/=\/home1\/irteam\/apps\/mysql\/tmp\/mysqld.sock/" php.ini
RUN sed -i "147s/#//" httpd.conf
RUN sed -i "257s/html/html index.php/" httpd.conf

RUN perl -p -i -e '$.==394 and print "AddType application/x-httpd-php .php .html .php5\n"' httpd.conf \
    && perl -p -i -e '$.==395 and print "AddType application/x-httpd-php-source .phps\n"' httpd.conf


# Setting for Nagios
RUN echo "Include conf/nagios.conf" >> httpd.conf \
    && ../bin/htpasswd -b -c ~/apps/nagios/etc/htpasswd.users nagiosadmin nagios12


# Change port num and clusterting setting on Tomcat1,2

WORKDIR /home1/irteam/apps/tomcat1/conf/
RUN sed -i "22s/8005/8105/" server.xml \
    && sed -i "116s/8009/8109/" server.xml \
    && sed -i "133s/<\!--//" server.xml \
    && sed -i "135s/-->//" server.xml

WORKDIR /home1/irteam/apps/tomcat2/conf/
RUN sed -i "22s/8005/8205/" server.xml \
    && sed -i "69s/8080/8081/" server.xml \
    && sed -i "116s/8009/8209/" server.xml \
    && sed -i "133s/<\!--//" server.xml \
    && sed -i "135s/-->//" server.xml



# Setting MySQL

WORKDIR /home1/irteam/apps/mysql/
RUN mkdir tmp etc && touch etc/my.cnf

RUN echo -e '[client]\nuser=root\npassword=root1234\nport = 13306\nsocket = /home1/irteam/apps/mysql/tmp/mysqld.sock' >> etc/my.cnf\
    && echo -e '[mysqld]\nuser=root\nport = 13306\nbasedir=/home1/irteam/apps/mysql\ndatadir=/home1/irteam/apps/mysql/data\nsocket=/home1/irteam/apps/mysql/tmp/mysqld.sock' >> etc/my.cnf \
    && echo -e 'log-error=/home1/irteam/apps/mysql/data/mysqld.log\npid-file=/home1/irteam/apps/mysql/tmp/mysqld.pid' >> etc/my.cnf 

RUN echo -e 'key_buffer_size = 384M\nmax_allowed_packet = 1M\ntable_open_cache = 512\nsort_buffer_size = 2M\nread_buffer_size = 2M\nread_rnd_buffer_size = 8M\nthread_cache_size = 8\nquery_cache_size = 32M' >> etc/my.cnf \
    && echo -e 'max_connections = 1000\nmax_connect_errors = 1000\nwait_timeout= 60\nexplicit_defaults_for_timestamp' >> etc/my.cnf \
    && echo -e 'character-set-client-handshake=FALSE\ninit_connect = SET collation_connection = utf8_general_ci\ninit_connect = SET NAMES utf8\ncharacter-set-server = utf8\ncollation-server = utf8_general_ci' >> etc/my.cnf

RUN echo -e 'default-storage-engine = InnoDB\ninnodb_buffer_pool_size = 503MB\ninnodb_data_file_path = ibdata1:10M:autoextend\ninnodb_write_io_threads = 8\ninnodb_read_io_threads = 8\ninnodb_thread_concurrency = 16\ninnodb_flush_log_at_trx_commit = 1\ninnodb_log_buffer_size = 8M\ninnodb_log_file_size = 128M\ninnodb_log_files_in_group = 3\ninnodb_max_dirty_pages_pct = 90\ninnodb_lock_wait_timeout = 120' >> etc/my.cnf

RUN echo -e 'symbolic-links=0\nskip-external-locking\nskip-grant-tables' >> etc/my.cnf



# Change root passwd on MySQL

RUN bin/mysqld --initialize \ 
    && support-files/mysql.server start \
    && bin/mysql <<< "UPDATE mysql.user SET authentication_string=PASSWORD('root1234') WHERE user='root' AND Host='localhost'; FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY 'root1234';" \ 
    && sed -i '$d' etc/my.cnf \
    && support-files/mysql.server stop



# Set Nagios Monitoring for Tomcat & MySQL

# Create Tomcat manager account
WORKDIR /home1/irteam/apps/tomcat1/conf/
RUN echo "<role rolename="manager-gui"/>" >> tomcat-user.xml \
    && echo "<role rolename="manager-script"/>" >> tomcat-user.xml \
    && echo "<role rolename="manager-status"/>" >> tomcat-user.xml \
    && echo "<user username="tomcatadmin" password="tomcat12" roles="manager-gui,manager-script,manager-status"/>" >> tomcat-user.xml

WORKDIR /home1/irteam/apps/tomcat2/conf/
RUN echo "<role rolename="manager-gui"/>" >> tomcat-user.xml \
    && echo "<role rolename="manager-script"/>" >> tomcat-user.xml \
    && echo "<role rolename="manager-status"/>" >> tomcat-user.xml \
    && echo "<user username="tomcatadmin" password="tomcat12" roles="manager-gui,manager-script,manager-status"/>" >> tomcat-user.xml

# Install check_tomcat plugin
WORKDIR /home1/irteam/apps/nagios/libexec/
RUN curl "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=2522&cf_id=24" -o check_tomcat.pl

USER irteamsu
RUN sudo chmod u+x check_tomcat.pl

USER irteam
RUN ./check_tomcat.pl -I 127.0.0.1 -p 8080 -l tomacatadmin -a tomcat12 -w 20%,30% -c 10%,20%
RUN ./check_tomcat.pl -I 127.0.0.1 -p 8081 -l tomacatadmin -a tomcat12 -w 20%,30% -c 10%,20%


WORKDIR /home1/irteam/apps/nagios/etc/objects/
RUN echo "define command {" >> commands.cfg \
    && echo "    command_name    check_tomcat" >> commands.cfg \
    && echo "    command_line    /bin/sh -c \"$USER1$/check_tomcat.pl -H $HOSTADDRESS$ -p $ARG1$ -l $ARG2$ -a $ARG3$\"" >> commands.cfg \
    && echo "}" >> commands.cfg

RUN echo -e "define service {\n\n" >> localhost.cfg \
    && echo "    use                     local-service" >> localhost.cfg \
    && echo "    host_name               localhost" >> localhost.cfg \
    && echo "    service_description     Tomcat1" >> localhost.cfg \
    && echo "    check_command           check_tomcat!8080!tomcatadmin!tomcat12" >> localhost.cfg \
    && echo "    check_interval          1" >> localhost.cfg \
    && echo -e "    retry_interval          1\n}" >> localhost.cfg

RUN echo -e "define service {\n\n" >> localhost.cfg \
    && echo "    use                     local-service" >> localhost.cfg \
    && echo "    host_name               localhost" >> localhost.cfg \
    && echo "    service_description     Tomcat1" >> localhost.cfg \
    && echo "    check_command           check_tomcat!8080!tomcatadmin!tomcat12" >> localhost.cfg \
    && echo "    check_interval          1" >> localhost.cfg \
    && echo -e "    retry_interval          1\n}" >> localhost.cfg


#
# TODO: Install check_mysql plugin
#



USER irteamsu

WORKDIR /home1/irteam/apps/
RUN sudo chown root:irteam apache/bin/httpd \
    && sudo chmod 4755 apache/bin/httpd

RUN sudo chown root:irteam tomcat1/bin/startup.sh \
    && sudo chmod 4755 tomcat1/bin/startup.sh \
    && sudo chown root:irteam tomcat2/bin/startup.sh \
    && sudo chmod 4755 tomcat2/bin/startup.sh



# USER irteam
# WORKDIR /home1/irteam/


ENV LANG=ko_KR.utf8 TZ=Asia/Seoul


EXPOSE 13306
EXPOSE 80 443
EXPOSE 8080 8081


CMD ["/bin/bash"]

