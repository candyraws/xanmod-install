# xanmod-install
xanmod内核一键安装脚本
# 依赖
```bash
apt install screen curl jq -y
```
# 快速入门
```bash
screen
bash <(curl -Ss "https://raw.githubusercontent.com/candyraws/xanmod-install/main/xanmod.sh")
```
# 碎碎念
第一次使用时会卸载原内核，需要手动选择no，后续可以全程无人值守（建议`nohup`或者`screen`运行，防止因ssh意外中断造成不可预期的后果），再次执行脚本即为检查更新操作

仅在debian系统上进行过测试，理论上deb系的发行版都支持（如ubuntu等），具体自行测试。

不推荐在生产环境下使用

安装成功后默认自动重启，开启BBR+FQ加速，无需额外操作

# 验证BBR是否已经成功开启
```bash
cat /proc/sys/net/ipv4/tcp_congestion_control ;sysctl net.core.default_qdisc
```
