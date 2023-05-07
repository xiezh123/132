#!/bin/bash

echo "请选择要执行的操作："
echo "1. 初始设置"
echo "2. 安装工具"
echo "3. 其他命令"
echo "4. 快捷命令"
echo "   a. 关闭LED"
echo "   b. 清理垃圾&压缩系统"
echo "   c. 查看网络信息"
echo "   d. 查看系统状态"

clean_commands="apt-get clean
journalctl --vacuum-size=5M
echo > /var/log/syslog
echo > /var/log/syslog.1
echo > /var/log/mail.log.1
echo > /var/log/mail.info.1
echo > /var/log/mail.warn.1
echo > /var/log/mail.err.1
echo > /var/log/mail.log
echo > /var/log/mail.info
echo > /var/log/mail.warn
echo > /var/log/mail.err
echo "清理垃圾完成""

read -p "请输入选项（1、2、3、4a、4b、4c、4d）：" option

if [ "$option" == "1" ]; then
  CONFIG_DIR="/path/to"
CONFIG_FILE="$CONFIG_DIR/config.cfg"
HOST_MODE_FLAG="$CONFIG_DIR/host_mode_enabled"

# 确保目录存在
mkdir -p "$CONFIG_DIR"

if [[ -f "$CONFIG_FILE" ]]; then
  echo "脚本已经被执行过，不再提示用户是否启用主机模式"
  else
  read -t 5 -p "是否需要启用主机模式？按回车键确认启用，否则等待5秒后将不启用。（y/n）：" confirm
  if [ "$confirm" == "y" ]; then
    echo "正在添加主机模式..."
    sudo sed -i '/exit 0/i\sleep 45\n echo host > /sys/kernel/debug/usb/ci_hdrc.0/role' /etc/rc.local
    echo "主机模式将在开机后的45秒后启用"
    touch "$HOST_MODE_FLAG"
  else
    echo "未启用主机模式"
  fi
  touch "$CONFIG_FILE"
  fi
  if grep -qs '/swapfile' /etc/fstab; then
    echo "检测到 swapfile 文件已经存在，是否删除它？(y or n)"
    read -r answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        echo "删除 swapfile 文件"
        sudo swapoff /swapfile
        sudo rm -f /swapfile
        sudo sed -i '/\/swapfile/d' /etc/fstab
    else
        echo "Aborting!"
        exit 1
    fi
  fi

  if ! grep -qs '^/swapfile swap swap defaults 0 0' /etc/fstab; then
    echo "设置 swap 分区"
    if grep -q btrfs /etc/fstab; then
      echo -n "设置btrfs文件系统的swap交换分区大小（单位：MB):"
      read swap_size
      sudo truncate -s 0 /swapfile &&
      sudo chattr +C /swapfile &&
      sudo btrfs property set /swapfile compression none &&
      dd if=/dev/zero of=/swapfile bs=1M count="$swap_size" &&
      sleep 2 &&
      chmod 600 /swapfile &&
      mkswap /swapfile &&
      swapon /swapfile &&
      echo -e "LABEL=arch64 / btrfs defaults,noatime,compress=zstd:15,commit=30 0 0\n/swapfile swap swap defaults 0 0" >> /etc/fstab
    else
      echo -n "设置普通文件系统的swap交换分区大小（单位随意，比如0.5G/200M）:"
      read swap_size
      fallocate -l "$swap_size" /swapfile &&
      chmod 600 /swapfile &&
      mkswap /swapfile &&
      swapon /swapfile &&
      echo -e "\n/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi
  else
    echo "已存在设置 swap 分区的项在 /etc/fstab 中，将不再执行设置命令"
  fi

  if ! grep -qs '/swapfile' /etc/fstab; then
    echo "将 swap 分区添加到 /etc/fstab"
    if grep -q btrfs /etc/fstab; then
      echo -e "/swapfile swap swap defaults 0 0" >> /etc/fstab
    else
      echo -e "\n/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi
  else
    echo "已存在 swap 分区的项在 /etc/fstab 中，将不再执行添加命令"
  fi

  read -t 5 -n 1 -p "是否确认更改软件源为阿里源并更新必要的软件包？（5s后自动确认,或输入N停止）："
  echo ""
  if [[ $REPLY == "" || $REPLY == "y" ]]; then
    echo "更改软件源为阿里源"
    echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list
    echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
    echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
    apt update && sleep 1
    apt upgrade -y && sleep 2
    read -t 5 -n 1 -e -p "是否确认推荐软件包？zip、byobu、cron、btrfs-progs等（默认为y，输入n安装）：" confirm_install
    if [[ -z $confirm_install ]]; then
      confirm_install="y"
    fi

    if [[ $confirm_install == "y" ]]; then
      echo "安装zip、byobu、cron、btrfs-progs等软件包"
      apt-get install zip byobu cron btrfs-progs && sleep 6
      byobu-enable
    else
      echo "操作已取消"
    fi

    read -t 10 -n 1 -p "系统需要重启以确保稳定性，10秒后系统将在清理垃圾和压缩系统之后重启，按任意键取消操作：" prompt
    if [[ -z $prompt ]]; then
      echo "正在清理垃圾..."
      eval "$clean_commands" && sleep 2
      if [[ $(grep -c btrfs /proc/mounts) -gt 0 ]]; then
        echo "正在压缩系统..."
        btrfs filesystem defragment -r -v -czstd / && sleep 6
      else
        echo "系统文件不是btrfs，取消执行压缩系统命令"
      fi
      echo "正在重启..."
      sleep 1
      /sbin/reboot
    else
      echo "已取消"
    fi
  fi
