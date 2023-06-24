#!/bin/bash

if ! ls /boot/vmlinuz-5.15.0-jsbsbxjxh66+ &> /dev/null; then
    echo "脚本无法在此设备上运行"
    sudo rm /root/0
    exit 1
fi

echo "正在更改DNS服务器..."

# 将 wlan0 替换为你的网络接口名称，将 180.76.76.76 和 8.8.8.8 替换为你想要使用的DNS服务器的IP地址。
sudo sed -i 's/dns-nameservers.*/dns-nameservers 180.76.76.76 8.8.8.8/g' /etc/network/interfaces

echo "正在重启网络服务..."
sudo service networking restart

echo "DNS服务器更改成功。"

# 要添加到 hosts 文件中的 IP 地址和域名
ip_list="140.82.114.3 github.com\n185.199.108.153 assets-cdn.github.com\n199.232.69.194 github.global.ssl.fastly.net\n151.101.0.133 raw.githubusercontent.com\n140.82.121.3 http://github.com\n140.82.121.3 http://gist.github.com\n185.199.110.153 http://assets-cdn.github.com\n185.199.108.133 http://raw.githubusercontent.com\n185.199.111.133 http://gist.githubusercontent.com\n185.199.110.133 http://cloud.githubusercontent.com\n185.199.111.133 http://camo.githubusercontent.com\n185.199.111.133 http://avatars0.githubusercontent.com\n185.199.110.133 http://avatars1.githubusercontent.com\n185.199.111.133 http://avatars2.githubusercontent.com\n185.199.109.133 http://avatars3.githubusercontent.com\n185.199.108.133 http://avatars4.githubusercontent.com\n185.199.111.133 http://avatars5.githubusercontent.com\n185.199.109.133 http://avatars6.githubusercontent.com\n185.199.109.133 http://avatars7.githubusercontent.com\n185.199.110.133 http://avatars8.githubusercontent.com\n185.199.108.133 http://avatars.githubusercontent.com\n185.199.111.154 http://github.githubassets.com\n185.199.109.133 http://user-images.githubusercontent.com\n140.82.112.9 http://codeload.github.com\n185.199.110.133 http://favicons.githubusercontent.com\n192.30.255.116 http://api.github.com"

# Add /root to the PATH environment variable
echo 'export PATH="$PATH:/root"' >> ~/.bashrc

# Reload the updated .bashrc file
source ~/.bashrc

echo '/root has been added to the PATH variable'

# 配置文件路径和标志文件路径
CONFIG_DIR="/home"
CONFIG_FILE="$CONFIG_DIR/鸡你太美"
HOST_MODE_FLAG="$CONFIG_DIR/host_mode_enabled"

curl_command="curl -sSL https://github.com/xiezh123/132/raw/main/1 -o /usr/local/bin/z && sudo chmod +x /usr/local/bin/z"

# 检查鸡你太美文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
  # 如果鸡你太美文件不存在，则向 hosts 文件添加 IP 地址和域名
  if grep -q "$ip_list" /etc/hosts; then
    echo "hosts 文件中已经包含要添加的 IP 地址和域名。"
  else
    # 将 IP 地址和域名添加到 hosts 文件中
    if sudo sh -c "echo '$ip_list' >> /etc/hosts"; then
      echo "IP 地址和域名...已经成功添加到 hosts 文件中。"
      ip_address=$(ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1)
      echo -e "\033[33m更新大小1G+，操作不可逆，绿色LED会长亮后闪烁，尝试安装Docker后压缩直至重启，重启后LED会恢复为默认状态\033[0m"
      echo -e "\e[33m如需恢复备份文件请在安装Docker之前将docker.tar(xz)文件上传完成\e[0m"
      echo -e "\033[31m如果无法连接且红灯长时间不闪烁就拔了重新尝试，建议使用WIFI连接 IP：\033[32m$ip_address  \033[0m\033[31m。\033[31m更过程中断开连接可以输入 \033[32m x \033[31m 返回会话\033[0m"
    else
      echo "添加 IP 地址和域名到 hosts 文件失败。"
    fi
  fi

  # 创建鸡你太美文件
  if touch "$CONFIG_FILE"; then
    echo "哥哥下蛋了"
  else
    echo "哥哥卡jj了"
  fi
else
  echo -e "\033[33m脚本已经执行过了，再次执行可能会出现问题\033[0m"
fi

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

#删除zram0
sudo swapoff /dev/zram0 &&
sudo zramctl -r /dev/zram0

# 获取当前swap分区的大小，单位为MB
current_swap=$(sudo swapon --show | awk '/\/dev\/zram/ {print $3}' | sed 's/M//')

# 如果当前swap分区大小为空，则设置为0
if [ -z "$current_swap" ]; then
    current_swap=0
fi

# 获取当前可用内存的大小，单位为MB
mem=$(awk '/MemAvailable:/ {print int($2/1024)}' /proc/meminfo)

# 获取当前总内存的大小，单位为GB或MB
total_mem=$(free -h | awk '/^Mem:/ {print $2}')

# 计算建议的swap大小，单位为MB
if [ "$current_swap" != "0" ]; then
    swap=$(echo "($mem * 1.5 + $current_swap)/1" | bc)
else
    swap=$(echo "($mem * 1.5 + 424.5)/1" | bc)
fi

# 对建议的swap大小进行四舍五入，并将结果转换为整数
swap=$(printf "%.0f" "$swap")

# 如果当前swap分区的大小小于建议的大小，则提示需要设置更大的swap分区
if [ "$current_swap" -lt "$swap" ]; then
    echo "如果运行的服务较多推荐设置在$swap MB左右。"
