# kubernetes-mini-cluster
A mini cluster with kubernetes

## First

Install vagrant and virtualbox

## Second

clone this repo

## Third

vagrant up


## Optionally (have fun)

### Install the dns with
```shell
$ kubectl create -f master/dns-svc.yml
$ kubectl create -f master/dns-rc.yml
```

### Install heapster with
```shell
$ kubectl create -f maste/heapster-master/deploy/kube-config/influxdb/
```

### Install the dashboard with
```shell
$ kubectl create -f master/kubernetes-dashboard.yaml
```

