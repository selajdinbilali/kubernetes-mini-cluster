#!/usr/bin/env bash

# arrete et desactive le firewall
systemctl stop firewalld
systemctl disable firewalld

# install ntp pour la synchronisation du temps et l'active au demarrage
yum -y install ntp
systemctl start ntpd
systemctl enable ntpd

# installation des paquets etcd, kubernetes et flannel
yum -y install etcd kubernetes flannel

# configuration de flannel
echo "
# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
# adresse du master qui contient etcd
FLANNEL_ETCD=\"http://192.168.50.130:2379\"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_KEY=\"/atomic.io/network\"

# Any additional options that you want to pass
# ajout de l'option --iface=eth1 pour pointer sur la bonne interface ethernet
FLANNEL_OPTIONS=\"--iface=eth1\"
" > /etc/sysconfig/flanneld

# desactivation de selinux

echo "
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
" > /etc/sysconfig/selinux


# configuration d'etcd

echo "
ETCD_NAME=default
ETCD_DATA_DIR=\"/var/lib/etcd/default.etcd\"
ETCD_LISTEN_CLIENT_URLS=\"http://0.0.0.0:2379\"
ETCD_ADVERTISE_CLIENT_URLS=\"http://localhost:2379\"
" > /etc/etcd/etcd.conf

# configuration de l'apiserver

echo "
# ecoute sur toutes les adresse de maniere non securisee
KUBE_API_ADDRESS=\"--insecure-bind-address=0.0.0.0\"
KUBE_API_PORT=\"--port=8080\"
KUBELET_PORT=\"--kubelet_port=10250\"
# pointe sur le server etcd qui est dans le master donc localhost
KUBE_ETCD_SERVERS=\"--etcd_servers=http://127.0.0.1:2379\"
# plage des adresse pour les services
KUBE_SERVICE_ADDRESSES=\"--service-cluster-ip-range=10.254.0.0/16\"
# securite pour l'admission des services
KUBE_ADMISSION_CONTROL=\"--admission_control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota\"
KUBE_API_ARGS=\"\"
" > /etc/kubernetes/apiserver

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


# on active les services a chaque demarrage
for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler docker flanneld; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
done

# on inscrit dans etcd la plage des noeuds

etcdctl mk /atomic.io/network/config '{"Network":"172.17.0.0/16"}'

# a decommenter si on veut installer un registre prive
#docker run --restart=always -d -p 5000:5000 --name registry registry:2

echo "INSTALLATION DU MASTER TERMINEE"

# on redemmare

reboot