fi

# 如果当前可用内存的大小小于建议的大小，则提示需要添加更多的内存
if [ "$mem" -lt "$swap" ]; then
    add_mem=$((swap - mem))
    echo "当前可用内存大小为$mem MB，轻量使用建议添加$add_mem MB的内存以达到最佳能效。"
fi

if grep -q btrfs /etc/fstab; then
    # 循环读取交换分区大小，直到输入有效的数字
    while true; do
        echo -ne "\e[33m设置 btrfs 文件系统的交换分区大小（另一半为zram0，单位：MB）：\e[0m"
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
    SIZE=$((swap_size/2))
    export zram="$SIZE"
    SIZE1="${SIZE}M"
    sudo truncate -s 0 /swapfile &&
    sudo chattr +C /swapfile &&
    sudo btrfs property set /swapfile compression none &&
    dd if=/dev/zero of=/swapfile bs=1M count="$SIZE" &&
    sleep 2 &&
    chmod 600 /swapfile &&
    mkswap /swapfile &&
    modprobe zram
    zram_dev=$(zramctl --find --size $SIZE1)
    mkswap $zram_dev
    swapon $zram_dev
    swapon /swapfile &&
    sudo rm /etc/fstab &&
    sudo touch /etc/fstab &&
    sudo chmod 644 /etc/fstab &&
    echo -e "LABEL=arch64 / btrfs defaults,noatime,compress=zstd:15,commit=30 0 0" | sudo tee -a /etc/fstab
else
    # 读取用户输入的交换分区大小
    echo -n "设置普通文件系统的交换分区大小（zram重启后启用，需要输入整数，比如输入 1234 为1.2G）："
    read swap_size
    
    # 根据用户输入的数字动态选择单位并计算交换分区大小
    if [[ $swap_size -ge 1000 ]]; then
        SIZE2=$(($swap_size/2/1024))"G"
    elif (( $(echo "$swap_size > 1" | bc -l) )); then
        SIZE2=$(($swap_size/2))"M"
    else
        SIZE2=$(echo "$swap_size/1000" | bc -l)"G"
    fi

    # 创建交换分区并设置为自动启用
    fallocate -l "$SIZE2" /swapfile &&
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

echo '#!/bin/bash

# 关闭 zram0 交换分区
sudo swapoff /dev/zram0
sudo zramctl -r /dev/zram0

# 加载 zram 模块
sudo modprobe zram

# 获取 /swapfile 文件的大小
swapfile_size=$(sudo du -h /swapfile | awk '\''{print $1}'\'')

# 创建新的 zram0 交换分区
zram_dev=$(sudo zramctl --find --size $swapfile_size)
sudo mkswap $zram_dev
sudo swapon $zram_dev' > zram.sh

echo '#脚本
# 压缩算法，效果: zstd > lzo > lz4，速度: lz4 > zstd > lzo，默认lz4
ALGO=zstd

#由于自定义了zram，此项作废
PERCENT=10
#SIZE=256

#交换分区优先级
PRIORITY=300' > zramswap

echo '#!/bin/bash

# 定义恢复备份文件的函数
function delete_backup_files {
  local backup_dir=$1

  # 提示用户是否删除文件
  echo "您是否要删除备份文件？（按下回车键删除，否则跳过）"
  read -t 6 -n 1 response

  # 检查用户的响应
  if [ "$response" == "" ]; then
    # 如果用户按下回车键，则删除文件
    sudo rm -f $backup_dir/docker.tar $backup_dir/docker.tar.xz
    echo "文件已成功删除。"
  else
    # 如果用户没有按下回车键，则跳过删除操作
    echo "文件未被删除。"
  fi
  
  target_dir="/root/青龙脚本"
  source_dir="/srv/ql/scripts"
  
  if [ ! -L "$target_dir" ]; then
    echo "软链接不存在，正在创建..."
    ln -s "$source_dir" "$target_dir"
    echo "已创建"
  else
    echo "软链接已存在"
  fi

  #提示
  sudo systemctl start docker
  echo "容器在恢复过程中可能会轻微卡顿"
  sleep 10
  top
}

# 询问用户备份/恢复操作
echo "请选择您要进行的操作:"
echo "1. 备份 /var/lib/docker 和 /srv 目录"
echo "2. 恢复 /var/lib/docker 和 /srv 目录"
read -p "请输入操作编号(1/2): " action

# 备份操作
if [ "$action" == "1" ]; then
    # 询问用户要备份到哪个目录
    read -p "请输入保存备份文件的路径: " backup_dir

    while [ ! -d "$backup_dir" ]; do
      echo "路径不存在或不是目录，请重新输入。"
      read -p "请输入保存备份文件的路径: " backup_dir
    done

    # 如果备份目录不存在，则创建目录
    sudo mkdir -p "$backup_dir"
    echo "正在停止docker容器"
    sudo docker stop $(sudo docker ps -aq)
    sudo systemctl stop docker

    # 检查 /var/lib/docker 和 /srv 目录是否都存在
    if [[ -d /var/lib/docker ]] && [[ -d /srv ]]; then
        # 询问用户要使用哪种压缩方法
        read -p "请选择压缩方法 (gz/xz): " compression_method

        # 根据用户选择的压缩方法进行备份
        if [ "$compression_method" == "gz" ]; then
            # 使用 tar 命令将 /var/lib/docker 和 /srv 目录压缩为 tar 格式的文件，并使用 pv 命令显示进度
            backup_file="$backup_dir/docker.tar"
            sudo tar -czf - /var/lib/docker /srv | pv -q -L 10M | sudo dd of="$backup_file" status=progress
            echo "已备份 /var/lib/docker 和 /srv 目录到 $backup_file 中"

        elif [ "$compression_method" == "xz" ]; then
            # 使用 tar 和 xz 命令将 /var/lib/docker 和 /srv 目录压缩为 tar.xz 格式的文件，并使用 pv 命令显示进度
            backup_file="$backup_dir/docker.tar.xz"
            sudo tar -cJf - -C /var/lib "$(basename /var/lib/docker)" -C / srv | pv -q -L 10M | sudo dd of="$backup_file" status=progress
            echo "已备份 /var/lib/docker 和 /srv 目录到 $backup_file 中"

        else
            # 如果用户输入了无效的压缩方法，则提示错误信息
            echo "无效的压缩方法"
        fi

        echo "启动 Docker中"
        sudo systemctl start docker

    else
        echo "/var/lib/docker 或 /srv 目录不存在"
    fi

