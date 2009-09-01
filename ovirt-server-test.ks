install

lang en_US.UTF-8
keyboard us
# should have address on default libvirt network
network --device=eth0 --bootproto=static --ip=192.168.122.190 --netmask=255.255.255.0 --onboot=on --nameserver=192.168.122.1 --gateway=192.168.122.1
# Root password is 'ovirt'
rootpw --iscrypted Xa8QeYfWrtscM
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --disabled
# NOTE: ntp/ntpdate need to stay in this list to ensure that time on the
# appliance is correct prior to the ovirt-server-installer being run.  Otherwise you
# get Kerberos errors
services --disabled=libvirtd,postgresql --enabled=network,iptables,ntpdate,acpid,sshd
timezone --utc UTC
text

bootloader --location=mbr --driveorder=sda --append="console=tty0"
zerombr
clearpart --all --drives=sda
part /boot  --ondisk=sda --fstype=ext3 --size=100
part /      --ondisk=sda --fstype=ext3 --size=5000
part swap   --ondisk=sda --fstype=swap --size=512
reboot

repo --name=f10 --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-10&arch=x86_64
repo --name=ovirt-org --baseurl=http://ovirt.org/repos/ovirt/10/x86_64
repo --name=f10-updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f10&arch=x86_64
repo --name=ovirt-local --baseurl=file:///var/lib/builder/ovirt/package-root/rpm/RPMS

%packages --excludedocs --nobase
%include /usr/share/appliance-os/includes/base-pkgs.ks
openssh-server
ovirt-server
ovirt-server-installer
ovirt-node-image-pxe
