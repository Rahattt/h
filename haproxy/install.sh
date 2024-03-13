source ../common/utils.sh
rm -rf *.template
if is_installed sniproxy; then
    # systemctl kill hiddify-sniproxy > /dev/null 2>&1
    systemctl stop hiddify-sniproxy >/dev/null 2>&1
    systemctl disable hiddify-sniproxy >/dev/null 2>&1
    pkill -9 sniproxy >/dev/null 2>&1
fi

if ! is_installed_package "haproxy=2.9.4"; then
    add-apt-repository -y ppa:vbernat/haproxy-2.9 || {
        sed -i 's|#!/usr/bin/python3|#!/usr/bin/python3.8|' /usr/bin/add-apt-repository
        add-apt-repository -y ppa:vbernat/haproxy-2.9
    }
    install_package haproxy=2.9*
fi
systemctl kill haproxy >/dev/null 2>&1
systemctl stop haproxy >/dev/null 2>&1
systemctl disable haproxy >/dev/null 2>&1

ln -sf $(pwd)/hiddify-haproxy.service /etc/systemd/system/hiddify-haproxy.service
systemctl enable hiddify-haproxy.service
