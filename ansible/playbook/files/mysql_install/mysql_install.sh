#!/bin/bash
echo "HOSTNAME: " `hostname`
echo "BEGIN - [`date +%d/%m/%Y" "%H:%M:%S`]"
echo "##############"
echo "$1" > /tmp/MYSQL_VERSION
MYSQL_VERSION=$(cat /tmp/MYSQL_VERSION)
echo "$2" > /tmp/MYSQL_MINOR_VERSION
MYSQL_MINOR_VERSION=$(cat /tmp/MYSQL_MINOR_VERSION)

# os_type = rhel
os_type=
# os_version as demanded by the OS (codename, major release, etc.)
os_version=
supported="Only RHEL/CentOS 7 & 8 are supported for this installation process."

msg(){
    type=$1 #${1^^}
    shift
    printf "[$type] %s\n" "$@" >&2
}

error(){
    msg error "$@"
    exit 1
}

identify_os(){
    arch=$(uname -m)
    # Check for RHEL/CentOS, Fedora, etc.
    if command -v rpm >/dev/null && [[ -e /etc/redhat-release || -e /etc/os-release ]]
    then
        os_type=rhel
        el_version=$(rpm -qa '(oraclelinux|sl|redhat|centos|fedora|rocky|alma|system)*release(|-server)' --queryformat '%{VERSION}')
        case $el_version in
            1*) os_version=6 ; error "RHEL/CentOS 6 is no longer supported" "$supported" ;;
            2*) os_version=7 ;;
            5*) os_version=5 ; error "RHEL/CentOS 5 is no longer supported" "$supported" ;;
            6*) os_version=6 ; error "RHEL/CentOS 6 is no longer supported" "$supported" ;;
            7*) os_version=7 ;;
            8*) os_version=8 ;;
             *) error "Detected RHEL or compatible but version ($el_version) is not supported." "$supported"  "$otherplatforms" ;;
         esac
         if [[ $arch == aarch64 ]] && [[ $os_version != 7 ]]; then error "Only RHEL/CentOS 7 are supported for ARM64. Detected version: '$os_version'"; fi
    fi

    if ! [[ $os_type ]] || ! [[ $os_version ]]
    then
        error "Could not identify OS type or version." "$supported"
    fi
}

### OS auto discovey to identify which is the OS and version thats been used it.
identify_os

echo $os_type
echo $os_version

##### FIREWALLD DISABLE ########################
systemctl disable firewalld
systemctl stop firewalld
######### SELINUX ###############################
sed -ie 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# disable selinux on the fly
/usr/sbin/setenforce 0

### clean yum cache ###
rm -rf /etc/yum.repos.d/MariaDB.repo
rm -rf /etc/yum.repos.d/mariadb.repo
rm -rf /etc/yum.repos.d/mysql-community.repo
rm -rf /etc/yum.repos.d/mysql-community-source.repo
rm -rf /etc/yum.repos.d/percona-original-release.repo
yum clean all

####### PACKAGES ###########################
if [[ $os_type == "rhel" ]]; then
    # yum -y install epel-release
    if [[ $os_version == "7" ]]; then
      yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    elif [[ $os_version == "8" ]]; then
      yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    fi
fi

### remove old packages ####
yum -y remove mariadb-libs
yum -y remove 'maria*'
yum -y remove mysql mysql-server mysql-libs mysql-common mysql-community-common mysql-community-libs
yum -y remove 'mysql*'
yum -y remove 'percona*'
yum -y remove 'Percona-*'
yum -y remove MariaDB-common MariaDB-compat
yum -y remove MariaDB-server MariaDB-client
yum -y remove percona-release

### clean yum cache ###
yum clean all

### monitoring pre-packages ####
yum -y install nload bmon iptraf glances nmap htop dstat sysstat socat

# dev tools
yum -y install screen yum-utils expect perl perl-DBI perl-IO-Socket-SSL perl-Digest-MD5 perl-TermReadKey  libev gcc zlib zlib-devel openssl openssl-devel python3 python3-pip python3-devel

# others pre-packages
yum -y install pigz zlib file sudo libaio rsync snappy net-tools wget

### clean yum cache ###
yum clean all