# 恢复操作
elif [ "$action" == "2" ]; then
    # 询问用户从哪个备份目录中恢复
    read -p "请输入包含备份文件的路径: " backup_dir

    while [ ! -d "$backup_dir" ]; do
      echo "路径不存在或不是目录，请重新输入。"
      read -p "请输入保存备份文件的路径: " backup_dir
    done

    # 检查备份目录中是否存在 docker.tar 或 docker.tar.xz 文件
    if [[ -f "$backup_dir/docker.tar" ]] || [[ -f "$backup_dir/docker.tar.xz" ]]; then
        # 停止 Docker
        echo "停止docker中"
        sudo systemctl stop docker

        # 解压缩 /var/lib/docker 目录，并使用 pv 命令显示进度
        if [[ -f "$backup_dir/docker.tar" ]]; then
            echo "正在恢复 /var/lib/docker 目录..."
            sudo dd if="$backup_dir/docker.tar" status=progress | pv -q -L 10M | sudo tar -zxvf - -C /
        elif [[ -f "$backup_dir/docker.tar.xz" ]]; then
            echo "正在恢复 /var/lib/docker 目录..."
            sudo dd if="$backup_dir/docker.tar.xz" status=progress | pv -q -L 10M | sudo tar -xJf - -C /
        fi

        echo "已恢复 /var/lib/docker 目录"
        # 询问用户是否删除备份文件
        delete_backup_files $backup_dir
        
    else
        echo "$backup_dir/docker.tar 或 $backup_dir/docker.tar.xz 文件不存在"
    fi

# 无效操作
else
    echo "无效的操作编号"
fi

' > /usr/local/bin/b

chmod +x /usr/local/bin/b

#移动到/etc/default并且启用自启服务
sudo cp /etc/default/zramswap /etc/default/zramswap.bak
sudo rm -f /etc/default/zramswap
sudo mv zram.sh /etc/default/zram.sh
sudo mv zramswap /etc/default/zramswap
sudo chmod +x /etc/default/zramswap
sudo chmod +x /etc/default/zram.sh
sudo mkdir /etc/dconf/jntm

echo '[Unit]
Description=Setup Zram swap
After=local-fs.target

[Service]
ExecStartPre=/bin/sleep 45
ExecStart=/etc/default/zram.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/zram.service

sudo systemctl daemon-reload

sudo systemctl enable zram.service

#sudo systemctl status zram.service  # 查看服务状态

# 检查/etc/fstab文件中是否有包含关键字btrfs的行，创建低内存自动压缩服务
#if grep -q 'btrfs' /etc/fstab; then
  # 如果是Btrfs文件系统，则创建systemd服务
#  echo '[Unit]
#  Description=Defragment root btrfs filesystem when memory low
#  After=local-fs.target

#  [Service]
#  Type=oneshot
#  ExecStart=/bin/bash -c "free | awk '\''/^Mem/ {exit ($7>800000)}'\''; if [ $? -eq 1 ]; then /usr/bin/screen -dmS btrfs bash -c '\''btrfs filesystem defragment -r -v -czstd /'\''; fi"
#  User=root

#  [Install]
#  WantedBy=multi-user.target' | sudo tee /etc/systemd/system/btrfs-defragment.service > /dev/null

  # 启用和启动服务
#  sudo systemctl enable btrfs-defragment.service
#  sudo systemctl start btrfs-defragment.service
#else
  # 如果不是Btrfs文件系统，则输出一条错误信息
#  echo "不是Btrfs文件系统，跳过添加"
#fi

# 创建标志服务文件
cat << EOF > /etc/systemd/system/check_dconf.service
[Unit]
Description=Check dconf for jntm and led

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if [ ! -d "/etc/dconf/jntm" ]; then mkdir /etc/dconf/jntm; fi; cd /etc/dconf/jntm; if [ ! -f "led" ]; then echo "删除或者更改会使led失控" > led; else led_content="$(cat led)"; if [ "$led_content" != "删除或者更改会使led失控" ]; then rm led; echo "删除或者更改会使led失控" > led; fi; fi'

[Install]
WantedBy=multi-user.target
EOF

# 重新加载Systemd服务
systemctl daemon-reload

# 启用服务
systemctl enable check_dconf.service

echo '#!/bin/bash

