#!/usr/bin/env bash

CONF_KMSG='/usr/local/bin/conf-kmsg.sh'
SERVICE_KMSG='/etc/systemd/system/conf-kmsg.service'
REQUIRED='gpg curl apt-transport-https'
PKGS='helm'
INSTALL=false
GR=$(tput setaf 2)
CY=$(tput setaf 6)
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

for pkg in $PKGS $REQUIRED; do
    status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
    if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
    INSTALL=true
    break
fi
done

if [[ "${uninstall}" == 'true' ]]; then
    echo "${GR}Uninstalling...${NC}"
    sudo apt remove -y --purge $PKGS &>/dev/null
    sudo apt autoremove -y &>/dev/null
    sudo rm -rf "$CONF_KMSG" "$SERVICE_KMSG" /usr/share/keyrings/helm.gpg /etc/apt/sources.list.d/helm-stable-debian.list
    systemctl daemon-reload
    sudo apt update &>/dev/null
elif [ -f "$CONF_KMSG" ] && [ -x "$CONF_KMSG" ] && [ "$status" = installed ]; then
    echo "${GR}Setup already done.${NC}"
else
    echo "${GR}Setup requirement for k3s...${NC}"
fi

if [ "${uninstall}" == 'true' ] && [ ! -f "$CONF_KMSG" ] && [ ! -f "$SERVICE_KMSG" ]; then
    echo "${GR}Uninstall done please reboot.${NC}"
fi

if [ "$INSTALL" ] && [ "${uninstall}" != 'true' ] && [ ! "$status" = installed ]; then
    echo "${CY}Install dependencies...${NC}"
    sudo apt install -y $REQUIRED &>/dev/null   
    sudo curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt update &>/dev/null
    sudo apt install -y $PKGS &>/dev/null
fi

if [ ! -f "$CONF_KMSG" ] && [ "${uninstall}" != 'true' ]; then
    echo "${CY}Create conf-kmsg.sh -> $CONF_KMSG${NC}"
    cat > "$CONF_KMSG" <<EOF
#!/bin/sh -e

if [ ! -e /dev/kmsg ]; then
    ln -s /dev/console /dev/kmsg
fi

mount --make-rshared /
EOF
fi

if [ ! -x "$CONF_KMSG" ] && [ "${uninstall}" != 'true' ]; then
    echo "${CY}Make conf-kmsg.sh executable...${NC}"
    chmod +x "$CONF_KMSG"

fi

if [ ! -f "$SERVICE_KMSG" ] && [ "${uninstall}" != 'true' ]; then
    echo "${CY}Create conf-kmsg.service -> $SERVICE_KMSG${NC}"
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
    echo "${GR}Setup done please reboot.${NC}"
fi