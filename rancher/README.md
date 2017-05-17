
# Rancher测试集群

## 环境

  写文章时的环境:

    docker version is 1.12.5, build 7392c3b
    docker-machine version is 0.8.2, build e18a919
    VirtualBox from http://download.virtualbox.org/virtualbox/5.1.12/VirtualBox-5.1.12-112440-OSX.dmg
    Rancher-server 1.6.0

    Supported Docker Versions

    Docker 1.10.3
    Docker 1.12.3-1.12.6
    Docker 1.13.1 (Not supported with Kubernetes as Kubernetes does not support it yet)
    Docker 17.03.0-ce (Not supported with Kubernetes as Kubernetes does not support it yet)

## 集群部署

#### rancher-server启动

1. 启动rancher-server

        docker-compose pull 或 build
        docker-compose up -d

2. 配置server

    > 我们使用VirtualBox的虚机组成一个小集群,所以建议把Rancher的Host Registration URL设置为: http://192.168.99.1:18080

    - 配置Host Registration URL：Admin->Settings->Host Registration URL: http://192.168.99.1:18080
    - 配置Access Control: Admin->Access Control: 选择Local，输入用户名密码,Ex: admin/admin_pass
    - Env管理：(下面的添加Host，需要选定一个Env，这里使用了k8s，所以在添加k8s的env之后，再执行后面的添加host)

            Manage Environments->Environment-> Add Environment: Ex: k8s-env,管理上面新建的Templates

#### MAC下创建并启动host主机

        ./add_ros_host.sh ros-1
        docker-machine ls  # 查看虚拟机
        docker-machine ssh ros-1 # ssh登录
        sudo ros config set rancher.docker.extra_args "['--registry-mirror','http://hub-mirror.c.163.com','--insecure-registry','registry.docker.yixinonline.org']"
        sudo system-docker restart docker # 重启docker

        ./add_ros_host.sh ros-2
        docker-machine ls  # 查看虚拟机
        docker-machine ssh ros-2 # ssh登录
        sudo ros config set rancher.docker.extra_args "['--registry-mirror','http://hub-mirror.c.163.com','--insecure-registry','registry.docker.yixinonline.org']"
        sudo system-docker restart docker # 重启docker


#### 如果是物理机，可参照后文步骤先安装RancherOS系统。


#### 添加主机

 > 核对当前的Env是否是欲使用的env，这里使用k8s-env

  INFRASTRUCTURE->Hosts—> Add Host: 粘贴ros-1的ip地址（可使用`docker-machine ip ros-1`命令获取）,然后复制命令，进入虚机执行注册，Ex：
注意:
添加Rancher agent时, CATTLE_AGENT_IP 要设置成VirtualBox虚机内网段(192.168.99.0/24)的IP, 例如: 192.168.99.100,
     可使用`docker-machine ip ros-1`命令查看.
    docker-machine ssh ros-2 # ssh登录
    sudo docker run -e CATTLE_AGENT_IP="192.168.99.100"  -d --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.0 http://192.168.99.1:18080/v1/scripts/7D94D5BEE79836C361D4:1483142400000:0RcDhCR4Pv35AJUqCW9J1eLsvfc

### 参考文档

[构建支持多编排引擎的容器基础设施服务](https://www.sdk.cn/news/6292)

### 自定义Catalog

    fork https://github.com/rancher/rancher-catalog
    # 直接定制化插件的参数，或者自定义添加插件。
    # 完后再rancherUI添加catalog即可。
    # catalog相关参考 https://docs.rancher.com/rancher/v1.5/en/catalog/


### 制作Rancher OS启动U盘

On Mac:
Open the DiskUtility.app, and on your USB hard drive, unmount any of it's partitions. Do not eject the USB hard drive.
Right click on the hard drive in the DiskUtility and get it's Identifier from the Information tab.

    cp ${HOME}/.oss-cache/rancher/os/releases/download/v0.9.0/rancheros.iso ${HOME}/Desktop/ros-v090.iso
    sudo dd if=${HOME}/Desktop/ros-v090.iso of=/dev/<disk identifier>

### 安装Rancher OS到磁盘

准备数据盘, 使用FAT(MS-DOS)格式化

    docker pull rancher/os:v0.9.0
    #docker save rancher/os:v0.9.0 > ~/Desktop/ros-v090.tar
    docker tag rancher/os:v0.9.0 registry.docker.internal/rancheros:v0.9.0
    docker push registry.docker.internal/rancheros:v0.9.0

    touch ~/Desktop/ros-conf.yml
    echo -e "
    #hostname: ros-192-231
    ssh_authorized_keys:
    - $(cat ${HOME}/.ssh/internal-git.pub)
    rancher:
      docker:
        extra_args:
        - --insecure-registry
        - registry.docker.internal
        - --registry-mirror
        - http://hub-mirror.c.163.com
      network:
        dns:
          nameservers:
          - 10.141.7.50
          - 10.141.7.51
    #    interfaces:
    #      eth0:
    #        address: 10.106.192.231/24
    #        gateway: 10.106.192.1
    #        mtu: 1500
    #        dhcp: false
      system_docker:
        extra_args:
        - --insecure-registry
        - registry.docker.internal
        - --registry-mirror
        - http://hub-mirror.c.163.com
    " > ~/Desktop/ros-conf.yml

    sudo ros os list
    sudo ros service list

    sudo mkdir -p /mnt/sdc1
    sudo mount -t msdos /dev/sdc1 /mnt/sdc1
    cp /mnt/sdc1/ros-conf.yml ros-conf.yml
    cp /mnt/sdc1/ros-v090.tar ros-v090.tar
    sudo system-docker load < ros-v090.tar

    #sudo ros config set rancher.docker.extra_args "['--insecure-registry','registry.docker.internal','--registry-mirror','http://hub-mirror.c.163.com']"
    #sudo system-docker restart docker
    #sudo ros config set hostname ros-192-231
    #sudo ros config set rancher.network.dns.nameservers [10.141.7.50,10.141.7.51]
    #sudo ros config set rancher.network.interfaces.eth0.address 10.106.192.231/24
    #sudo ros config set rancher.network.interfaces.eth0.gateway 10.106.192.1
    #sudo ros config set rancher.network.interfaces.eth0.mtu 1500
    #sudo ros config set rancher.network.interfaces.eth0.dhcp false
    #sudo system-docker restart network
    #sudo ros config set rancher.system_docker.extra_args [--insecure-registry,registry.docker.internal,--registry-mirror,http://hub-mirror.c.163.com]

    #sudo ros install -c ros-conf.yml -d /dev/sda -i registry.docker.internal/rancheros:v0.9.0
    sudo ros install -c ros-conf.yml -d /dev/sda -i rancher/os:v0.9.0
