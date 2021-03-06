#!/bin/sh

CUR_VER=""
NEW_VER=""
ARCH=""
VDIS="arm"
ZIPFILE="/tmp/v2ray/v2ray.zip"
V2RAY_DIR="/jffs/v2ray"

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
PROXY=`dbus get v2ray_update_proxy`

sysArch(){
    ARCH=$(uname -m)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="32"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="arm"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="arm64"
    elif [[ "$ARCH" == *"mips64le"* ]]; then
        VDIS="mips64le"
    elif [[ "$ARCH" == *"mips64"* ]]; then
        VDIS="mips64"
    elif [[ "$ARCH" == *"mipsle"* ]]; then
        VDIS="mipsle"
    elif [[ "$ARCH" == *"mips"* ]]; then
        VDIS="mips"
    elif [[ "$ARCH" == *"s390x"* ]]; then
        VDIS="s390x"
    fi
    return 0
}

quit(){
    echo "XU6J03M6"
}

downloadV2Ray(){
    rm -rf /tmp/v2ray
    mkdir -p /tmp/v2ray
    echo_date "Downloading V2Ray."
    DOWNLOAD_LINK="https://github.com/v2ray/v2ray-core/releases/download/${NEW_VER}/v2ray-linux-${VDIS}.zip"
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        echo_date "Failed to download! Please check your network or try again."
        quit
    fi
    return 0
}

installSoftware(){
    COMPONENT=$1
    if [[ -n `command -v $COMPONENT` ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        echo_date "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        quit
    fi
    echo_date "Installing $COMPONENT"
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        echo_date "Updating software repo"
        $CMD_UPDATE
        SOFTWARE_UPDATED=1
    fi

    echo_date "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        echo_date "Install ${COMPONENT} fail, please install it manually."
        quit
    fi
    return 0
}

extract(){
    echo_date "Extracting V2Ray package to /tmp/v2ray."
    mkdir -p /tmp/v2ray
    unzip $1 -d "/tmp/v2ray/"
    if [[ $? -ne 0 ]]; then
        echo_date "Extracting V2Ray faile!"
        quit
    fi
    return 0
}

# 1: new V2Ray. 0: no
getVersion(){
    CUR_VER=`$V2RAY_DIR/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
    TAG_URL="https://api.github.com/repos/v2ray/v2ray-core/releases/latest"
    NEW_VER=`curl ${PROXY} -s ${TAG_URL} --connect-timeout 10| grep 'tag_name' | cut -d\" -f4`

    if [[ $? -ne 0 ]] || [[ "$NEW_VER" == "" ]]; then
        echo_date "Network error! Please check your network or try again."
        quit
    elif [[ "$NEW_VER" != "$CUR_VER" ]];then
            return 1
    fi
    return 0

}

copyFile() {
    NAME=$1
    MANDATE=$2
    ERROR=`cp "/tmp/v2ray/v2ray-${NEW_VER}-linux-${VDIS}/${NAME}" "$V2RAY_DIR/${NAME}"`
    if [[ $? -ne 0 ]]; then
        echo_date "${ERROR}"
        if [ "$MANDATE" = true ]; then
            quit
        fi
    fi
}

installV2Ray(){
    # Install V2Ray binary to $V2RAY_DIR
    mkdir -p $V2RAY_DIR
    copyFile v2ray true
    makeExecutable v2ray
    copyFile v2ctl false
    makeExecutable v2ctl
    copyFile geoip.dat false
    copyFile geosite.dat false
    return 0
}

makeExecutable() {
    chmod +x "$V2RAY_DIR/$1"
}

main() {
    # dowload via network and extract
    echo_date "Check v2ray version, proxy ${PROXY}"
    getVersion
    if [[ $? == 0 ]]; then
        echo_date "Lastest version ${NEW_VER} is already installed."
        quit
    else
        echo_date "Installing V2Ray ${NEW_VER} on ${ARCH}"
        downloadV2Ray
        extract ${ZIPFILE}
    fi

    installV2Ray
    echo_date "V2Ray ${NEW_VER} is installed."
    rm -rf /tmp/v2ray
    return 0
}

echo > /tmp/v2ray_status.log
main > /tmp/v2ray_status.log
echo "O(∩ _∩ )O~" >> /tmp/v2ray_status.log
quit>> /tmp/v2ray_status.log
