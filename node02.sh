#!/usr/bin/env bash
systemctl stop firewalld
systemctl disable firewalld

yum -y install ntp
systemctl start ntpd
systemctl enable ntpd

yum -y install flannel kubernetes

echo "
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
" > /etc/sysconfig/selinux

echo "
# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD=\"http://192.168.50.130:2379\"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_KEY=\"/atomic.io/network\"

# Any additional options that you want to pass
FLANNEL_OPTIONS=\"--iface=eth1\"
" > /etc/sysconfig/flanneld

echo "
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR=\"--logtostderr=true\"

# journal message level, 0 is debug
KUBE_LOG_LEVEL=\"--v=0\"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV=\"--allow-privileged=false\"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER=\"--master=http://192.168.50.130:8080\"
" > /etc/kubernetes/config

echo "
KUBELET_ADDRESS=\"--address=0.0.0.0\"
KUBELET_PORT=\"--port=10250\"
# change the hostname to this host’s IP address
KUBELET_HOSTNAME=\"--hostname_override=192.168.50.132\"
KUBELET_API_SERVER=\"--api_servers=http://192.168.50.130:8080\"
KUBELET_ARGS=\"--cluster_dns=10.254.0.10 --cluster_domain=cluster.local --resolv-conf=\"\"\"
" > /etc/kubernetes/kubelet


# configuration de docker pour le registre prive
echo "
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS='--selinux-enabled --log-driver=journald'
DOCKER_CERT_PATH=/etc/docker

# If you want to add your own registry to be used for docker search and docker
# pull use the ADD_REGISTRY option to list a set of registries, each prepended
# with --add-registry flag. The first registry added will be the first registry
# searched.
#ADD_REGISTRY='--add-registry registry.access.redhat.com'

# If you want to block registries from being used, uncomment the BLOCK_REGISTRY
# option and give it a set of registries, each prepended with --block-registry
# flag. For example adding docker.io will stop users from downloading images
# from docker.io
# BLOCK_REGISTRY='--block-registry'

# If you have a registry secured with https but do not have proper certs
# distributed, you can tell docker to not look for full authorization by
# adding the registry to the INSECURE_REGISTRY line and uncommenting it.
INSECURE_REGISTRY='--insecure-registry=192.168.50.130:5000'

# On an SELinux system, if you remove the --selinux-enabled option, you
# also need to turn on the docker_transition_unconfined boolean.
# setsebool -P docker_transition_unconfined 1

# Location used for temporary files, such as those created by
# docker load and build operations. Default is /var/lib/docker/tmp
# Can be overriden by setting the following environment variable.
# DOCKER_TMPDIR=/var/tmp

# Controls the /etc/cron.daily/docker-logrotate cron job status.
# To disable, uncomment the line below.
# LOGROTATE=false
#

# docker-latest daemon can be used by starting the docker-latest unitfile.
# To use docker-latest client, uncomment below line
#DOCKERBINARY=/usr/bin/docker-latest
" > /etc/sysconfig/docker

for SERVICES in kube-proxy kubelet docker flanneld; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
done

ip a | grep flannel | grep inet

echo "INSTALLATION DU NODE-02 TERMINEE"

reboot