# 定义LED控制函数
led_control() {

  sudo sh -c "echo phy0tx > /sys/class/leds/blue\:wifi/trigger && echo mmc0 > /sys/class/leds/mmc0\:\:/trigger"
  
  echo 255 > /sys/class/leds/green:internet/brightness
  
  sleep 3

  echo 0 > /sys/class/leds/green:internet/brightness

  sleep 2
  
  # 获取温度值
  temp=$(cat /sys/class/thermal/thermal_zone0/temp)
  
  # 取头值
  head=${temp:0:1}
  
  # 如果第二位大于5，则头值加1
  if [ ${temp:1:1} -ge 5 ]; then
    head=$((head+1))
  fi
  
  # 计算循环次数和间隔时间
  count=$head
  interval=$((15/(count*2)))
  
  # 循环执行命令
  for ((i=1; i<=$count; i++)); do
    echo 255 > /sys/class/leds/green:internet/brightness
    sleep $interval
    echo 0 > /sys/class/leds/green:internet/brightness
    sleep $interval
  done
  
  # 关闭亮灯
  echo 0 > /sys/class/leds/green:internet/brightness
}

#检查
check_led_trigger() {
  # 检查文件内容是否为"no"
  if grep -q "no" "/etc/dconf/jntm/led"; then
      echo "文件已经包含\"no\"，停止代码继续运行"
      exit 1
  fi
  
  echo "绿色 LED 触发器状态不为 none，开始执行 led_control 命令..."
  led_control
  echo "led_control 命令执行完毕。"
  exit 0
}

#检查wifi
check_led_nowifi() {
  # 检查文件内容是否为"no"
  if grep -q "no" "/etc/dconf/jntm/led"; then
      echo "文件已经包含\"no\"，停止代码继续运行"
      exit 1
  fi
  
  echo "绿色 LED 触发器状态不为 none，开始执行 led_control 命令..."
  sudo sh -c "echo timer > /sys/class/leds/blue\:wifi/trigger && echo 1500 > /sys/class/leds/blue\:wifi/delay_on && echo 1500 > /sys/class/leds/blue\:wifi/delay_off && echo 255 > /sys/class/leds/mmc0\:\:/brightness && echo timer > /sys/class/leds/green:internet/trigger && echo 1500 > /sys/class/leds/green\:internet/delay_on && echo 1500 > /sys/class/leds/green\:internet/delay_off"
  echo "led_control 命令执行完毕。"
  exit 0
}

#开关wifi
function wifi_reconnect {
    ping -c 3 www.baidu.com > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "WiFi连接已断开，正在尝试重新连接..."
        nmcli radio wifi off
        sleep 8
        nmcli radio wifi on
        sleep 8
        ping -c 3 www.baidu.com > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "WiFi重新连接成功。"
        else
            echo "WiFi重新连接失败。"
        fi
    fi
}

#写入日志
function write_wifi_log() {
    logfile="/etc/dconf/jntm/wifi.log"

    # 检查 log 文件所在的目录是否存在，如果不存在则创建
    logdir=$(dirname "${logfile}")
    if [ ! -d "${logdir}" ]; then
        mkdir -p "${logdir}"
    fi

    # 如果 log 文件不存在，创建一个空文件
    if [ ! -e "${logfile}" ]; then
        touch "${logfile}"
    fi

    # 读取文件中已有的行数
    line_count=$(wc -l < "${logfile}")

    # 如果文件为空，或者最后一行已经有 5 个 0，需要添加新的一行
    if [ $line_count -eq 0 ] || [ $(tail -n 1 "${logfile}" | tr -cd '0' | wc -m) -eq 5 ]; then
        echo "" >> "${logfile}"
    fi

    # 向 log 文件写入 0
    echo -n "0" >> "${logfile}"
}

#查询log
function check_wifi_log() {
    local logfile="/etc/dconf/jntm/wifi.log"

    # 检查 log 文件是否存在
    if [ -e "${logfile}" ]; then
        # 统计文件行数
        line_count=$(wc -l < "${logfile}")
        echo "文件 ${logfile} 有 ${line_count} 行"

        # 如果文件有 3 行，执行重启命令
        if [ ${line_count} -eq 3 ]; then
            sudo reboot
        fi

        # 如果文件行数超过 6，暂停系统运行
        if [ ${line_count} -gt 6 ]; then
            echo "文件行数超过 6，暂停系统运行"
            systemctl suspend
        fi
    else
        echo "文件 ${logfile} 不存在"
    fi
}

#删除wifilog
function remove_wifi_log() {
    logfile="/etc/dconf/jntm/wifi.log"

    # 检查 log 文件是否存在，如果存在则删除
    if [ -e "${logfile}" ]; then
        rm "${logfile}"
    fi
}

if [[ "$GREEN_TRIGGER" == "none" && "$BLUE_TRIGGER" == "none" ]]; then
    echo "LED触发器状态为none，不进行碎片整理操作。"
else
    if ping -c 1 www.baidu.com > /dev/null 2>&1; then
        echo "网络连接正常，重置指示灯"
        check_led_trigger
        remove_wifi_log
    else
        echo "没有网络连接，执行操作"
        write_wifi_log
        check_led_nowifi
        wifi_reconnect
        check_wifi_log
    fi
fi
' > /etc/dconf/jntm/LEDnetwork.sh

sudo chmod +x /etc/dconf/jntm/LEDnetwork.sh

# 创建服务文件
cat << EOF > /etc/systemd/system/led.service
[Unit]
Description=Check network for jntm and led

[Service]
Type=simple
ExecStartPre=/bin/sleep 30
ExecStart=/bin/bash /etc/dconf/jntm/LEDnetwork.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# 重新加载Systemd服务
systemctl daemon-reload

# 启用服务
sudo systemctl enable led.service

