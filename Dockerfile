# services

FROM centos:7.4.1708
#MAINTAINER
#LABEL 

#
# build time argument
# TENANT_URL: tenant URL
# ARG TENANT_URL

#
# environment variables
# CODE: enrollment code
# LOGIN_ROLE: roles that can login

# the following variables are optional
# PORT: SSH port (default: 22)
# NAME: name of system
# ADDRESS: address of system
# CONNECTOR: connector to use
# OPTION: optional parameters for cenroll command

# fill in the correct values for the followings
ENV CODE ""
ENV PORT ""
ENV NAME ""
ENV ADDRESS ""
ENV CONNECTOR ""
ENV LOGIN_ROLE ""
ENV TENANT_URL ""
ENV HTTP_PORT ${PORT:-22}

STOPSIGNAL SIGRTMIN+3

# install and configure openssh
RUN yum -y update && yum install -y openssh-server vim openssh-clients
RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN sed -i '/^PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
RUN sed -i '/^ChallengeResponseAuthentication/c\ChallengeResponseAuthentication yes' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd


# install systemd
RUN yum -y install systemd; yum clean all; \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done ); 

VOLUME [ "/sys/fs/cgroup" ]

# note that systemd comes with journald in CentOS...no need to install rsyslog

# install net-tools so we can figure out our IP address
RUN yum -y install net-tools

# enable and start services
RUN systemctl enable sshd.service

# download Centrify Agent
RUN curl --fail -s -o /tmp/CentrifyCC-rhel6.x86_64.rpm http://edge.centrify.com/products/cloud-service/CliDownload/Centrify/CentrifyCC-rhel6.x86_64.rpm

# install Centrify Agent
RUN yum -y install /tmp/CentrifyCC-rhel6.x86_64.rpm

# create a new service for unenroll Centrify agent
COPY centrifycc-unenroll.service /usr/lib/systemd/system/centrifycc-unenroll.service
RUN systemctl enable centrifycc-unenroll.service

# copy the script that set the root password so that it is run by cenroll
# it must be in a root-owned not world writable directory (e.g., /var/centrify/tmp)
#
RUN mkdir -p /var/centrify/tmp
COPY setpasswd.sh /var/centrify/tmp
RUN chmod 700 /var/centrify/tmp/setpasswd.sh

# modify the configuration file to run setpasswd.sh as postenroll hook
RUN echo "cli.hook.cenroll: /var/centrify/tmp/setpasswd.sh" >> /etc/centrifycc/centrifycc.conf

# note that the selinux policy set to enforcing
# change to permissive for now

RUN sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

COPY ./cjoin_startup.sh /tmp/cjoin_startup.sh
RUN chmod 500 /tmp/cjoin_startup.sh

EXPOSE 22

CMD ["/tmp/cjoin_startup.sh"]

