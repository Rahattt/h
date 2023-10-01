source ../common/utils.sh

latest=$(get_release_version hiddify-sing-box)

if [ "$(cat VERSION)" != "$latest" ]; then
    pkg=$(dpkg --print-architecture)

    curl -Lo sb.zip "https://github.com/hiddify/hiddify-sing-box/releases/download/$latest/sing-box-linux-$pkg.zip"

    unzip -o sb.zip
    cp -f sing-box-*/sing-box .
    echo "$latest" >VERSION
    rm -r sb.zip sing-box-*
    chown root:root sing-box
    chmod +x sing-box
    ln -sf /opt/hiddify-server/singbox/sing-box /usr/bin/sing-box
    rm geosite.db
fi