#备份sources.list
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 更改软件源为阿里源并更新必要的软件包
echo "使用阿里源更新"
echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
#echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
#echo "deb-src http://deb.debian.org/debian buster main" >> /etc/apt/sources.list


# 检查screen和git是否已安装
if ! command -v screen &> /dev/null
then
    echo "screen is not installed, installing now..."
    sudo apt-get update
    sudo apt-get install screen -y
else
    echo "安装工具1"
fi

#在根目录下创建
sudo mkdir /updata

echo '#!/bin/bash

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

sudo mkdir /etc/docker

if [ -f /etc/docker/daemon.json ]; then
  echo "文件 /etc/docker/daemon.json 已经存在，备份为 /etc/docker/daemon.json.bak"
  sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
fi

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
	"registry-mirrors": [
		"https://registry.hub.docker.com",
		"http://hub-mirror.c.163.com",
		"https://docker.mirrors.ustc.edu.cn",
		"https://registry.docker-cn.com"
	]
}
EOF

echo none > /sys/class/leds/green:internet/trigger && sleep 1
echo 255 > /sys/class/leds/green:internet/brightness && sleep 1

apt upgrade -y && sleep 2

# 检查根文件系统的已用空间占比
usage_percentage=$(df -h / | awk 'NR==2 {print $5}')

# 提取已用空间占比的数字部分
usage_percentage=${usage_percentage%\%}

# 如果已用空间占比超过 35%，则执行磁盘碎片整理命令
if [[ $usage_percentage -gt 35 ]]; then
  echo "根文件系统已用空间占比超过 35%，尝试磁盘碎片整理..."
  if grep --quiet "btrfs" /etc/fstab; then
      # 执行 Btrfs 文件系统压缩和碎片整理操作
      btrfs filesystem defragment -r -v -czstd /
  fi
else
  echo "根文件系统已用空间占比低于等于 35%，无需进行磁盘碎片整理。"
fi
# 安装推荐软件包
echo "安装推荐软件包"
apt-get install zip byobu cron btrfs-progs rsync preload pv sshpass curlftpfs -y && sleep 3

# 确保docker目录存在
mkdir -p /etc/docker

# Create daemon.json file
cat <<EOT > /etc/docker/daemon.json
{
	"registry-mirrors": [
		"https://registry.hub.docker.com",
		"http://hub-mirror.c.163.com",
		"https://docker.mirrors.ustc.edu.cn",
		"https://registry.docker-cn.com"
	]
}
EOT

# 执行 Docker 安装命令
echo timer > /sys/class/leds/green\:internet/trigger && echo 1000 > /sys/class/leds/green\:internet/delay_on && echo 1000 > /sys/class/leds/green\:internet/delay_off && sleep 1
echo "安装Docker." && sleep 1

attempt=0
while [ $attempt -lt 5 ]; do
    if ! command -v docker &> /dev/null; then
        echo "正在安装 Docker..."
        wget -qO- https://get.docker.com | bash -s docker --mirror Aliyun || wget -qO- https://get.docker.com | bash -s docker --mirror Aliyun
    fi

    # 检查 Docker 是否成功安装
    if command -v docker &> /dev/null; then
        echo "Docker 已成功安装。"
        break
    else
        echo "Docker 安装失败，正在尝试重新安装..."
        attempt=$((attempt+1))
    fi
done

if [ $attempt -eq 5 ]; then
    echo "Docker 安装失败。请检查您的网络连接并重试。"
fi

sleep 3
# 恢复 Docker 数据
echo "正在检查 Docker 是否安装并运行中..."
if command -v docker >/dev/null 2>&1 && sudo systemctl is-active --quiet docker; then
    echo "Docker 安装并运行中，可以恢复 /var/lib/docker 目录"

    # 备份目录路径
    backup_dir="/root"

    # 检查备份目录中是否存在 docker.tar 或 docker.tar.xz 文件
    if [[ -f "$backup_dir/docker.tar" ]] || [[ -f "$backup_dir/docker.tar.xz" ]]; then
        # 停止 Docker
        echo "停止 docker 中"
        sudo systemctl stop docker

        # 解压缩 /var/lib/docker 目录，并使用 pv 命令显示进度
        if [[ -f "$backup_dir/docker.tar" ]]; then
            echo "正在恢复 /var/lib/docker 目录..."
            sudo dd if="$backup_dir/docker.tar" status=progress | pv -q -L 10M | sudo tar -zxvf - -C /
        elif [[ -f "$backup_dir/docker.tar.xz" ]]; then
            echo "正在恢复 /var/lib/docker 目录..."
            sudo dd if="$backup_dir/docker.tar.xz" status=progress | pv -q -L 10M | sudo tar -xJf - -C /
        fi

        # 检查 /root 目录中是否存在 docker.tar 或 docker.tar.xz 文件，并删除
        if [ -f /root/docker.tar ]; then
            rm -f /root/docker.tar
            echo "已删除 /root/docker.tar 文件"
        fi

        if [ -f /root/docker.tar.xz ]; then
            rm -f /root/docker.tar.xz
            echo "已删除 /root/docker.tar.xz 文件"
        fi

    else
        echo "备份目录中没有找到 docker.tar 或 docker.tar.xz 文件"
    fi
else
    echo "Docker 未安装或未运行"
fi