elif [ "$option" == "2" ]; then
  echo "请选择要执行的操作："
  echo "a. 安装Docker"
  echo "b. 安装青龙面板"
  echo "c. 安装1Panel面板"
  echo "d. 安装宝塔开心版"
  echo "e. 安装Aria2"
  echo "f. 安装Alist网盘"
  echo "g. 安装CasaOS个人云"
  echo "h. 安装qiandao"
  echo "i. 安装网易云音乐解灰代理服务"
  read -p "请输入字母选项：" install_option

  if [ "$install_option" == "a" ]; then
    echo "请选择使用的镜像源："
    echo "1. 使用Docker官方源"
    echo "2. 使用阿里云镜像源"
    echo "3. 使用DaoCloud镜像源"
    echo "4. 删除Docker及其相关文件和设置"
    read -p "请输入选项（1、2、3、4）：" option
    if [ "$option" == "1" ]; then
    echo "从Docker官方安装Docker"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    elif [ "$option" == "2" ]; then
      echo "从阿里云安装Docker"
      curl -fsSL https://get.docker.com | sed 's/docker-ce/docker-ce -o debuntu/g' - | CHANNEL=stable bash
    elif [ "$option" == "3" ]; then
      echo "从DaoCloud安装Docker"
      curl -sSL https://get.daocloud.io/docker | sh
    elif [ "$option" == "4" ]; then
      echo "确认删除 Docker 及其相关文件和设置"
      sudo systemctl stop docker && sudo apt-get purge docker-ce docker-ce-cli containerd.io && sudo rm -rf /var/lib/docker /etc/docker && sudo groupdel docker && sudo userdel -r docker && sudo rm -rf /etc/systemd/system/docker.service.d /etc/systemd/system/containerd.service.d /lib/systemd/system/docker.service /lib/systemd/system/containerd.service
    echo "Docker 已被完全删除"
    else
      echo "无效的选项"
      exit 1
    fi

    echo "启用 Docker 服务..."
    sudo systemctl enable docker
    echo "启动 Docker 服务..."
    sudo systemctl start docker
  elif [ "$install_option" == "b" ]; then
    echo "请选择您要安装的版本："
    echo "1. 安装 Debian 版本"
    echo "2. 安装正式版"
    echo "3. 安装 2.10.13 稳定版"
    echo "4. 进入容器"
    read panel_option

    if [ "$panel_option" == "1" ]; then
        echo "安装 Debian 版本..."
        ## 执行安装命令
        docker run -dit \
        -v $PWD/ql:/ql/data \
        -p 5700:5700 \
        --name qinglong \
        --hostname qinglong \
        --restart always \
        whyour/qinglong:debia
    elif [ "$panel_option" == "2" ]; then
        echo "安装正式版..."
        ## 执行安装命令
        docker run -dit \
        -v $PWD/ql:/ql/data \
        -p 5700:5700 \
        --name qinglong \
        --hostname qinglong \
        --restart always \
        whyour/qinglong:latest
    elif [ "$panel_option" == "3" ]; then
        echo "安装 2.10.13 稳定版..."
        ## 执行安装命令
        docker run -dit \
        -v /root/ql/config:/ql/config \
        -v /root/ql/log:/ql/log \
        -v /root/ql/db:/ql/db \
        -v /root/ql/scripts:/ql/scripts \
        -v /root/ql/jbot:/ql/jbot \
        -v /root/ql/repo:/ql/repo \
        -v /root/ql/ninja:/ql/ninja \
        -v /root/ql/raw:/ql/raw \
        -p 5960:5700 \
        -p 5701:5701 \
        -e ENABLE_HANGUP=true \
        -e ENABLE_WEB_PANEL=true \
        --name ql \
        --hostname ql \
        --privileged=true \
        --restart always \
        whyour/qinglong:2.10.13
    elif [ "$panel_option" == "4" ]; then
        echo "进入容器，按住 Ctrl 和 PQ 退出容器"
        docker exec -it qinglong /bin/bash
    else
        echo "无效的选项，退出脚本"
    fi
  elif [ "$install_option" == "c" ]; then
    echo "安装1Panel面板"
    curl -fsSL https://onepanel.fit/install.sh | bash
  elif [ "$install_option" == "d" ]; then
    echo "安装宝塔开心版，安装完成后终端执行<bt>自行更改"
    wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh
  elif [ "$install_option" == "e" ]; then
    echo "安装Aria2"
    apt-get update
    apt-get install -y aria2
  elif [ "$install_option" == "f" ]; then
    echo "安装Alist网盘,IP:5244,帐密请查看输出内容"
    curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install
  elif [ "$install_option" == "g" ]; then
    echo "安装CasaOS个人云,IP"
    curl -fsSL https://get.casaos.io | sudo bash
  elif [ "$install_option" == "h" ]; then
    echo "安装qiandao,IP:8923"
    docker run --restart=always -d --name qiandao -p 8923:80 -v $(pwd)/qiandao/config:/usr/src/app/config a76yyyy/qiandao:lite-latest
  elif [ "$install_option" == "i" ]; then
    echo "安装网易云音乐解灰,代理端口6666"
    # athr=nondanee && img=unblockneteasemusic && \
    athr=pan93412 && img=unblock-netease-music-enhanced && \
    docker rm -f $img 2>/dev/null || true && \
    docker rmi -f $athr/$img 2>/dev/null || true && \
    docker run -d \
    --name $img \
    --restart always \
    -p 6666:8080 \
    $athr/$img \
    -p 8080:8081 \
    -s -e https://music.163.com -f 59.111.19.33 \
    -o kuwo qq

  else
    echo "选项不存在"
  fi
