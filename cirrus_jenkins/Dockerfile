FROM jenkins/jenkins:2.319.3-centos7-jdk8
#VOLUME /jenkins_var
#MAINTAINER shaik  <shaik@coredge.io>

# Skip initial sietup
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt
USER root
RUN  yum  update  -y
RUN  yum install -y yum-utils device-mapper-persistent-data lvm2
RUN  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN yum install http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-3.el7.noarch.rpm -y
RUN   yum install   docker-ce -y
RUN usermod -aG docker jenkins
#RUN  yum  clean
ENV JENKINS_HOME /var/lib/jenkins
WORKDIR /var/lib/jenkins
RUN mkdir -p $JENKINS_HOME/jobs/1.0_MAAS_APPLICATION_DEPLOYMENT
COPY 1.0_MAAS_APPLICATION_DEPLOYMENT_config.xml  $JENKINS_HOME/jobs/1.0_MAAS_APPLICATION_DEPLOYMENT/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/1.1_MAAS_AUTOMATION_NODE_ALLOCATION
COPY 1.1_MAAS_AUTOMATION_NODE_ALLOCATION_config.xml $JENKINS_HOME/jobs/1.1_MAAS_AUTOMATION_NODE_ALLOCATION/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/1.2_MAAS_AUTOMATION_BAREMETAL_OS_DEPLOY
COPY 1.2_MAAS_AUTOMATION_BAREMETAL_OS_DEPLOY_config.xml $JENKINS_HOME/jobs/1.2_MAAS_AUTOMATION_BAREMETAL_OS_DEPLOY/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/1.3_MAAS_AUTOMATION_POST_OS_DEPLOY_CONFIG
COPY 1.3_MAAS_AUTOMATION_POST_OS_DEPLOY_CONFIG_config.xml $JENKINS_HOME/jobs/1.3_MAAS_AUTOMATION_POST_OS_DEPLOY_CONFIG/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/1.4_MAAS_AUTOMATION_POST_CHECK
COPY 1.4_MAAS_AUTOMATION_POST_CONFIG_CHECK_config.xml $JENKINS_HOME/jobs/1.4_MAAS_AUTOMATION_POST_CONFIG_CHECK/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/2.1_External_Ceph_Deployment
COPY 2.1_External_Ceph_Deployment_config.xml $JENKINS_HOME/jobs/2.1_External_Ceph_Deployment/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/3.1_Openstack_Deployment
COPY 3.1_Openstack_Deployment_config.xml $JENKINS_HOME/jobs/3.1_Openstack_Deployment/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/3.2_OpenstackHealtcheck
COPY 3.2_OpenstackHealtcheck_config.xml $JENKINS_HOME/jobs/3.2_OpenstackHealtcheck/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/3.3_Openstack_Upgrade
COPY 3.3_Openstack_Upgrade_config.xml $JENKINS_HOME/jobs/3.3_Openstack_Upgrade/config.xml
RUN mkdir -p $JENKINS_HOME/jobs/3.4_Openstack_Compute_Add_Remove
COPY 3.4_Openstack_Compute_Add_Remove_config.xml $JENKINS_HOME/jobs/3.4_Openstack_Compute_Add_Remove/config.xml
#RUN mkdir -p  $JENKINS_HOME
COPY views1_config.xml $JENKINS_HOME/config.xml
COPY maas_automated $JENKINS_HOME/maas_automated
COPY maas_manual $JENKINS_HOME/maas_manual
COPY ceph $JENKINS_HOME/ceph
COPY maas_package_install $JENKINS_HOME/maas_package_install
COPY openstack $JENKINS_HOME/openstack
