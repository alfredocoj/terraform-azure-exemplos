#!/bin/bash

useradd -s /bin/bash -m k8s-admin
passwd k8s-admin
usermod -aG sudo k8s-admin
usermod -aG docker k8s-admin
echo "k8s-admin ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/k8s-admin

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common vim mcedit nfs-common wget

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
# add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list
apt-get update
#apt-get install -y docker-ce docker-ce-cli containerd.io kubelet kubeadm kubectl

apt-get install -y kubelet=1.17.3-00 kubeadm=1.17.3-00 kubectl=1.17.3-00 kubernetes-cni=0.7.5-00


##Setting Limits on Ubuntu 16.04
##Open the grub configuration file in a text editor.
#nano /etc/default/grub
##Add the following line. If the GRUB_CMDLINE_LINUX optional already exists, modify it to include the values below.
#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
##Save your changes and exit the text editor.

sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& cgroup_enable=memory swapaccount=1/' /etc/default/grub

##Update the grub configuration.

sudo update-grub


sudo kubeadm init