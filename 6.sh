#!/bin/bash
######################################################被拉取脚本
function ip1 {
################################################################################################################################################################################服务
sys0() {

script_content2="#!/bin/bash

# 检查是否为半夜 2 点 30 分
if [[ \$current_hour -eq 2 && \$current_minute -eq 30 ]]; then
    if [[ -z \"\$container_ids\" ]]; then
        echo \"没有找到任何正在运行的 Docker 容器。\"
    else
        # 逐个退出容器
        for container_id in \$container_ids; do
            echo \"正在退出容器: \$container_id\"
            docker stop \$container_id
        done

        echo \"所有容器已成功退出。\"
    fi
    sudo systemctl stop led.service
    screen -dmS reboot1 bash -c \"btrfs filesystem defragment -r -v -czstd / && bash /etc/dconf/jntm/push.sh\"
    sleep 3
    reboot
else
    # 早上7到23时每15分钟执行一次
    current_hour=\$(date +\%H)
    current_minute=\$(date +\%M)
    
    if [ \"\$current_hour\" -ge 7 ] && [ \"\$current_hour\" -lt 11 ] && [ \"\$current_minute\" -eq 0 ]; then
        echo \"执行命令：bash /etc/dconf/jntm/push.sh\"
        bash /etc/dconf/jntm/push.sh
    fi
fi

exit 0"

echo "$script_content2" > /etc/dconf/jntm/quick.sh

}
#######################################################################################
# 交换分区和启动命令
sys1() {

script_content="#!/bin/bash

nmcli radio wifi off
sleep 1
sudo cpufreq-set -g performance

# 关闭 zram0 交换分区
sudo swapoff /dev/zram0
sudo zramctl -r /dev/zram0
# 加载 zram 模块
sudo modprobe zram
# 获取 /swapfile 文件的大小
swapfile_size=\$(sudo du -h /swapfile | awk '{print \$1}')
# 创建新的 zram0 交换分区
zram_dev=\$(sudo zramctl --find --size \$swapfile_size)
sudo mkswap \$zram_dev
sudo swapon \$zram_dev

sleep 10

sudo sed -i 's/^reboot0=.*/reboot0=0/' /etc/environment

sleep 1

sudo sed -i 's/^LEDoff=.*/LEDoff=0/' /etc/environment

sleep 10

nmcli radio wifi on

sleep 2

# 执行 ifconfig 命令并将输出保存到变量中
output=\$(ifconfig usb0)

sleep 1

# 使用 grep 命令在输出中查找目标字符串
if echo \"\$output\" | grep -q \"inet 10.42.0.1\"; then
    sudo sed -i 's/^host=.*/host=0/' /etc/environment
else
    echo host > /sys/kernel/debug/usb/ci_hdrc.0/role
    sleep 1
    sudo sed -i 's/^host=.*/host=1/' /etc/environment
    sleep 1
    # 执行 fdisk -l 命令并将结果保存到变量中
    output=\$(fdisk -l)
    sleep 1
    # 使用正则表达式匹配设备信息，并将匹配结果保存到数组中
    regex='/dev/sda1\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+([0-9.]+[KMG]?)\s+Linux filesystem'
    devices=()
    while read -r line; do
        if [[ \$line =~ \$regex ]]; then
            size=\${BASH_REMATCH[1]}
            devices+=(\"\$line\")
        fi
    done <<< \"\$output\"

    # 挂载设备
    if [ \${#devices[@]} -gt 0 ]; then
        echo \"找到以下设备：\"
        for device in \"\${devices[@]}\"; do
            echo \"\$device\"
            # 提取设备路径
            device_path=\$(echo \"\$device\" | awk '{print \$1}')
            # 创建挂载点目录
            mount_point=\"/mnt/\$(basename \"\$device_path\")\"
            echo \"将 \$device_path 挂载到 \$mount_point\"
            mkdir -p \"\$mount_point\"
            # 挂载设备
            mount \"\$device_path\" \"\$mount_point\"
        done
    else
        echo \"未找到匹配的设备。\"
    fi
fi

sleep 3

# Ping 百度网站并执行相应操作
if ping -c 1 www.baidu.com >/dev/null 2>&1; then
    # 检查 Docker 是否已安装
    if command -v docker &> /dev/null; then
        if systemctl is-enabled docker &> /dev/null; then
            systemctl disable docker
        else
            systemctl start docker
        fi
    else
        echo \"Docker 未安装，跳过...\"
    fi
    bash /etc/dconf/jntm/push.sh
else
    echo \"无法连通 www.baidu.com\"
fi

sleep 1

# 读取 /etc/environment 文件中的环境变量
while read -r line; do
    export \"\$line\"
done < /etc/environment

# 使用读取的环境变量
echo \"LED 环境变量的值是：\$LED\"

# 检查 LED 环境变量的值并显示相应的提示
if [[ \"\$LED\" == \"0\" ]]; then
    echo \"LED 的值为 0\"
    echo 0 > /sys/class/leds/mmc0\\:\\:/brightness #红灯
    echo none > /sys/class/leds/blue\\:wifi/trigger #蓝灯
    echo none > /sys/class/leds/green\\:internet/trigger #绿灯
else
    # 检查文件夹是否存在
    if [ -d \"/etc/dconf/jntm\" ]; then
        echo \"文件夹 /etc/dconf/jntm 已存在.\"
    
        # 检查文件是否存在
        if [ -f \"/etc/dconf/jntm/led\" ]; then
            echo \"文件 /etc/dconf/jntm/led 已存在.\"
        else
            echo \"文件 /etc/dconf/jntm/led 不存在，创建文件...\"
            touch \"/etc/dconf/jntm/led\"
            echo \"文件 /etc/dconf/jntm/led 创建成功.\"
        fi
    else
        mkdir -p \"/etc/dconf/jntm\"
        touch \"/etc/dconf/jntm/led\"
        echo \"文件夹 /etc/dconf/jntm 及文件 /etc/dconf/jntm/led 创建成功.\"
    fi
fi
sleep 60
sudo cpufreq-set -g ondemand
sudo systemctl stop zram.service

exit 0"

# 将脚本内容写入脚本文件
echo "$script_content" > zram.sh

echo '#脚本
# 压缩算法，效果: zstd > lzo > lz4，速度: lz4 > zstd > lzo，默认lz4
ALGO=zstd

#由于自定义了zram，此项作废
PERCENT=10
#SIZE=256

#交换分区优先级
PRIORITY=300' > zramswap

######################################网络

# 要添加到 hosts 文件中的 IP 地址和域名
ip_list="157.148.69.80 www.baidu.com\n182.89.194.244 mirrors.aliyun.com\n140.82.114.3 github.com\n185.199.108.153 assets-cdn.github.com\n199.232.69.194 github.global.ssl.fastly.net\n151.101.0.133 raw.githubusercontent.com\n140.82.121.3 http://github.com\n140.82.121.3 http://gist.github.com\n185.199.110.153 http://assets-cdn.github.com\n185.199.108.133 http://raw.githubusercontent.com\n185.199.111.133 http://gist.githubusercontent.com\n185.199.110.133 http://cloud.githubusercontent.com\n185.199.111.133 http://camo.githubusercontent.com\n185.199.111.133 http://avatars0.githubusercontent.com\n185.199.110.133 http://avatars1.githubusercontent.com\n185.199.111.133 http://avatars2.githubusercontent.com\n185.199.109.133 http://avatars3.githubusercontent.com\n185.199.108.133 http://avatars4.githubusercontent.com\n185.199.111.133 http://avatars5.githubusercontent.com\n185.199.109.133 http://avatars6.githubusercontent.com\n185.199.109.133 http://avatars7.githubusercontent.com\n185.199.110.133 http://avatars8.githubusercontent.com\n185.199.108.133 http://avatars.githubusercontent.com\n185.199.111.154 http://github.githubassets.com\n185.199.109.133 http://user-images.githubusercontent.com\n140.82.112.9 http://codeload.github.com\n185.199.110.133 http://favicons.githubusercontent.com\n192.30.255.116 http://api.github.com"

echo "$ip_list" | sudo tee -a /etc/hosts
  
echo "正在更改DNS服务器..."
echo "nameserver 180.76.76.76" | sudo tee -a /etc/resolv.conf
echo "nameserver 180.76.76.67" | sudo tee -a /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
echo "nameserver 223.5.5.5" | sudo tee -a /etc/resolv.conf
echo "nameserver 223.6.6.6" | sudo tee -a /etc/resolv.conf

}

#######################################################################################
# 备份脚本
sys2() {
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
  htop
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
}
#######################################################################################
# Led控制
sys3() {
  echo '#!/bin/bash

# 读取 /etc/environment 文件中的环境变量
while read -r line; do
    export "$line"
done < /etc/environment

# 检查 LED 环境变量的值并显示相应的提示
if [[ "$LED" == "1" ]]; then
    echo "LED 的值为 1"
    export LEDOFF=0
else
    export LEDOFF=1
fi

# 定义LED控制函数
led_control() {

  sudo sh -c "echo phy0tx > /sys/class/leds/blue\:wifi/trigger && echo mmc0 > /sys/class/leds/mmc0\:\:/trigger"
  
  # 获取温度值
  temp=$(cat /sys/class/thermal/thermal_zone0/temp)
  
  # 取头值
  head=${temp:0:1}
  
  # 如果第二位大于5，则头值加1
  if [ ${temp:1:1} -ge 5 ]; then
    head=$((head+1))
  fi
  
  # 如果头值小于5，则退出脚本
  if [ $head -lt 5 ]; then
    echo "头值小于5，停止执行脚本。"
    exit 1
  fi
    
  echo 255 > /sys/class/leds/green:internet/brightness
  
  sleep 3

  echo 0 > /sys/class/leds/green:internet/brightness

  sleep 2
  
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
  # 检查环境变量内容是否为"1"
  if [[ "$LEDOFF" == "1" ]]; then
      exit 1
  else
      echo "LED环境变量的值不是1"
  fi
  
  echo "绿色 LED 触发器状态不为 none，开始执行 led_control 命令..."
  led_control
  echo "led_control 命令执行完毕。"
  exit 0
}

#检查wifi
check_led_nowifi() {
  # 检查环境变量内容是否为"1"
  if [[ "$LEDOFF" == "1" ]]; then
      exit 1
  else
      echo "LEDoff环境变量的值不是1"
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
        sleep 5
        nmcli radio wifi on
        sleep 10
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
# 检查wifi.log文件是否存在
if [ ! -e /etc/dconf/jntm/wifi.log ]; then
    touch /etc/dconf/jntm/wifi.log
    echo "$(date +%Y-%m-%d\ %H:%M:%S): wifi.log does not exist, creating one." >> /var/log/wifi.log
fi

# 判断执行次数是否达到10次
if [ ! -e /etc/dconf/jntm/opweroff ]; then
    if [ ! -e /var/log/count.log ]; then
        echo "0" > /var/log/count.log
    fi

    count=$(cat /var/log/count.log)
    count=$((count+1))
    echo $count > /var/log/count.log

    if [ "$count" -eq 10 ]; then
        # 创建opweroff文件
        touch /etc/dconf/jntm/opweroff
        # 执行函数1
        /sbin/reboot
    fi
else
    # 删除创建的文件
    rm -f /var/log/count.log
    rm -f /etc/dconf/jntm/wifi.log
    rm -f /etc/dconf/jntm/opweroff

    # 检查网络连接是否畅通
    if ping -c 1 www.baidu.com &> /dev/null; then
        exit 0 # 如果网络畅通，则停止执行
    fi

    # 执行函数2
    sleep 2
    systemctl suspend

fi
}

#删除wifilog
function remove_wifi_log() {
    logfile="/etc/dconf/jntm/wifi.log"

    # 检查 log 文件是否存在，如果存在则删除
    if [ -e "${logfile}" ]; then
        rm "${logfile}"
    fi
    if [ -e /var/log/count.log ]; then
        rm -f /var/log/count.log
    fi
    
    if [ -e /etc/dconf/jntm/wifi.log ]; then
        rm -f /etc/dconf/jntm/wifi.log
    fi
    
    if [ -e /etc/dconf/jntm/opweroff ]; then
        rm -f /etc/dconf/jntm/opweroff
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
    fi
fi
' > /etc/dconf/jntm/LEDnetwork.sh

echo "#!/bin/bash

uptime_output=\$(uptime)
uptime_info=\"\"

# 解析开机时间
uptime=\$(echo \"\$uptime_output\" | awk -F \"up \" '{print \$2}' | awk -F \",\" '{print \$1}' | sed 's/^[[:space:]]*//')
uptime_info+=\"当前系统已经开机 \$uptime，\"

# 解析登录用户数
users=\$(echo \"\$uptime_output\" | awk -F \", \" '{print \$2}' | awk '{print \$1}')
uptime_info+=\"当前登录用户数为 \$users 个，\"

# 解析负载平均值
load_average=\$(echo \"\$uptime_output\" | awk -F \"load average: \" '{print \$2}')
load_average_info=\"系统的负载平均值为：\$load_average\"

uptime_info+=\$load_average_info

echo \"\$uptime_info\"

function dockersys {
# 获取 Docker 所有容器 ID
container_ids=\$(docker ps -aq)

if [[ -z \"\$container_ids\" ]]; then
    echo \"没有找到任何正在运行的 Docker 容器。\"
else
    # 逐个退出容器
    for container_id in \$container_ids; do
        echo \"正在退出容器: \$container_id\"
        docker stop \$container_id
    done

    echo \"所有容器已成功退出。\"
fi
# 关闭 Docker
echo \"正在关闭 Docker 服务...\"
systemctl stop docker
}

# 获取当前时间的小时和分钟
current_hour=\$(date +%H)
current_minute=\$(date +%M)

# 检查是否为半夜 2 点 30 分
if [[ \$current_hour -eq 2 && \$current_minute -eq 30 ]]; then
    dockersys
    btrfs filesystem defragment -r -v -czstd /
    reboot
else
    echo 1 > /proc/sys/vm/drop_caches
    dockersys
    poweroff
fi" > /usr/local/bin/f

}
#######################################################################################
# 启用系统服务
sysd () {
# Create led.service file
cat << EOL > /etc/systemd/system/led.service
[Unit]
Description=Check network for jntm and led

[Service]
Type=simple
ExecStartPre=/bin/sleep 30
ExecStart=/bin/bash /etc/dconf/jntm/quick.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOL

# Enable led.service
systemctl daemon-reload
systemctl enable led.service

# Create zram.service file
cat << EOL > /etc/systemd/system/zram.service
[Unit]
Description=Setup Zram swap
After=local-fs.target

[Service]
ExecStartPre=/bin/sleep 45
ExecStart=/etc/dconf/jntm/zram.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL

# Enable zram.service
systemctl daemon-reload
systemctl enable zram.service

}

push0() {

sudo tee /etc/dconf/jntm/push.sh <<EOF
#!/bin/bash
#code by Aimt#

# 读取 /etc/environment 文件中的环境变量
while read -r line; do
    export "$line"
done < /etc/environment

# 将自己的token复制到这里 eg.MyToken="123456xxxx"
MyToken="$PushToken"

cpu_usage=\$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - \$1}')
memory_usage=\$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", \$3,\$2,\$3*100/\$2 }')
network_traffic=\$(/sbin/ifconfig enx00e04c360017 | awk '/RX p/{print \$6,\$7}')

push_body="服务器{\$(hostname)}状态信息：\n\n"
push_body+="公网IP：\$(curl -s cip.cc | awk 'NR==1{printf \$3}')\n"
push_body+="局域网IP：\$(hostname -I | awk '{print \$1}')\n"
push_body+="USB网卡IP：\$(ifconfig usb0 | awk '/inet /{print \$2}')\n"
push_body+="CPU温度：\$(cat /sys/class/thermal/thermal_zone0/temp | awk '{print \$1/1000}')℃\n"
push_body+="CPU负载：\$(uptime | awk '{print \$(NF-2),\$(NF-1),\$(NF)}')\n"
push_body+="CPU使用率：\${cpu_usage/100}%\n"
push_body+="内存使用率：\${memory_usage}\n"
push_body+="流量传输：\$network_traffic\n"
push_body+="运行时间：\n\$(uptime -p)"

json="{\"token\": \"\$MyToken\", \"content\": \"\$push_body\"}"
url="http://www.pushplus.plus/send"
curl -X GET "\$url" -H "Content-Type: application/json" -d "\$json"

exit 0
EOF

script_path="/usr/local/bin/u"
script_content0='#!/bin/bash

# 设置尝试次数
max_attempts=3
attempt=1

while [ $attempt -le $max_attempts ]; do
    # 执行wget命令下载文件
    wget "https://raw.githubusercontent.com/xiezh123/132/main/1" -O "/usr/local/bin/z"
    
    # 检查文件是否为空文件
    if [ -s "/usr/local/bin/z" ]; then
        echo "文件已成功下载并不为空。"
        break
    else
        echo "文件为空或下载失败。尝试重新下载（尝试次数：$attempt）。"
        attempt=$((attempt+1))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    echo "无法下载文件。尝试次数已达到上限。"
fi'

echo "$script_content0" > "$script_path"
chmod +x "$script_path"

}

#######################################################################################
# 赋予执行权限
sys() {
  #移动到/etc/default并且启用自启服务
  sudo cp /etc/default/zramswap /etc/default/zramswap.bak
  sudo rm -f /etc/default/zramswap
  sudo mv zram.sh /etc/dconf/jntm/zram.sh
  sudo mv zramswap /etc/default/zramswap
  sudo chmod +x /etc/default/zramswap
  sudo chmod +x /etc/dconf/jntm/zram.sh
  sudo chmod +x /etc/dconf/jntm/LEDnetwork.sh
  sudo chmod +x /usr/local/bin/b
  sudo chmod +x /usr/local/bin/f
  sudo chmod +x /usr/local/bin/u
  sudo chmod +x /etc/dconf/jntm/quick.sh
  sudo chmod +x /etc/dconf/jntm/push.sh
  ###############################################环境变量
  file_path="/root/wifi"
  line_number=4

  # 检查文件是否存在
  if [ -f "$file_path" ]; then
      # 获取第四行内容
      line_content=$(sed -n "${line_number}p" "$file_path")

      if [ -z "$line_content" ] || [ "$line_content" -ne 0 ]; then
          # 第四行为空或不为 0，执行 "LED=1" 的写入操作
          sudo sh -c 'echo "LED=1" >> /etc/environment'
          echo "已向 /etc/environment 写入 LED=1"
      else
          # 第四行为 0，执行 "LED=0" 的写入操作
          sudo sh -c 'echo "LED=0" >> /etc/environment'
          echo "已向 /etc/environment 写入 LED=0"
      fi
  else
      echo "文件 $file_path 不存在"
  fi                                                                 #led自启动
  sudo sh -c 'echo "host=0" >> /etc/environment'                     #主机模式
  sudo sh -c 'echo "LEDoff=0" >> /etc/environment'                   #led关闭
  sudo sh -c 'echo "LEDsys=1" >> /etc/environment'                   #led配置
  sudo sh -c 'echo "PushToken=0" >> /etc/environment'                #推送代码
  sudo sh -c 'echo "Pushoff=0" >> /etc/environment'                  #推送开关
  sudo sh -c 'echo "reboot0=0" >> /etc/environment'                  #过载重启
  #备份sources.list
  sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

}

########################################################################################################################################################################################

# 检查/etc/dconf目录是否包含jntm文件夹
if [ -d /etc/dconf/jntm ]; then
  echo "jntm文件夹已存在，跳过执行。"
else
  echo "创建文件夹jntm"
  mkdir /etc/dconf/jntm
  sys0 >/dev/null 2>&1
  sys1 >/dev/null 2>&1
  sys2 >/dev/null 2>&1
  sys3 >/dev/null 2>&1
  push0 >/dev/null 2>&1
  sys
  sysd
  echo "成功创建了脚本"
fi
#sys是执行权限，sysd是系统服务的创建，sys1是zrm0的启用,2是备份脚本的创建，3是led的控制

########################################################################################################################################################################################
# 更新源函数
function set_debian_mirror() {
    mirror="mirrors.ustc.edu.cn"

    echo "正在测试中科大源..."
    avg_time=$(ping -c 3 "$mirror" | tee /dev/tty | awk -F'/' 'END{print $5}')

    if [ -n "$avg_time" ]; then
        echo "平均ping时间为 $avg_time 毫秒。"
        ip_address=$(ping -c 1 -n -q "$mirror" | awk -F'[()]' 'NR==1{print $2}')
        echo "服务器IP地址为 $ip_address。"

        if [ -n "$ip_address" ]; then
            echo "将 $mirror 的IP地址 $ip_address 添加到 hosts 文件中..."
            echo "$ip_address $mirror" | sudo tee -a /etc/hosts >/dev/null
            echo "deb https://mirrors.ustc.edu.cn/debian/ bullseye main contrib non-free" > /etc/apt/sources.list
            echo "deb-src https://mirrors.ustc.edu.cn/debian/ bullseye main contrib non-free" >> /etc/apt/sources.list
            echo "deb https://mirrors.ustc.edu.cn/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list
            echo "deb-src https://mirrors.ustc.edu.cn/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list
            echo "deb https://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free" >> /etc/apt/sources.list
            echo "deb-src https://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free" >> /etc/apt/sources.list
            echo "deb https://mirrors.ustc.edu.cn/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
            echo "deb-src https://mirrors.ustc.edu.cn/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
            echo "完成。"
        else
            echo "尝试使用阿里源"
            mirror2="mirrors.aliyun.com"
            echo "正在获取 $mirror2 的IP地址..."
            ip_address2=$(ping -c 1 -n -q "$mirror2" | awk -F'[()]' 'NR==1{print $2}')

            if [ -n "$ip_address2" ]; then
                echo "将 $mirror2 的IP地址 $ip_address 添加到 hosts 文件中..."
                echo "$ip_address2 $mirror2" | sudo tee -a /etc/hosts >/dev/null
                echo "完成。"
            else
                echo "无法获取 $mirror2 的IP地址。"
            fi
            echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list
            echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list
            echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
            echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
            echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
            echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
            echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
            echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
        fi
    else
        echo "无法连接到网络"
        while true
        do
            ping -c 1 www.baidu.com >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "网络正常"
                break
            else
                echo "网络无法访问，继续尝试，成功为止。"
                sleep 1
            fi
        done

        echo "退出循环"
        set_debian_mirror

    fi
}

# 调用函数
set_debian_mirror

# 检查screen和git是否已安装
if ! command -v screen &> /dev/null
then
    echo "screen is not installed, installing now..."
    sudo apt-get update
    sudo apt-get install screen cpufrequtils -y
else
    echo "已经安装工具？？？"
fi

# 检查 screen 和 cpufrequtils 是否已安装
if dpkg -s screen cpufrequtils >/dev/null 2>&1; then
  echo "screen 和 cpufrequtils 已安装"
else
  echo -e "\033[31m更新失败，使用阿里源\033[0m"
  echo "182.89.194.244 mirrors.aliyun.com" | sudo tee -a /etc/hosts
  echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list
  echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list
  echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
  echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
  echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
  echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
  echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
  echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
  sudo apt-get update
  sudo apt-get install screen cpufrequtils -y
fi

#在根目录下创建，调整性能模式
sudo mkdir /updata
sudo cpufreq-set -g performance
########################################################################################################################################################################################

# 检查/etc/apt目录是否包含sources.list.backup文件
if [ -f /etc/apt/sources.list.backup ]; then
  echo "sources.list.backup文件已存在，跳过执行。"
else
  # 如果文件不存在，则调用sys函数
  sys
fi

########################################################################################################################################################################################
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
echo "为您的系统安装推荐软件包"
apt-get install gnupg2 byobu cron btop rsync preload pv sshpass curlftpfs irqbalance -y && sleep 3

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

echo "确保您的系统具有最新的 GPG 密钥库"
sudo apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com

# 使用阿里云的Docker镜像下载并运行 get.docker.com 脚本
echo "正在测试拉取环境"
if ping -c 4 get.docker.com; then
  echo -e "\033[32mPing 测试成功。正在下载 Docker 安装脚本...\033[0m"
  curl -# https://get.docker.com -o get-docker.sh
  if [ ! -s get-docker.sh ]; then
    echo -e "\033[31m下载的 Docker 安装脚本为空文件，尝试其他安装方法\033[0m"
    curl https://get.docker.com | bash -s docker --mirror Aliyun
  fi
  echo -e "\033[33m尝试安装Docker服务中，请耐心等待\033[0m"
  sudo bash get-docker.sh
  sudo rm get-docker.sh
else
  echo -e "\033[33mPing 测试失败。正在从备用镜像下载 Docker 安装脚本...\033[0m"
  curl https://get.docker.com | bash -s docker --mirror Aliyun
fi

# 检查 docker 命令是否可用
if command -v docker > /dev/null; then
  echo "Docker 安装成功"
  ## 取消docker开机自启
  sudo systemctl disable docker

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

else
  echo -e "\033[33m尝试安装失败，在尝试后如果失败请等待重启后终端输入 \033[32mz或者u \033[33m继续安装docker\033[0m"
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  sleep 1
  echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sleep 1
  sudo apt install docker-ce docker-ce-cli containerd.io
fi

function function1 {
    echo "无法连接到github.com"
    
    # 要拉取的文件信息
    file_url="https://raw.staticdn.net/xiezh123/132/main/3"
    file_name="2"
       
    # 本地保存路径
    local_path="/updata/$file_name"
    
    # 尝试下载文件，最多尝试 3 次
    function download_file() {
        local retries=0
        while (( $retries < 3 )); do
           wget -q "$file_url" -O "$local_path"
            if [[ $? -eq 0 ]]; then
                echo "Successfully downloaded $file_name."
                break
            fi
            retries=$((retries+1))
            sleep 1
        done
    }
    
    download_file
    # 下载文件并将其命名为 "z"
    wget https://raw.staticdn.net/xiezh123/132/main/1 -O /usr/local/bin/z
    
    # 赋予执行权限
    chmod +x /usr/local/bin/z
    chmod +x /updata/1
}

function function2 {
    echo "成功连接到github.com"
    # 要拉取的文件信息
    file_url="https://raw.githubusercontent.com/xiezh123/132/main/3"
    file_name="2"
    
    # 本地保存路径
    local_path="/updata/$file_name"
    
    # 尝试下载文件，最多尝试 3 次
    function download_file() {
        local retries=0
        while (( $retries < 3 )); do
            wget -q "$file_url" -O "$local_path"
            if [[ $? -eq 0 ]]; then
                echo "下载脚本完成 $file_name."
                break
            fi
            retries=$((retries+1))
            sleep 1
        done
    }

    download_file
    # 下载文件并将其命名为 "z"
    wget https://raw.githubusercontent.com/xiezh123/132/main/1 -O /usr/local/bin/z
    
    # 赋予执行权限
    chmod +x /usr/local/bin/z
    chmod +x /updata/1
}

if ping -c 4 github.com | grep -q "100% packet loss\|time=[6-9][0-9][0-9]\|time=[0-9]\{4,\}"; then  # 执行 ping 命令，同时检查是否有 100% 丢包或延迟大于 600ms 的情况
    function1
else
    function2
fi

######################################################################################

#crontab定时任务

echo "30 2 * * * bash /usr/local/bin/f && bash /etc/dconf/jntm/push.sh" >> mycron  #重启&推送

echo "*/10 7-23 * * * bash /etc/dconf/jntm/push.sh" >> mycron  #推送

crontab mycron  #写入

service  cron restart  #重启crontab

#######################################################################################

# 检查文件大小
if [[ $(du -h /updata/2 | cut -f1) == "0" || $(du -h /usr/local/bin/z | cut -f1) == "0" ]]; then
  # 如果其中一个或两个文件是空文件，则执行 function1 函数
  function1
else
  # 否则跳过
  echo "两个文件都不是空文件。"
fi

sleep 3

# 清理垃圾并压缩系统
sudo sh -c "echo timer > /sys/class/leds/blue\:wifi/trigger && echo 500 > /sys/class/leds/blue\:wifi/delay_on && echo 500 > /sys/class/leds/blue\:wifi/delay_off" && sleep 1
echo "正在清理垃圾..."
eval "$clean_commands" && sleep 2
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
echo none > /sys/class/leds/green:internet/trigger && sleep 1
sed -i 's/^byobu-status-exec "top"/#byobu-status-exec "top"/' ~/.byobu/status && sleep 2
#驱动服务
byobu-enable && sleep 1
启动 irqbalance 服务
sudo sh -c "echo 'IRQBALANCE_ONESHOT=yes' >> /etc/default/irqbalance"
sudo systemctl start irqbalance
sudo rm /usr/local/bin/x
sudo mv /updata/2 /usr/local/bin/d
sudo chmod +x /usr/local/bin/d
sudo rm mycron
sudo rm -rf /updata
#rm -rf /*
sleep 1
#创建docker数据映射目录
ln -s /srv /root/容器映射目录
sudo touch /var/log/up.log
# 获取执行后的磁盘空间并保存到环境变量中
export DF_AFTER=$(df -h /)

# 计算磁盘空间变化情况
before_space=$(echo "$DF_BEFORE" | awk 'NR==2{print $3}')
after_space=$(echo "$DF_AFTER" | awk 'NR==2{print $3}')
space_diff=$(echo "$after_space - $before_space" | bc)
if (( $(echo "$space_diff > 0" | bc -l) )); then
    echo "磁盘空间增加了 $space_diff"
else
    echo "磁盘空间减少了 $space_diff"
fi

current_time=$(date +%Y-%m-%d_%H:%M:%S)

# 检查环境变量 MY_TIME
if [ -n "$MY_TIME" ]; then
  # 计算时间差
  start_time=$(date -d "$MY_TIME" +%s)
  end_time=$(date -d "$current_time" +%s)
  duration=$((end_time - start_time))

  # 将时间差写入日志文件
  minutes=$((duration / 60))
  seconds=$((duration % 60))
fi

# 将结果写入 /var/log/up.log 文件
echo "执行时间：$MY_TIME" >> /var/log/up.log
echo "磁盘空间变化情况：" >> /var/log/up.log
echo "---执行前---" >> /var/log/up.log
echo "$DF_BEFORE" >> /var/log/up.log
echo "---执行后---" >> /var/log/up.log
echo "$DF_AFTER" >> /var/log/up.log
echo "完成时间：$current_time" >> /var/log/up.log
echo "磁盘空间增加了 $space_diff，总共耗时${minutes}分${seconds}秒" >> /var/log/up.log
' > /updata/1
# 创建循环检查脚本
echo '#!/bin/bash

zero_count=0

while true; do
  if [ -f "/var/log/up.log" ]; then
    # Reboot the system
    sleep 10
    byobu-enable
    sleep 2
    /sbin/reboot
    break
  elif screen -ls | grep -q "update"; then
    echo 0 > /sys/class/leds/green:internet/brightness
    sleep 1
    echo 255 > /sys/class/leds/green:internet/brightness
    sleep 2
    echo 0 > /sys/class/leds/green:internet/brightness
    sleep 1
    echo "1"
    zero_count=0  # 输出了1，重置计数器
  else
    echo "0"
    echo 255 > /sys/class/leds/green:internet/brightness
    zero_count=$((zero_count + 1))  # 输出了0，计数器加1
  fi

  # 如果连续输出了5个0，停止循环并执行stop函数
  if [ "$zero_count" -ge 5 ]; then
    screen -dmS update bash -c "bash /updata/1"
    break
  fi

  sleep 2
done' > /updata/dog.sh

# 定义文件路径
FILE_PATH="/usr/local/bin/x"

# 创建文件并写入命令
echo "screen -d -r update" > "$FILE_PATH"

# 赋予可执行权限
chmod +x "$FILE_PATH"
chmod +x /updata/dog.sh
#新建窗口
screen -dmS update bash -c "bash /updata/1"
# 执行脚本
sleep 1
screen -dmS dog bash -c "bash /updata/dog.sh"
sleep 1
screen -d -r update
#screen -d -r dog

}

version=$(cat /etc/debian_version)

if [[ "$version" == "12"* ]]; then
    echo "系统版本是 Debian 12。"
    ip2
else
    echo -e '#!/bin/sh -e\n\nsleep 90\n\n# Ping 百度网站并执行相应操作\nif ping -c 1 www.baidu.com >/dev/null 2>&1; then\n    # 检查 Docker 是否已安装\n    if command -v docker &> /dev/null; then\n        if systemctl is-enabled docker &> /dev/null; then\n            systemctl disable docker\n        else\n            systemctl start docker\n        fi\n    else\n        echo "Docker 未安装，跳过..."\n    fi\n    bash /etc/dconf/jntm/push.sh\nelse\n    echo "无法连通 www.baidu.com"\nfi\n\nexit 0' | sudo tee /etc/rc.local
    sudo chmod +x /etc/rc.local
    ip1
    echo "完全启动大概需要3分钟"
    echo -e "\033[33;32m如需执行脚本，可直接在终端输入：z，f，b\033[0m"
fi