#### REPO MYSQL ######
if [[ $os_type == "rhel" ]]; then
  if [[ $os_version == "7" ]]; then
    if [ "$MYSQL_VERSION" == "80" ]; then
       yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
       if [ "$MYSQL_MINOR_VERSION" != "" ]; then
          MYSQL_INSTALL_VERSION=pdps-$MYSQL_MINOR_VERSION
          echo $MYSQL_INSTALL_VERSION
        else
          MYSQL_INSTALL_VERSION=ps80
          echo $MYSQL_INSTALL_VERSION
       fi
       percona-release setup -y $MYSQL_INSTALL_VERSION
       yum -y install percona-server-server percona-server-client percona-server-shared percona-server-shared-compat
     elif [[ "$MYSQL_VERSION" == "57" ]]; then
       yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
       percona-release setup -y ps57
       yum -y install Percona-Server-client-$MYSQL_VERSION
       yum -y install Percona-Server-devel-$MYSQL_VERSION
       yum -y install Percona-Server-server-$MYSQL_VERSION
       yum -y install Percona-Server-shared-$MYSQL_VERSION
       yum -y install Percona-Server-shared-compat-$MYSQL_VERSION
     elif [[ "$MYSQL_VERSION" == "56" ]]; then
       yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
       percona-release setup -y ps56
       yum -y install Percona-Server-client-$MYSQL_VERSION
       yum -y install Percona-Server-devel-$MYSQL_VERSION
       yum -y install Percona-Server-server-$MYSQL_VERSION
       yum -y install Percona-Server-shared-$MYSQL_VERSION
       yum -y install Percona-Server-shared-compat-$MYSQL_VERSION
    fi
  elif [[ $os_version == "8" ]]; then
    if [ "$MYSQL_VERSION" == "80" ]; then
       yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
       if [ "$MYSQL_MINOR_VERSION" != "" ]; then
          MYSQL_INSTALL_VERSION=pdps-$MYSQL_MINOR_VERSION
          echo $MYSQL_INSTALL_VERSION
          percona-release setup -y $MYSQL_INSTALL_VERSION
          PERCONA_REPO="percona-pdps-$MYSQL_INSTALL_VERSION-release.repo"
          sed -ie 's/enabled=1/enabled=1\nmodule_hotfixes=1/g' /etc/yum.repos.d/$PERCONA_REPO
          sed -ie 's/enabled = 1/enabled=1\nmodule_hotfixes=1/g' /etc/yum.repos.d/$PERCONA_REPO
        else
          MYSQL_INSTALL_VERSION=ps80
          echo $MYSQL_INSTALL_VERSION
          percona-release setup -y $MYSQL_INSTALL_VERSION
          sed -ie 's/enabled=1/enabled=1\nmodule_hotfixes=1/g' /etc/yum.repos.d/percona-ps-80-release.repo
          sed -ie 's/enabled = 1/enabled=1\nmodule_hotfixes=1/g' /etc/yum.repos.d/percona-ps-80-release.repo
       fi
       yum -y install percona-server-server percona-server-client percona-server-shared percona-server-shared-compat
     elif [[ "$MYSQL_VERSION" == "57" ]]; then
       yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
       percona-release setup -y ps57
       sed -ie 's/enabled=1/enabled=1\nmodule_hotfixes=1/g' /etc/yum.repos.d/percona-ps-57-release.repo
       sed -ie 's/enabled = 1/enabled=1\nmodule_hotfixes=1/g' /etc/yum.repos.d/percona-ps-57-release.repo
       yum -y install Percona-Server-client-$MYSQL_VERSION
       yum -y install Percona-Server-devel-$MYSQL_VERSION
       yum -y install Percona-Server-server-$MYSQL_VERSION
       yum -y install Percona-Server-shared-$MYSQL_VERSION
       yum -y install Percona-Server-shared-compat-$MYSQL_VERSION
     elif [[ "$MYSQL_VERSION" == "56" ]]; then
       error "Could not install MySQL 56 because it is not supported on RHEL/CentOS 8."
    fi
  fi
fi

### installation mysql add-ons via yum ####
yum -y install perl-DBD-MySQL
yum -y install jemalloc

####### PACKAGES ###########################
if [[ $os_type == "rhel" ]]; then
    if [[ $os_version == "7" ]]; then
      # -------------- For RHEL/CentOS 7 --------------
      #### mydumper ######
      yum -y install https://github.com/mydumper/mydumper/releases/download/v0.11.5-2/mydumper-0.11.5-2.el7.x86_64.rpm

      #### qpress #####
      #yum -y install https://github.com/emersongaudencio/linux_packages/raw/master/RPM/qpress-11-1.el7.x86_64.rpm
      yum -y install https://repo.percona.com/tools/yum/release/7/RPMS/x86_64/qpress-11-1.el7.x86_64.rpm
    elif [[ $os_version == "8" ]]; then
      #### mydumper ######
      yum -y install https://github.com/mydumper/mydumper/releases/download/v0.11.5-2/mydumper-0.11.5-2.el8.x86_64.rpm

      #### qpress #####
      #yum -y install https://github.com/emersongaudencio/linux_packages/raw/master/RPM/qpress-11-1.el8.x86_64.rpm
      yum -y install https://repo.percona.com/tools/yum/release/8/RPMS/x86_64/qpress-11-1.el8.x86_64.rpm
    fi