# 清理垃圾并压缩系统
echo none > /sys/class/leds/green:internet/trigger && sleep 1
sudo sh -c "echo timer > /sys/class/leds/blue\:wifi/trigger && echo 500 > /sys/class/leds/blue\:wifi/delay_on && echo 500 > /sys/class/leds/blue\:wifi/delay_off" && sleep 1
echo "正在清理垃圾..."
eval "$clean_commands" && sleep 2
if [[ $(grep -c btrfs /proc/mounts) -gt 0 ]]; then
  echo "正在压缩系统..."
  (crontab -l ; echo "30 1 * * 2,4,6 btrfs filesystem defragment -r -v -czstd /") | crontab - && sleep 6
  btrfs filesystem defragment -r -v -czstd / && sleep 6
else
  echo "系统文件不是btrfs，取消执行压缩系统命令"
fi

# 重启系统
echo "重启以确保稳定性..."
eval "$clean_commands" && sleep 1
echo -e "\033[33;32m如需执行脚本，可以在终端输入：z\033[0m"
echo none > /sys/class/leds/green:internet/trigger && sleep 1
sed -i 's/^byobu-status-exec "top"/#byobu-status-exec "top"/' ~/.byobu/status && sleep 2
byobu-enable && sleep 1
sudo rm /usr/local/bin/x
sudo rm /root/0
sudo rm -rf /root/132
sudo rm -rf /etc/docker
#rm -rf /root/*
sleep 1
#创建docker数据映射目录
ln -s /srv /root/容器映射目录
# Reboot the system
/sbin/reboot' > /updata/1

# 定义文件路径
FILE_PATH="/usr/local/bin/x"

# 创建文件并写入命令
echo "screen -d -r update" > "$FILE_PATH"

#创建菜单脚本z
echo '#!/bin/bash

#检查变量
FILE_PATH=/home/鸡你太美
my_var=$(last | grep "pts/[0-9]" | grep "still logged in" | awk '{print $1}' | uniq -c)

if [ $(systemctl is-active docker) = "active" ]; then
    if grep -q "docker" $FILE_PATH; then
        echo "docker already exists in the file."
    elif grep -q "no docker" $FILE_PATH; then
        sed -i 's/no docker/docker/g' $FILE_PATH
        echo "no docker has been replaced with docker in the file."
    else
        echo "docker" >> $FILE_PATH
        echo "docker has been added to the file."
    fi
else
    if grep -q "no docker" $FILE_PATH; then
        echo "no docker already exists in the file."
    elif grep -q "docker" $FILE_PATH; then
        sed -i 's/docker/no docker/g' $FILE_PATH
        echo "docker has been replaced with no docker in the file."
    else
        echo "no docker" >> $FILE_PATH
        echo "no docker has been added to the file."
   fi
fi

hour=$(date +%H)

if ! pgrep docker >/dev/null; then
    echo "Docker未运行。正在启动Docker..."
    sudo systemctl start docker
elif ((hour >= 5 && hour < 12)); then
    echo "早上好！欢迎使用脚本！"
elif ((hour >= 12 && hour < 18)); then
    echo "下午好！欢迎使用脚本！"
else
    echo "晚上好！欢迎使用脚本！"
fi

echo "请选择要执行的操作："
echo "1. 安装工具"
echo "2. 其他命令"
echo "3. 快捷命令"
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

read -p "请输入选项（1、2、3、3a、3b、3c、3d）：" option

