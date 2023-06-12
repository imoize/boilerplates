#!/usr/bin/env bash

CONF_KMSG='/usr/local/bin/conf-kmsg.sh'
SERVICE_KMSG='/etc/systemd/system/conf-kmsg.service'
GPG='gpg'
PKGS='curl apt-transport-https curl helm'
INSTALL=false
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6)
NC=$(tput sgr 0)

usage() {
    helpify "-r, --remove, -u, --uninstall" "" "Remove all installed" ""
}

while [[ $# -gt 0 ]]; do

case "${1}" in
    -r|--remove|-u|-uninstall)
    uninstall='true'; shift ;;
esac
done

for pkg in $PKGS $GPG; do
    status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
    if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
    INSTALL=true
    break
fi
done

if [[ "${uninstall}" == 'true' ]]; then
    echo "${GREEN}Uninstalling...${NC}"
    sudo apt remove -y --purge $PKGS $GPG &>/dev/null
    sudo apt autoremove -y &>/dev/null
    sudo rm -rf "$CONF_KMSG" "$SERVICE_KMSG" /usr/share/keyrings/helm.gpg /etc/apt/sources.list.d/helm-stable-debian.list
    systemctl daemon-reload
    sudo apt update &>/dev/null
elif [ -f "$CONF_KMSG" ] && [ -x "$CONF_KMSG" ] && [ "$status" = installed ]; then
    echo "${GREEN}Setup already done.${NC}"
else
    echo "${GREEN}Setup requirement for k3s...${NC}"
fi

if [ "${uninstall}" == 'true' ] && [ ! -f "$CONF_KMSG" ] && [ ! -f "$SERVICE_KMSG" ]; then
    echo "${GREEN}Uninstall done please reboot.${NC}"
fi

if [ "$INSTALL" ] && [ "${uninstall}" != 'true' ] && [ ! "$status" = installed ]; then
    echo "${CYAN}Install dependencies...${NC}"
    sudo apt install -y $GPG &>/dev/null   
    sudo wget -qO- https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt update &>/dev/null
    sudo apt install -y $PKGS &>/dev/null
fi

if [ ! -f "$CONF_KMSG" ] && [ "${uninstall}" != 'true' ]; then
    echo "${CYAN}Create conf-kmsg.sh in /usr/local/bin/...${NC}"
    cat > "$CONF_KMSG" <<EOF
#!/bin/sh -e

if [ ! -e /dev/kmsg ]; then
    ln -s /dev/console /dev/kmsg
fi

mount --make-rshared /
EOF
fi

if [ ! -x "$CONF_KMSG" ] && [ "${uninstall}" != 'true' ]; then
    echo "${CYAN}Make conf-kmsg.sh executable...${NC}"
    chmod +x "$CONF_KMSG"
        
fi

if [ ! -f "$SERVICE_KMSG" ] && [ "${uninstall}" != 'true' ]; then
    echo "${CYAN}Create conf-kmsg.service in /etc/systemd/system/...${NC}"
    cat > "$SERVICE_KMSG" <<EOF
[Unit]
Description=Make sure /dev/kmsg exists
[Service]
Type=simple
RemainAfterExit=yes
ExecStart=/usr/local/bin/conf-kmsg.sh
TimeoutStartSec=0
[Install]
WantedBy=default.target
EOF
	systemctl daemon-reload
    systemctl enable --now conf-kmsg
    echo "${GREEN}Setup done please reboot.${NC}"
fi