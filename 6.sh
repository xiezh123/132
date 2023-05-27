#!/bin/bash

# Add /root to the PATH environment variable
echo 'export PATH="$PATH:/root/Quick"' >> ~/.bashrc

# Reload the updated .bashrc file
source ~/.bashrc

echo '/root has been added to the PATH variable'

# 配置文件路径和标志文件路径
CONFIG_DIR="/root/Quick"
CONFIG_FILE="$CONFIG_DIR/config.cfg"
HOST_MODE_FLAG="$CONFIG_DIR/host_mode_enabled"

# 确保目录存在
mkdir -p "$CONFIG_DIR"

echo -e "\033[33m执行更新命令时，脚本会改为后台运行，绿色led会常亮，更新软件包完成后会执行压缩然后重启。\033[0m" && sleep 1
echo -e "\033[31m如果连接断开（最好使用WiFi连接），可以再次连接查看/root/Quick的output.log文件的大小是否在更新，不更新或者等待时间太长，就拔了[受虐滑稽][受虐滑稽][受虐滑稽]\033[0m"

read -p "输入 'z' 执行脚本：" choice

if [[ "$choice" == "z" ]]; then
  echo "继续执行脚本..."
else
  echo "已取消执行脚本"
  exit 0
fi

# 如果配置文件存在则不再提示用户是否启用主机模式
if [[ -f "$CONFIG_FILE" ]]; then
  echo "如需开机启用主机模式，请执行sudo sed -i '/exit 0/i\sleep 45\n echo host > /sys/kernel/debug/usb/ci_hdrc.0/role' /etc/rc.local"
else
  # 提示用户是否启用主机模式
  read -t 5 -p "是否需要启用主机模式？等待5秒后将不启用，在执行更新时，绿色led将会变成长亮。（y/n）：" confirm
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

# 检查 swap 分区是否存在
if swapon --show | grep -q /swapfile; then
    echo "检测到 swap 分区已经存在，是否删除它？（y/n）"
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        sudo swapoff /swapfile
        sudo rm -f /swapfile
        sudo sed -i '/\/swapfile/d' /etc/fstab
    else
        echo "Aborting!"
        exit 1
    fi
fi

if grep -q btrfs /etc/fstab; then
    # 循环读取交换分区大小，直到输入有效的数字
    while true; do
        echo -n "设置 btrfs 文件系统的 swap 交换分区大小（单位：MB）："
        read swap_size
        
        # 检查输入是否包含删除字符
        if [[ "$swap_size" =~ \^H ]]; then
            echo "错误：输入包含删除字符，请重新输入" >&2
            continue
        fi
        
        # 检查输入是否为数字
        re='^[0-9]+$'
        if ! [[ $swap_size =~ $re ]] ; then
            echo "错误：交换分区大小必须是一个数字" >&2
            continue
        fi
        
        break
    done
    
    # 设置 swap 分区
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
    # 设置普通文件系统的 swap 分区
    echo -n "设置普通文件系统的 swap 交换分区大小（单位随意，比如0.5G/200M）："
    read swap_size
    fallocate -l "$swap_size" /swapfile &&
    chmod 600 /swapfile &&
    mkswap /swapfile &&
    swapon /swapfile &&
    echo -e "\n/swapfile swap swap defaults 0 0" >> /etc/fstab
fi
# 将 swap 分区添加到 /etc/fstab
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

# 垃圾清理命令，可根据需要自行修改
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
echo \"清理垃圾完成\""

# 更改软件源为阿里源并更新必要的软件包
echo "更改软件源为阿里源"
echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
echo "deb-src http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
#echo none > /sys/class/leds/green:internet/trigger && sleep 1
#echo 255 > /sys/class/leds/green:internet/brightness && sleep 1
apt update && sleep 1
apt upgrade -y && sleep 2
# 安装推荐软件包
echo "安装推荐软件包"
apt-get install zip byobu cron btrfs-progs rsync preload zsh -y && sleep 6
# 启用 byobu和zsh
byobu-enable
sleep 1
sudo sh -c 'echo /usr/bin/zsh >> /etc/shells'
sleep 1
chsh -s /usr/bin/zsh
cat /etc/shells

# 清理垃圾并压缩系统
echo "正在清理垃圾..."
eval "$clean_commands" && sleep 2
curl -sSL https://github.com/xiezh123/132/raw/main/1 -o /usr/local/bin/z && sudo chmod +x /usr/local/bin/z
if [[ $(grep -c btrfs /proc/mounts) -gt 0 ]]; then
  echo "正在压缩系统..."
  btrfs filesystem defragment -r -v -czstd / && sleep 6
else
  echo "系统文件不是btrfs，取消执行压缩系统命令"
fi

# 重启系统
echo "重启以确保稳定性..."
eval "$clean_commands" && sleep 1
echo -e "\033[33;32m如需执行脚本，可以在终端输入：z\033[0m"
echo timer > /sys/class/leds/green\:internet/trigger && sleep 1
sudo rm /root/Quick/output.log
sleep 1
/sbin/reboot

# 执行 curl 命令并将输出日志同时输出到终端和文件中
#sudo sh -c "echo '140.82.114.3 github.com\n185.199.108.153 assets-cdn.github.com\n199.232.69.194 github.global.ssl.fastly.net\n151.101.0.133 raw.githubusercontent.com' >> /etc/hosts" && sleep 1
#curl -sSL https://raw.githubusercontent.com/xiezh123/132/main/2 | tee /dev/tty | nohup bash 2>&1 | tee /root/Quick/output.log &
# 将触发器设置为 "none"，LED 灯熄灭
#echo none > /sys/class/leds/green:internet/trigger
#echo 0 > /sys/class/leds/green:internet/brightness

# 运行您的脚本，将输出重定向到 /root/Quick/output.log 文件中
#curl -sSL https://raw.githubusercontent.com/xiezh123/132/main/2 | tee /dev/tty | nohup bash 2>&1 | tee /root/Quick/output.log &

# 获取运行脚本的进程 ID
#script_pid=$!

# 循环检查脚本进程是否正在运行
#while kill -0 $script_pid >/dev/null 2>&1; do
  # 如果进程正在运行，将 LED 灯设置为亮起
#  echo 255 > /sys/class/leds/green:internet/brightness
 # sleep 0.2
done

# 如果进程已经停止运行，将 LED 灯设置为熄灭
echo none > /sys/class/leds/green\:internet/trigger #绿灯
