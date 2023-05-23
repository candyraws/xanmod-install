#!/bin/bash

#apt install curl jq -y

# 删除多余内核
remove_kernel() {
  kernal_headers_all=$(dpkg -l | grep "${remove_type}" | awk '{print $2}')
  if echo "${kernal_headers_all}" | grep -q "${xanmod_version}"; then
    apt purge -y $(echo "${kernal_headers_all}" | grep -v "${xanmod_version}")
    apt-get autoremove -y
  else
    echo "(7)Not found xanmod kernel,Check please!"
    exit 7
  fi
}

# 设置需要安装的版本 如: lts,main,rt
xanmod_type="lts"

xanmod_url="https://sourceforge.net/projects/xanmod/files/releases/${xanmod_type}/"
xanmod_json=$(curl "${xanmod_url}" | grep 'net.sf.files' | awk -F' ' '{print $3}')
xanmod_version=$(echo "${xanmod_json%;}" | jq -r .[0].name)

# 检测是否成功获取到最新xanmod版本号
if [ -z "${xanmod_version}" ]; then
  echo "(1)Fail to get xanmod Version,please check url/network or install jq/curl!"
  exit 1
elif [ "$(uname -r)" == "${xanmod_version}" ]; then
  echo "(0)The xanmod kernel is latest version,exit"
  exit 0
else
  echo "Get NEW xanmod Version: ${xanmod_version}"
  mkdir xanmod && cd xanmod || exit 1
fi

xanmod_page_url="${xanmod_url}${xanmod_version}/"
xanmod_page_json=$(curl "${xanmod_page_url}" | grep 'net.sf.files' | awk -F' ' '{print $3}')
xanmod_download_list=$(echo "${xanmod_page_json%;}" | jq -r .[].download_url)

headurl="$(echo "${xanmod_download_list}" | grep 'linux-headers')"
imgurl="$(echo "${xanmod_download_list}" | grep 'linux-image')"

if [ -z "${headurl}" ]; then
  echo -e "(3)Empty headurl!\nList:\n${xanmod_download_list}"
  exit 3
elif [ -z "${imgurl}" ]; then
  echo -e "(4)Empty imgurl!\nList:\n${xanmod_download_list}"
  exit 4
else
  echo "Download kernel start."
  # download headers
  curl -Lo headers.deb "${headurl}"
  curl_status_code=${?}
  if [ ${curl_status_code} != "0" ]; then
    echo -e "(5)Fail download headers,curl status code: ${curl_status_code}"
    exit 5
  else
    echo "Success download headers"
  fi

  # download image
  curl -Lo image.deb "${imgurl}"
  curl_status_code=${?}
  if [ ${curl_status_code} != "0" ]; then
    echo "(6)Fail download images,curl status code: ${curl_status_code}"
    exit 6
  else
    echo "Success download images"
  fi

  # install
  dpkg -i image.deb headers.deb
fi

cd .. && rm -rf xanmod

# 移除linux-headers
remove_type="linux-headers"
remove_kernel

# 移除linux-image
remove_type="linux-image"
remove_kernel

# 更新引导
if [ -f "/usr/sbin/update-grub" ]; then
  /usr/sbin/update-grub
else
  apt install grub2-common -y
  update-grub
fi

# 开启BBR+FQ
sed -i -e '/net.core.default_qdisc/d' -e '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
sysctl --system

# 检查内核
ls /boot/vmlinuz-* -I rescue -1 && reboot || echo "(8)ls /boot/vmlinuz-* not found"
