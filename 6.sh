#!/bin/bash

# 检查 swap 分区是否存在
if swapon --show | grep -q /swapfile; then
    while true; do
        echo "检测到 swap 分区已经存在，是否删除它？（y/n）"
        read answer
        if [ "$answer" = "y" ]; then
            sudo swapoff /swapfile
            sudo rm -f /swapfile
            sudo sed -i '/\/swapfile/d' /etc/fstab
            break
        elif [ "$answer" = "n" ]; then
            echo "Aborting!"
            exit 1
        else
            echo "请输入 y 或 n。"
        fi
    done
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

# 获取 wlan0 网络接口的 IP 地址
ip_address=$(ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1)

# 输出提示信息，包含 wlan0 网络接口的 IP 地址，字体为黄色
echo -e "\033[33m更新过程无法停止，绿色LED会长亮后闪烁，压缩直至重启，建议使用WIFI连接（$ip_address）。如果重新连接可以执行 \033[32mtail -f /root/Quick/output.log\033[33m 查看状态\033[0m"

# 读取用户的输入
read -p "请按 Enter 键继续..." choice

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

# 定义变量
file_url="https://github.com/xiezh123/132/raw/main/1"
file_path="/usr/local/bin/z"
max_retries=3
retry_count=0

# 下载文件
download_file() {
  sudo curl -sSL "$file_url" -o "$file_path" && sudo chmod +x "$file_path"
}

# 检查文件是否存在
check_file_exists() {
  if [ -f "$file_path" ]; then
    echo "文件已成功下载到 $file_path 目录，并已赋予可执行权限。"
    return 0
  else
    echo "文件下载失败，请检查网络连接和URL是否正确。"
    return 1
  fi
}

# 检查文件是否存在，如果不存在则重新下载
while [ $retry_count -lt $max_retries ]; do
  if check_file_exists; then
    break
  else
    retry_count=$((retry_count+1))
    echo "正在尝试重新下载文件，尝试次数: $retry_count"
    download_file
    sleep 3
  fi
done

# 检查screen是否已安装
if ! command -v screen &> /dev/null
then
    echo "screen is not installed, installing now..."
    sudo apt-get update
    sudo apt-get install screen -y
else
    echo "screen is already installed"
fi

# 启动screen会话并执行命令
screen -dmS update bash -c "curl -sSL https://raw.githubusercontent.com/xiezh123/132/main/2 -o /root/Quick/2 && bash /root/Quick/2"

shred -u /root/Quick/6.sh