if [ "$option" == "1" ]; then
  echo "请选择要执行的操作："
  echo "a. 安装Docker"
  echo "b. 安装ql"
  echo "c. 安装1Panel"
  echo "d. 安装bt"
  echo "e. 安装Aria2"
  echo "f. 安装Alist"
  echo "g. 安装CasaOS"
  echo "h. 安装qiandao"
  echo "i. 安装UnblockNeteaseMusic"
  echo "j. 安装Hsaa"
  read -p "请输入字母选项：" install_option

  if [ "$install_option" == "a" ]; then
    echo "请选择安装docker的镜像源（可能需要稳定的网络环境）："
    echo "1. 使用Docker官方源"
    echo "2. 使用阿里云镜像源"
    echo "3. 使用DaoCloud镜像源"
    echo "4. 移动docker目录"
    echo "5. 删除Docker及其相关文件和设置"
    read -p "请输入选项（1、2、3、4）：" option
    if [ "$option" == "1" ]; then
    echo "从Docker官方安装Docker"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    elif [ "$option" == "2" ]; then
      echo "从阿里云安装Docker"
      curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    elif [ "$option" == "3" ]; then
      echo "从DaoCloud安装Docker"
      curl -sSL https://get.daocloud.io/docker | sh
    elif [ "$option" == "4" ]; then
      echo "拉取脚本中，执行迁移操作可能会出现问题，自行解决"
      sudo curl -sSL https://raw.githubusercontent.com/xiezh123/132/main/3 -o /root/Quick/3 && sudo bash /root/Quick/3
    elif [ "$option" == "5" ]; then
      echo "确认删除 Docker 及其相关文件和设置（如需恢复请更新软件包，如安装docker—ce）"
      sudo docker stop $(sudo docker ps -aq)
      sudo systemctl stop docker && sudo apt-get purge docker-ce docker-ce-cli containerd.io && sudo rm -rf /var/lib/docker /etc/docker && sudo groupdel docker && sudo userdel -r docker && sudo rm -rf /etc/systemd/system/docker.service.d /etc/systemd/system/containerd.service.d /lib/systemd/system/docker.service /lib/systemd/system/containerd.service
    echo "Docker 已被删除"
    else
      echo "无效的选项"
      exit 1
    fi

    echo "启用 Docker 服务..."
    sudo systemctl enable docker
    echo -e "\e[33m请查看 Docker 守护进程的状态信息，出现 \e[32mActive: active (running)\e[33m 即可，安装出错请尝试到：脚本>2>a，修复软件包或更换源\e[0m"
    sudo systemctl start docker && sleep 3
    systemctl status docker
  elif [ "$install_option" == "b" ]; then
    echo "请选择您要安装的版本："
    echo "1. 安装 Debian 版本"
    echo "2. 安装正式版"
    echo "3. 安装 2.10.13 稳定版"
    echo "4. 进入容器"
    source_dir="/srv/ql/scripts"
    target_dir="/root/青龙脚本"
    read panel_option

    if [ "$panel_option" == "1" ]; then
        echo "安装 Debian 版本..."
        ## 执行安装命令
        docker pull whyour/qinglong:debian && sleep 2
        docker run -dit \
        -v /srv/ql:/ql/data \
        -p 5700:5700 \
        --name qinglong \
        --hostname qinglong \
        --restart always \
        whyour/qinglong:debian &&
        ln -s "$source_dir" "$target_dir"
    elif [ "$panel_option" == "2" ]; then
        echo "安装正式版..."
        ## 执行安装命令
        docker run -dit \
        -v /srv/ql:/ql/data \
        -p 5700:5700 \
        --name qinglong \
        --hostname qinglong \
        --restart always \
        whyour/qinglong:latest &&
        ln -s "$source_dir" "$target_dir"
    elif [ "$panel_option" == "3" ]; then
        echo "安装 2.10.13 稳定版..."
        ## 执行安装命令
        docker run -dit \
        -v /srv/ql/config:/ql/config \
        -v /srv/ql/log:/ql/log \
        -v /srv/ql/db:/ql/db \
        -v /srv/ql/scripts:/ql/scripts \
        -v /srv/ql/jbot:/ql/jbot \
        -v /srv/ql/repo:/ql/repo \
        -v /srv/ql/ninja:/ql/ninja \
        -v /srv/ql/raw:/ql/raw \
        -p 5960:5700 \
        -p 5701:5701 \
        -e ENABLE_HANGUP=true \
        -e ENABLE_WEB_PANEL=true \
        --name ql \
        --hostname ql \
        --privileged=true \
        --restart always \
        whyour/qinglong:2.10.13 &&
        ln -s "$source_dir" "$target_dir"
    elif [ "$panel_option" == "4" ]; then
        echo "进入容器，按住 Ctrl 和 PQ 退出容器，执行 ql -l check 修复面板"
        echo "2.10.13 稳定版执行 docker exec -it qinglong bash -c "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/FlechazoPh/QLDependency/main/Shell/QLOneKeyDependency.sh | sh)"
 安装依赖，如果查看不全，自行打开脚本查看"
        docker exec -it qinglong /bin/bash
    else
        echo "无效的选项，退出脚本"
    fi
  elif [ "$install_option" == "c" ]; then
    echo "安装1Panel面板"
    echo "如果需要备份数据，可以将其安装在/srv目录下"
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
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
    wget https://get.casaos.io -O casaos.sh && bash casaos.sh
  elif [ "$install_option" == "h" ]; then
    echo "安装qiandao,IP:8923"
    docker run --restart=always -d --name qiandao -p 8923:80 -v /srv/qiandao/config:/usr/src/app/config a76yyyy/qiandao:lite-latest
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
  elif [ "$install_option" == "j" ]; then
    sudo docker run -d --name hass --restart=always -p 8123:8123 -v /srv/hass:/config homeassistant/home-assistant
    echo "端口：8123"
  else
    echo "选项不存在"
  fi