elif [ "$option" == "3" ]; then
  echo "请选择要执行的操作："
  echo "a. 检查并修复软件包"
  echo "b. 关机"
  echo "c. 禁用系统日志"
  echo "d. 深度清理文件"
  echo "e. 添加主机模式"
  read -p "请输入选项（a、b、c、d、e）：" check_option

  if [ "$check_option" == "a" ]; then
    echo "正在检查并修复软件包..."
    echo -e '\xE2\xA0\x84\xE2\xA0\x84\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA0\x98\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xA7\xE2\xA3\x9B\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA0\xA4\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBD\xE2\xA1\x86\xE2\xA0\x84\xE2\xA0\x84'
    apt-get check && apt-get -f install
  elif [ "$check_option" == "b" ]; then
    echo "正在关机..."
    sudo shutdown -h now
  elif [ "$check_option" == "c" ]; then
    echo "正在清空系统日志..."
    sudo systemctl stop rsyslog && sudo systemctl disable rsyslog && sudo systemctl stop systemd-journald && sudo systemctl disable systemd-journald && sudo cat /dev/null > /var/log/syslog && sudo cat /dev/null > /var/log/messages && sudo cat /dev/null > /var/log/auth.log && sudo cat /dev/null > /var/log/user.log && sudo cat /dev/null > /var/log/kern.log && sudo cat /dev/null > /var/log/mysql/error.log && sudo find /var/log -type f -delete && sudo rm -rf /var/log/* && sudo rm -rf /tmp/* && sudo rm -rf /var/tmp/*
  elif [ "$check_option" == "d" ]; then
    read -p "警告：执行此操作可能会造成系统不稳定甚至崩溃，按回车键确认继续执行，出现英文提示时CTRL&C退出：" confirm
    if [ -z "$confirm" ]; then
      echo "正在深度清理文件..."
        if ! command -v bleachbit &> /dev/null
  then
      echo "Bleachbit not found. Installing..."
      sudo apt-get update && sudo apt-get install -y bleachbit
  fi

  echo "Cleaning system..."
  bleachbit --clean system.*
    else
      echo "已取消执行操作"
    fi
  elif [ "$check_option" == "e" ]; then
    read -p "警告：执行此操作将向 rc.local 文件添加一行命令，可能会影响系统稳定性。按回车键确认继续执行：" confirm
    if [ -z "$confirm" ]; then
      echo "正在添加主机模式..."
      sudo sed -i '/exit 0/i\sleep 45\necho host > /sys/kernel/debug/usb/ci_hdrc.0/role' /etc/rc.local
    else
      echo "已取消执行操作"
    fi
  else
    echo "选项不存在"
  fi
elif [[ "$option" == "4a" ]]; then 
  echo "关闭led"
  echo none > /sys/class/leds/red\:os/trigger #红灯
  echo none > /sys/class/leds/blue\:wifi/trigger #蓝灯
  echo none > /sys/class/leds/green\:internet/trigger #绿灯
elif [[ "$option" == "4b" ]]; then 
  echo "清理垃圾"
  eval "$clean_commands"

  ROOT_PARTITION=$(mount | grep "on / " | cut -d' ' -f1)
  if [ "$(lsblk -o FSTYPE "$ROOT_PARTITION" | tail -n1)" == "btrfs" ]; then 
    echo "根文件系统为 btrfs，执行相关操作"
    btrfs filesystem defragment -r -v -czstd /
  else 
    echo "根文件系统不是 btrfs，跳过相关操作"
  fi 
elif [[ "$option" == "4c" ]]; then 
  echo "查看网络信息"
  ping -c 4 google.com
  ip addr show
elif [[ "$option" == "4d" ]]; then 
  echo "查看系统状态"
  echo "系统详情：$(uname -a)"
  echo "CPU 信息：$(lscpu)"
  echo "内存占用情况：$(free -h)"
  echo "Swap 占用情况：$(swapon -s)"
  echo "磁盘挂载情况：$(lsblk)"
  echo "存储占用情况：$(df -h)"
else
  echo "选项不存在"
fi