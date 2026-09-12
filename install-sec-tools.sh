#!/bin/bash
#
# install-sec-tools.sh
# Author: David Roddick
# git clone https://github.com/dgroddick/el-sec-tools
# Usage: ./install-sec-tools.sh
#
# Installs security research tools for Enterprise Linux.
#
set -e

ARCH=$(uname -m)
VERSION='0.1'

# Logged in user
USER=$(logname)

# terminal colours
red=$'\e[1;31m'
green=$'\e[1;32m'
yellow=$'\e[1;93m'
reset=$'\e[0m'

# status indicators
greenplus='\e[1;33m[++]\e[0m'
greenminus='\e[1;33m[--]\e[0m'
redminus='\e[1;31m[--]\e[0m'

# REPOS
CRB="codeready-builder-for-rhel-${OS_VERSION}-$(arch)-rpms"
EPEL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION}.noarch.rpm"

## Core repo packages
EL_REPO_GROUPS=("security-tools" "development" "rpm-development-tools")
DEV_TOOLS=("python3-devel" "python3-pip" "kernel-devel" "golang" "rust" "cargo" "ruby-devel")
NET_TOOLS=("tcpdump" "nmap" "netcat" "samba-client" "nfs-utils" "hping3" "fping")
MALWARE_TOOLS=("clamav" "clamav-freshclam" "rkhunter" "yara")
BINARY_TOOLS=("radare2")
GUI_TOOLS=("wireshark")

## SecLists
SECLISTS=https://github.com/danielmiessler/SecLists.git

## Extra tools
ENUM4LINUX=https://gitlab.com/kalilinux/packages/enum4linux/-/raw/kali/master/enum4linux.pl
UNIXPRIVESC=https://raw.githubusercontent.com/pentestmonkey/unix-privesc-check/refs/heads/1_x/unix-privesc-check
PSPY=https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
LINPEAS=https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh

GOBUSTER=github.com/OJ/gobuster/v3@latest
NUCLEI=github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
ASSETFINDER=github.com/tomnomnom/assetfinder@latest
AMASS=github.com/owasp-amass/amass/v4/...@master
HYDRA=https://github.com/vanhauser-thc/thc-hydra.git

SUBLIST3R=https://github.com/aboul3la/Sublist3r

MALDET=https://github.com/rfxn/linux-malware-detect.git

ATOMIC=https://github.com/redcanaryco/atomic-red-team.git
METASPLOIT=https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb

show_usage() {
    echo -e 'Configures an Enterprise Linux system for Cyber Security Research.\n'
    echo -e 'Usage: ./install-sec-tools.sh\n'
}

detect_os () {
    if [ -f /etc/os-release ]; then
        OS_NAME=$(grep '^NAME' /etc/os-release | awk -F= '{ print $2 }')
        OS_ID=$(. /etc/os-release && echo "$ID")
        OS_VERSION=$(. /etc/os-release && echo "${VERSION_ID%%.*}")
    else
        echo -e "\n${redminus} It is unlikely that you are running a supported Operating System.\n"
        return 1
    fi
}

update_system() {
    echo -e "${greenplus} Updating system"
    sudo dnf clean all && sudo dnf -y upgrade
}


enable_repos() {
    if [[ "${OS_ID}" == "rhel" ]]; then
        sudo subscription-manager repos --enable "${CRB}"
        sudo dnf install -y "${EPEL}"
    elif [[ "${OS_ID}" == "ol" ]]; then
        sudo dnf config-manager --enable ol${OS_VERSION}_codeready_builder
        sudo dnf install -y oracle-epel-release-el${OS_VERSION}
    else
        sudo dnf config-manager --set-enabled crb
        sudo dnf install -y epel-release
    fi
    
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}


base_install() {
    echo -e "${greenplus} Installing required packages ${reset}"
    sudo dnf group install -y "${EL_REPO_GROUPS[@]}"
    sudo dnf install -y "${DEV_TOOLS[@]}" "${NET_TOOLS[@]}" "${CLEANING_TOOLS[@]}" "${BINARY_TOOLS[@]}" "${GUI_TOOLS[@]}"
}


recon_tools_install() {
    echo -e "${greenplus} Installing extra recon and scanning tools... ${reset}"
    if [ ! -d "${HOME}/tools" ]; then
        mkdir "${HOME}/tools/"
    fi

    echo "export PATH=${PATH}:${HOME}/go/bin" >> ${HOME}/.profile && source ${HOME}/.profile

    echo -e "${greenplus} Installing Gobuster ${reset}"
    if [ $(which gobuster) ]; then
        echo -e "\ngobuster is already installed\n"
    else
        go install "${GOBUSTER}"
    fi

    echo -e "${greenplus} Installing Assetfinder ${reset}"
    if [ $(which assetfinder) ]; then
        echo -e "\nassetfinder is already installed\n"
    else
        go install "${ASSETFINDER}"
    fi

    echo -e "$greenplus Installing Amass ${reset}"
    if [ -f "${HOME}/go/bin/amass" ]; then
        echo -e "\nAmass is already installed\n"
    else
        go install -v "${AMASS}"
    fi

    echo -e "${greenplus} Installing Nuclei Vulnerability Scanner ${reset}"
    if [ $(which nuclei) ]; then
        echo -e "\nNuclei is already installed\n"
    else
        go install "${NUCLEI}"
    fi

    echo -e "${greenplus} Installing WPScan ${reset}"
    if [ $(which ruby) ]; then
        if [ $(which wpscan) ]; then
            echo -e "\nWPScan is already installed\n"
        else
            gem update && gem install wpscan --no-document
        fi
    fi
    
    echo -e "${greenplus} Installing Sublist3r ${reset}"
    if [ -d "${HOME}/tools/Sublist3r" ]; then
        echo -e "\nSublist3r already installed\n"
    else
        cd "${HOME}/tools/" && git clone --depth 1 "${SUBLIST3R}"
    fi

    echo -e "${greenplus} Installing SQLMap ${reset}"
    if [ $(which sqlmap) ]; then
        echo -e "\nSQLMap already installed\n"
    else
        python3 -m pip install sqlmap --user
    fi
}

