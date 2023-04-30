#!/bin/bash
cd $( dirname -- "$0"; )
echo "we are going to install :)"
export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
#        exit 1

fi

source ./common/ticktick.sh

function set_config_from_hpanel(){

        hiddify=`cd hiddify-panel;python3 -m hiddifypanel all-configs`
        if [[ $? != 0 ]];then
                echo "Exception in Hiddify Panel. Please send the log to hiddify@gmail.com"
                exit 1
        fi
        tickParse  "$hiddify"
        tickVars

        function setenv () {
                echo $1=$2
                export $1="$2"
        }


        setenv GITHUB_USER hiddify
        setenv GITHUB_REPOSITORY hiddify-config
        setenv GITHUB_BRANCH_OR_TAG main
        
        setenv TLS_PORTS ``hconfigs[tls_ports]``
        setenv HTTP_PORTS ``hconfigs[http_ports]``
        setenv FIRST_SETUP ``hconfigs[first_setup]``
        setenv DB_VERSION ``hconfigs[db_version]``

        TELEGRAM_SECRET=``hconfigs[shared_secret]``

        setenv TELEGRAM_USER_SECRET ${TELEGRAM_SECRET//-/}

        setenv BASE_PROXY_PATH ``hconfigs[proxy_path]``
        setenv TELEGRAM_LIB ``hconfigs[telegram_lib]``
        setenv ADMIN_SECRET ``hconfigs[admin_secret]``

        setenv ENABLE_V2RAY ``hconfigs[v2ray_enable]``

        setenv ENABLE_SS ``hconfigs[ssfaketls_enable]``
        setenv SS_FAKE_TLS_DOMAIN ``hconfigs[ssfaketls_fakedomain]``
        
        setenv DECOY_DOMAIN ``hconfigs[decoy_domain]``

        setenv SHARED_SECRET ``hconfigs[shared_secret]``
        

        setenv ENABLE_TELEGRAM ``hconfigs[telegram_enable]``
        setenv TELEGRAM_FAKE_TLS_DOMAIN ``hconfigs[telegram_fakedomain]``
        setenv TELEGRAM_AD_TAG ``hconfigs[telegram_adtag]``

        setenv ENABLE_SHADOW_TLS ``hconfigs[shadowtls_enable]``
        setenv SHADOWTLS_FAKEDOMAIN ``hconfigs[shadowtls_fakedomain]``

        setenv FAKE_CDN_DOMAIN ``hconfigs[fake_cdn_domain]``
        c=``hconfigs[country]``
        if [[ "$c" == "" ]];then 
                c="ir"
        fi
        setenv COUNTRY  $c
        

        setenv ENABLE_SSR ``hconfigs[ssr_enable]``
        setenv SSR_FAKEDOMAIN ``hconfigs[ssr_fakedomain]``

        setenv ENABLE_VMESS ``hconfigs[vmess_enable]``
        setenv ENABLE_MONITORING false
        setenv ENABLE_FIREWALL ``hconfigs[firewall]``
        # setenv ENABLE_NETDATA ``hconfigs[netdata]``
        setenv ENABLE_HTTP_PROXY ``hconfigs[http_proxy]`` # UNSAFE to enable, use proxy also in unencrypted 80 port
        setenv ALLOW_ALL_SNI_TO_USE_PROXY ``hconfigs[allow_invalid_sni]`` #UNSAFE to enable, true=only MAIN domain is allowed to use proxy
        setenv ENABLE_AUTO_UPDATE ``hconfigs[auto_update]``
        setenv ENABLE_TROJAN_GO false
        setenv ENABLE_SPEED_TEST ``hconfigs[speed_test]``
        setenv BLOCK_IR_SITES ``hconfigs[block_iran_sites]``
        setenv ONLY_IPV4 ``hconfigs[only_ipv4]``
        setenv PATH_VMESS ``hconfigs[path_vmess]``
        setenv PATH_VLESS ``hconfigs[path_vless]``
        setenv PATH_SS ``hconfigs[path_v2ray]``
        setenv PATH_TROJAN ``hconfigs[path_trojan]``
        setenv PATH_TCP ``hconfigs[path_tcp]``
        setenv PATH_WS ``hconfigs[path_ws]``
        setenv PATH_GRPC ``hconfigs[path_grpc]``

        setenv REALITY_SERVER_NAMES ``hconfigs[reality_server_names]``
        setenv REALITY_FALLBACK_DOMAIN ``hconfigs[reality_fallback_domain]``
        setenv REALITY_PRIVATE_KEY ``hconfigs[reality_private_key]``
        setenv REALITY_SHORT_IDS ``hconfigs[reality_short_ids]``

        setenv SERVER_IP `curl --connect-timeout 1 -s https://v4.ident.me/`
        setenv SERVER_IPv6 `curl  --connect-timeout 1 -s https://v6.ident.me/`

        function get () {
                group=$1
                index=`printf "%012d" "$2"` 
                member=$3
                
                var="__tick_data_${group}_${index}_${member}";
                echo ${!var}
        }

        MAIN_DOMAIN=
        for i in $(seq 0 ``domains.length()``); do
                domain=$(get domains $i domain)
                mode=$(get domains $i mode)
                if [ "$mode"  == "direct" ] || [ "$mode"  == "cdn" ] || [ "$mode"  == "relay" ] || [ "$mode"  == "auto_cdn_ip" ];then
                        MAIN_DOMAIN="$domain;$MAIN_DOMAIN"
                fi
                if [ "$mode"  = "ss_faketls" ];then
                        setenv SS_FAKE_TLS_DOMAIN $domain
                fi
                if [ "$mode"  = "telegram_faketls" ];then
                        setenv TELEGRAM_FAKE_TLS_DOMAIN $domain
                fi

                if [ "$mode"  = "fake_cdn" ];then
                        setenv FAKE_CDN_DOMAIN $domain
                fi
        done

        setenv MAIN_DOMAIN $MAIN_DOMAIN

        USER_SECRET=
        for i in $(seq 0 ``users.length()``); do
        uuid=$(get users $i uuid)
        secret=${uuid//-/}
        if [ "$secret" != "" ];then
                USER_SECRET="$secret;$USER_SECRET"
        fi
        done


        setenv USER_SECRET $USER_SECRET
}
function check_req(){
        
   for req in hexdump dig curl git;do
        which $req
        if [[ "$?" != 0 ]];then
                apt update
                apt install -y dnsutils bsdmainutils curl git
                break
        fi
   done
   
}

function runsh() {          
        command=$1
        if [[ $3 == "false" ]];then
                command=uninstall.sh
        fi
        pushd $2 >>/dev/null 
        # if [[ $? != 0]];then
        #         echo "$2 not found"
        # fi
        if [[ $? == 0 && -f $command ]];then
                echo "==========================================================="
                echo "===$command $2"
                echo "==========================================================="        
                bash $command
        fi
        popd >>/dev/null
}

function do_for_all() {
        #cd /opt/$GITHUB_REPOSITORY
        bash common/replace_variables.sh
        systemctl daemon-reload
        if [ "$MODE" != "apply_users" ];then
                runsh $1.sh common
                #runsh $1.sh certbot
                runsh $1.sh acme.sh
                runsh $1.sh nginx
                # runsh $1.sh sniproxy
                runsh $1.sh haproxy
                runsh $1.sh other/speedtest
                runsh $1.sh other/telegram $ENABLE_TELEGRAM
                runsh $1.sh other/ssfaketls $ENABLE_SS
                runsh $1.sh other/v2ray $ENABLE_V2RAY
                runsh $1.sh other/shadowtls $ENABLE_SHADOWTLS
                runsh $1.sh other/clash-server $ENABLE_TUIC
                # runsh $1.sh deprecated/vmess $ENABLE_VMESS
                # runsh uninstall.sh deprecated/vmess
                # runsh $1.sh deprecated/monitoring $ENABLE_MONITORING
                # runsh uninstall.sh deprecated/monitoring
                # runsh $1.sh other/netdata false $ENABLE_NETDATA
                # runsh $1.sh deprecated/trojan-go  $ENABLE_TROJAN_GO
        fi

        runsh $1.sh xray
        
}


function main() {
    set -e

    export MODE="${1:-}"

    if [[ $MODE != "apply_users" ]]; then
        curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash -s -- install --version 1.8.1
        runsh install.sh hiddify-panel
    fi

    set_config_from_hpanel

    if [[ -z $DB_VERSION ]]; then
        printf "ERROR!!!! There is an error in the installation of python panel. Exit....\n"
        exit 1
    fi

    case $MODE in
        install-docker)
            printf "install-docker\n"
            export DO_NOT_RUN=true
            export ENABLE_SS=true
            export ENABLE_TELEGRAM=true
            export ENABLE_FIREWALL=false
            export ENABLE_AUTO_UPDATE=false
            export ONLY_IPV4=false
            ;;
        apply_users)
            export DO_NOT_INSTALL=true
            ;;
    esac

    if [[ -z "$DO_NOT_INSTALL" || "$DO_NOT_INSTALL" == false ]]; then
        do_for_all install
        systemctl daemon-reload
    fi

    if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]]; then
        do_for_all run
        if [[ $MODE != "apply_users" ]]; then        
            printf "\n\n"
            bash status.sh
            printf "===========================================================\n"
            printf "Finished! Thank you for helping Iranians to skip filternet.\n"
            printf "Please open the following link in the browser for client setup:\n"
            cat use-link
        fi
    fi

    for service in hiddify-xray hiddify-nginx haproxy; do
        if systemctl is-active --quiet "${service##*/}"; then
            continue
        else
            printf "An important service %s is not working yet\n" "$service"
            sleep 5
            printf "Checking again...\n"
            if systemctl is-active --quiet "${service##*/}"; then
                continue
            else
                printf "An important service %s is not working again\n" "$service"
                printf "Installation Failed!\n"
                exit 32
            fi
        fi         
    done

    printf "---------------------Finished!------------------------\n"
    if [[ $MODE != "apply_users" ]]; then
        systemctl restart hiddify-panel
    fi
    systemctl start hiddify-panel
}
     

mkdir -p log/system/
main $@|& tee log/system/0-install.log
