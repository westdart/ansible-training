
Sources:
- https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cri-o


# Install CRI-O
## Prerequisites
### Enable linux modules
```
modprobe overlay
modprobe br_netfilter
```
### Set up required sysctl params, these persist across reboots.
```
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system
```

## Enable repos
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:1.18.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.18/CentOS_7/devel:kubic:libcontainers:stable:cri-o:1.18.repo

## Install CRI-O
yum install -y cri-o

# Start CRI-O
```
systemctl daemon-reload
systemctl start crio
```