seclists_install() {
    echo -e "${greenplus} Installing Seclists ${reset}"
    if [ ! -d "${HOME}/tools" ]; then
        mkdir "${HOME}/tools/"
    fi

    if [ -d "${HOME}/tools/SecLists" ]; then
        echo -e "\nSeclists already installed\n"
    else
        cd "${HOME}/tools" && git clone --depth 1 "${SECLISTS}"
    fi
}

privesc_tools_install() {
    echo -e "${greenplus} Installing Privilege Escalation tools ${reset}"
    if [ ! -d "${HOME}/tools" ]; then
        mkdir "${HOME}/tools/"
    fi

    if ! [[ -f "${HOME}/tools/linpeas.sh" ]]; then
        wget -P "${HOME}/tools/" "${LINPEAS}" && chmod +x "${HOME}/tools/linpeas.sh"
    fi

    if ! [[ -f "${HOME}/tools/pspy64" ]]; then
        wget -P "${HOME}/tools/" "${PSPY}" && chmod +x "${HOME}/tools/pspy64"
    fi

    if ! [[ -f "${HOME}/tools/enum4linux.pl" ]]; then
        wget -P "${HOME}/tools/" "${ENUM4LINUX}" && chmod +x "${HOME}/tools/enum4linux.pl"
    fi

    if ! [[ -f "${HOME}/tools/unix-privesc-check" ]]; then
        wget -P "${HOME}/tools/" "${UNIXPRIVESC}" && chmod +x "${HOME}/tools/unix-privesc-check"
    fi
}

exploit_tools_install() {
    echo -e "${greenplus} Installing Atomic Red Team ${reset}"
    if [ ! -d "${HOME}/tools" ]; then
        mkdir "${HOME}/tools/"
    fi

    if [ -d "${HOME}/tools/atomic-red-team" ]; then
        echo -e "\nAtomic Red Team already installed\n"
    else
        cd "${HOME}/tools" && git clone --depth 1 "${ATOMIC}"
    fi

    echo -e "${greenplus} Installing Metasploit ${reset}"
    if [ $(which msfconsole) ]; then
        echo -e "\nMetasploit already installed\n"
    else
        curl "${METASPLOIT}" > msfinstall && chmod 755 msfinstall && ./msfinstall
    fi
}

maldet_install() {
    echo -e "${greenplus} Installing Linux Malware Detect ${reset}"
    if [ $(which maldet) ]; then
        echo -e "\nLinux Malware Detect already installed\n"
    else
        if [ ! -d "${HOME}/src" ]; then
            mkdir "${HOME}/src/"
        fi

        if [ ! -d "${HOME}/src/linux-malware-detect" ]; then
            cd "${HOME}/src/" && git clone "${MALDET}"
        else
            cd "${HOME}/src/linux-malware-detect"
            chmod +x install.sh
            sudo ./install.sh
        fi
    fi
}

hydra_install() {
    echo -e "${greenplus} Installing Hydra ${reset}"
    HYDRA_PATH=/usr/local/bin/hydra
    if [ $(which hydra) ]; then
        echo -e "\nHydra already installed\n"
    else
        if [ ! -d "${HOME}/src" ]; then
            mkdir "${HOME}/src/"
        fi

        echo -e "${greenplus} Installing Hydra ${reset}"

        if [ -f "${HYDRA_PATH}" ]; then
            echo -e "\nHydra is already installed\n"
        else
            cd "${HOME}/src" && git clone "${HYDRA}"
            cd "${HOME}/src/thc-hydra" && ./configure && make && sudo make install
        fi
    fi
}

reversing_tools_install() {
    echo -e "${greenplus} Installing Reverse Engineering tools ${reset}"
    flatpak install -y flathub org.ghidra_sre.Ghidra
    flatpak install -y flathub re.rizin.cutter
}

web_proxy_install() {
    echo -e "${greenplus} Installing Burp Suite ${reset}"
    flatpak install -y flathub net.portswigger.BurpSuite-Community
}

nessus_install() {
    podman pull tenable/nessus:latest-oracle
    podman run -d -p 8834:8834 tenable/nessus:latest-oracle
}


echo "EL SEC TOOLS"
echo "==========="
echo "A toolkit to configure an Enterprise Linux Security Research System."

echo "Starting..."

detect_os
enable_repos
update_system
base_install
seclists_install
recon_tools_install
exploit_tools_install
maldet_install
hydra_install
reversing_tools_install
web_proxy_install
privesc_tools_install
nessus_install

echo -e "${greenplus} All done! Happy Hacking!! ${reset}"
