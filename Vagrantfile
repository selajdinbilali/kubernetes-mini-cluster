# -*- mode: ruby -*-
# vi: set ft=ruby :

# configuration de 3 machines virtuelles avec 1gb de RAM

Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end
  
  
  config.vm.define "master" do |master|
     master.vm.box = "centos/7"
     master.vm.network "private_network", ip: "192.168.50.130"
     master.vm.provision :shell, path: "master.sh"

  end

  config.vm.define "slave1" do |slave1|
     slave1.vm.box = "centos/7"
     slave1.vm.network "private_network", ip: "192.168.50.131"
     slave1.vm.provision :shell, path: "node01.sh"
  end

  config.vm.define "slave2" do |slave2|
     slave2.vm.box = "centos/7"
     slave2.vm.network "private_network", ip: "192.168.50.132"
     slave2.vm.provision :shell, path: "node02.sh"
  end

# a decommente si on veut un serveur nfs
  
#  config.vm.define "nfs" do |nfs|
#     nfs.vm.box = "centos/7"
#     nfs.vm.network "private_network", ip: "192.168.50.133"
#  end

end
