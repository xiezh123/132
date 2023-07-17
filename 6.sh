#!/bin/bash
#code by Aimt#

#将自己的token复制到这里 eg.MyToken="123456xxxx"
MyToken=""

cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
memory_usage=$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }')
network_traffic=$(/sbin/ifconfig enx00e04c360017 | awk '/RX p/{print $6,$7}')

push_body="服务器{$(hostname)}状态信息：\n\n"
push_body+="公网IP：$(curl -s cip.cc | awk 'NR==1{printf $3}')\n"
push_body+="局域网IP：$(hostname -I | awk '{print $1}')\n"
push_body+="USB网卡IP：$(ifconfig usb0 | awk '/inet /{print $2}')\n"
push_body+="CPU温度：$(cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000}')℃\n"
push_body+="CPU负载：$(uptime | awk '{print $(NF-2),$(NF-1),$(NF)}')\n"
push_body+="CPU使用率：${cpu_usage/100}%\n"
push_body+="内存使用率：${memory_usage}\n"
push_body+="流量传输：$network_traffic\n"
push_body+="运行时间：\n$(uptime -p)"

json="{\"token\": \"$MyToken\", \"content\": \"$push_body\"}"
url="http://www.pushplus.plus/send"
curl -X GET "$url" -H "Content-Type: application/json" -d "$json"

exit 0