elif [ "$option" == "2" ]; then
  echo "请选择要执行的操作："
  echo "a. 检查并修复软件包"
  echo "b. 关机"
  echo "c. 禁用系统日志"
  echo "d. 深度清理文件"
  echo "e. 添加主机模式"
  echo "f. 更改CPU频率"
  echo "g. 查看emmc"
  echo "h. LED控制选项"
  echo "i. 安装桌面（xfce）"
  read -p "请输入选项（a、b、c、d、e）：" check_option

  if [ "$check_option" == "a" ]; then
    echo "正在检查并更新软件包..."
    echo -e '\xE2\xA0\x84\xE2\xA0\x84\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA0\x98\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xA7\xE2\xA3\x9B\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA0\xA4\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBF\xE2\xA3\xBD\xE2\xA1\x86\xE2\xA0\x84\xE2\xA0\x84'
    apt-get check && apt-get -f install
    sleep 1
    sudo apt-get update && sleep 2 && sudo apt --fix-broken install
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
  elif [ "$check_option" == "f" ]; then
  # 检查 cpufrequtils 是否已安装，如果未安装则自动安装
  if ! dpkg -s cpufrequtils > /dev/null 2>&1 ; then
      echo "cpufrequtils 尚未安装，正在安装..."
      sudo apt-get install cpufrequtils -y
  fi

  # 显示选择菜单
  echo "请选择 CPU 频率："
  echo "1. 动态调整"
  echo "2. 800 MHz"
  echo "3. 1000 MHz"
  echo "4. 1.20 GHz"
  echo "5. 1.40 GHz"
  echo "6. 1.60 GHz"
  echo "7. 1.80 GHz"
  echo "8. 2.00 GHz"
  echo "9. 2.10 GHz"

  # 读取用户输入
  read -p "请输入数字 [1-9]: " choice

  # 根据用户输入修改 CPU 频率
  case $choice in
    1) sudo cpufreq-set -g ondemand ;;
    2) sudo cpufreq-set -c 0 -f 800000 ;;
    3) sudo cpufreq-set -c 0 -f 1000000 ;;
    4) sudo cpufreq-set -c 0 -f 1200000 ;;
    5) sudo cpufreq-set -c 0 -f 1400000 ;;
    6) sudo cpufreq-set -c0 -f 1600000 ;;
    7) sudo cpufreq-set -c 0 -f 1800000 ;;
    8) sudo cpufreq-set -c 0 -f 2000000 ;;
    9) sudo cpufreq-set -c 0 -f 2100000 ;;
    *) echo "错误的输入" ;;
  esac

  echo "CPU 频率已修改为："
  sudo cpufreq-info | grep "current CPU frequency"
  elif [ "$check_option" == "g" ]; then
    cat /sys/class/mmc_host/mmc0/mmc0\:0001/life_time
  elif [ "$check_option" == "h" ]; then
    bash -c "$(curl -L gitee.com/ojf6ii/led-control-script/raw/master/led.sh)"
  elif [ "$check_option" == "i" ]; then
    read -p "需要4g左右空间，安装速度由棒子体质决定，输入x返回会话，回车继续"
    # 检查screen和git是否已安装
    if ! command -v screen &> /dev/null
    then
        echo "安装screen"
        sudo apt-get install screen -y
    else
        echo "安装工具1"
    fi
    echo '#!/bin/bash
    sudo apt-get update && sudo apt-get install xrdp -y && sleep 3
    sudo service xrdp start -y && apt-get install task-xfce-desktop -y && sleep 3
    sudo apt-get install -y openssh-server
    sudo systemctl start ssh
    btrfs filesystem defragment -r -v -czstd / && sleep 3
    wget https://dldir1.qq.com/qqfile/qq/QQNT/ad5b5393/linuxqq_3.1.2-13107_arm64.deb && sudo dpkg -i linuxqq_3.1.2-13107_arm64.deb
    sudo rm /root/linuxqq_3.1.2-13107_arm64.deb
    sudo rm /root/Desktop.sh
    sudo rm /usr/local/bin/x' > Desktop.sh
    sleep 2
    sudo chmod +x /root/Desktop.sh
    # 定义文件路径
    FILE_PATH="/usr/local/bin/x"
    FILE="screen -d -r Desktop"
    # 创建文件并写入命令
    echo "$FILE" > "$FILE_PATH"
    sudo chmod +x /usr/local/bin/x
    #新建窗口
    screen -dmS Desktop bash -c "bash /root/Desktop.sh"
    sleep 2
    $FILE
    GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo -e "${GREEN}请使用远程桌面客户端连接到服务器，使用root用户名和密码登录。${NC}"
  else
    echo "选项不存在"
  fi
elif [[ "$option" == "3a" ]]; then
  # 显示 LED 控制菜单
  echo "请选择 LED 控制选项：（回车关闭）"
  echo "1. 保留WiFi（默认情况）"
  echo "2. 蓝绿互换"
  read -r led_option
  
  # 处理 LED 控制选项
  case "$led_option" in
    1)
      # 关闭其他 LED
      echo 0 > /sys/class/leds/mmc0\:\:/brightness #红灯
      echo none > /sys/class/leds/green\:internet/trigger #绿灯
      ;;
    2)
      # LED 互换
      echo heartbeat > /sys/class/leds/blue\:wifi/trigger
      echo phy0tx > /sys/class/leds/green\:internet/trigger
      ;;
    *)
      # 默认情况：关闭 LED
      echo "关闭 LED"
      echo 0 > /sys/class/leds/mmc0\:\:/brightness #红灯
      echo none > /sys/class/leds/blue\:wifi/trigger #蓝灯
      echo none > /sys/class/leds/green\:internet/trigger #绿灯
      if [ ! -f "/etc/dconf/jntm/led" ]; then
          echo "文件不存在"
          exit 1
      fi

      # 检查文件内容是否为"no"
      if grep -q "no" "/etc/dconf/jntm/led"; then
          echo "文件已经包含\"no\""
          exit 0
      fi

      # 添加"no"到文件尾部
      echo "no" >> "/etc/dconf/jntm/led"
      ;;
  esac
elif [[ "$option" == "3b" ]]; then 
  echo "清理垃圾"
  eval "$clean_commands"

  ROOT_PARTITION=$(mount | grep "on / " | cut -d' ' -f1)
  if [ "$(lsblk -o FSTYPE "$ROOT_PARTITION" | tail -n1)" == "btrfs" ]; then 
    echo "根文件系统为 btrfs，执行相关操作"
    btrfs filesystem defragment -r -v -czstd /
  else 
    echo "根文件系统不是 btrfs，跳过相关操作"
  fi 
elif [[ "$option" == "3c" ]]; then 
  echo "查看网络信息"
  ip addr show
  ping -c 4 baidu.com
  ping -c 4 google.com
  mmcli -m 0
elif [[ "$option" == "3d" ]]; then 
  echo "查看系统状态"
  echo "系统详情：$(uname -a)"
  echo "CPU 信息：$(lscpu)"
  echo "内存占用情况：$(free -h)"
  echo "Swap 占用情况：$(swapon -s)"
  echo "磁盘挂载情况：$(lsblk)"
  echo "存储占用情况：$(df -h)"
else
  echo "选项不存在"
fi' > /usr/local/bin/z

# 赋予可执行权限
chmod +x "$FILE_PATH"
chmod +x /usr/local/bin/z
#新建窗口
screen -dmS update bash -c "bash /updata/1"
sleep 2
screen -d -r update