fi

### Percona #####
### https://www.percona.com/doc/percona-server/LATEST/installation/yum_repo.html
yum -y install percona-toolkit sysbench
if [ "$MYSQL_VERSION" == "80" ];
 then
   yum -y install percona-xtrabackup-80
else
   yum -y install percona-xtrabackup-24
fi

#####  MYSQL LIMITS ###########################
check_limits=$(cat /etc/security/limits.conf | grep '# mysql-pre-reqs' | wc -l)
if [ "$check_limits" == "0" ]; then
echo ' ' >> /etc/security/limits.conf
echo '# mysql-pre-reqs' >> /etc/security/limits.conf
echo 'mysql              soft    nproc   102400' >> /etc/security/limits.conf
echo 'mysql              hard    nproc   102400' >> /etc/security/limits.conf
echo 'mysql              soft    nofile  102400' >> /etc/security/limits.conf
echo 'mysql              hard    nofile  102400' >> /etc/security/limits.conf
echo 'mysql              soft    stack   102400' >> /etc/security/limits.conf
echo 'mysql              soft    core unlimited' >> /etc/security/limits.conf
echo 'mysql              hard    core unlimited' >> /etc/security/limits.conf
echo '# all_users' >> /etc/security/limits.conf
echo '* soft nofile 102400' >> /etc/security/limits.conf
echo '* hard nofile 102400' >> /etc/security/limits.conf
else
echo "MySQL Pre-reqs for /etc/security/limits.conf is already in place!"
fi

##### CONFIG PROFILE #############
check_profile=$(cat /etc/profile | grep '# mysql-pre-reqs' | wc -l)
if [ "$check_profile" == "0" ]; then
echo ' ' >> /etc/profile
echo '# mysql-pre-reqs' >> /etc/profile
echo 'if [ $USER = "mysql" ]; then' >> /etc/profile
echo '  if [ $SHELL = "/bin/bash" ]; then' >> /etc/profile
echo '    ulimit -u 65536 -n 65536' >> /etc/profile
echo '  else' >> /etc/profile
echo '    ulimit -u 65536 -n 65536' >> /etc/profile
echo '  fi' >> /etc/profile
echo 'fi' >> /etc/profile
else
echo "MySQL Pre-reqs for /etc/profile is already in place!"
fi

##### SYSCTL MYSQL ###########################
check_sysctl=$(cat /etc/sysctl.conf | grep '# mysql-pre-reqs' | wc -l)
if [ "$check_sysctl" == "0" ]; then
# insert parameters into /etc/sysctl.conf for incresing MySQL limits
echo "# mysql-pre-reqs
# virtual memory limits
vm.swappiness = 1
vm.dirty_background_ratio = 3
vm.dirty_ratio = 40
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
fs.suid_dumpable = 1
vm.nr_hugepages = 0
# file system limits
fs.aio-max-nr = 1048576
fs.file-max = 6815744
# kernel limits
kernel.panic_on_oops = 1
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
# kernel semaphores: semmsl, semmns, semopm, semmni
kernel.sem = 250 32000 100 128
# networking limits
net.ipv4.ip_local_port_range = 9000 65499
net.core.rmem_default=4194304
net.core.rmem_max=4194304
net.core.wmem_default=262144
net.core.wmem_max=1048586" >> /etc/sysctl.conf
else
echo "MySQL Pre-reqs for /etc/sysctl.conf is already in place!"
fi
# reload confs of /etc/sysctl.confs
sysctl -p

#####  MYSQL LIMITS ###########################
mkdir -p /etc/systemd/system/mysqld.service.d/
echo '[Service]' > /etc/systemd/system/mysqld.service.d/limits.conf
echo 'LimitNOFILE=102400' >> /etc/systemd/system/mysqld.service.d/limits.conf
echo '[Service]' > /etc/systemd/system/mysqld.service.d/timeout.conf
echo 'TimeoutSec=28800' >> /etc/systemd/system/mysqld.service.d/timeout.conf
systemctl daemon-reload

#####  MYSQL MEMORY ALLOCATOR ###########################
echo '[Service]' > /etc/systemd/system/mysqld.service.d/malloc.conf
echo 'ExecStartPre=/bin/sh -c "systemctl unset-environment LD_PRELOAD"' >> /etc/systemd/system/mysqld.service.d/malloc.conf
echo 'ExecStartPre=/bin/sh -c "systemctl set-environment LD_PRELOAD=/usr/lib64/libjemalloc.so.1"' >> /etc/systemd/system/mysqld.service.d/malloc.conf
systemctl daemon-reload

# disable transparent huge pages
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
  echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

echo "##############"
echo "END - [`date +%d/%m/%Y" "%H:%M:%S`]"
