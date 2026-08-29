#!/bin/bash
#
# sec-tools.sh
# Author: David Roddick
# git clone https://github.com/dgroddick/sec-tools
# Usage: ./install-sec-tools.sh
#
# Installs and configures security assessment tools for Fedora Linux.
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

show_usage() {
    echo -e 'Configures a Linux system for Ethical Hacking and Cyber Security Research.\n'
    echo -e 'Usage: ./install-sec-tools.sh\n'
}

update_system() {
    echo -e "${greenplus} Updating system"
    sudo dnf -y upgrade
}

## Repo packages
REPO_GROUPS=("security-lab" "development-libs" "c-development" "rpm-development-tools" "container-management" "php")
CORE_TOOLS=("dnf-plugins-core" "python3-devel" "python3-pip" "tcpdump" "git" "kernel-devel" "golang" "rust" "cargo" "ruby-devel")
CLEANING_TOOLS=("bleachbit" "clamav" "clamav-freshclam")
RECON_TOOLS=("netcat" "ffuf" "gobuster" "assetfinder" "subfinder" "httprobe" "whatweb")

## Flatpak tools
ZAP="org.zaproxy.ZAP"

## SecLists
SECLISTS=https://github.com/danielmiessler/SecLists.git

## Extra scanning tools
GOWITNESS=github.com/sensepost/gowitness@latest
WAYBACKURLS=github.com/tomnomnom/waybackurls@latest
SUBLIST3R=https://github.com/aboul3la/Sublist3r
NUCLEI=github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

base_install() {
    update_system

    echo -e "${greenplus} Installing required packages ${reset}"
    sudo dnf group install -y "${REPO_GROUPS[@]}"
    sudo dnf install -y "${CORE_TOOLS[@]}" "${CLEANING_TOOLS[@]}" "${RECON_TOOLS[@]}"
}

webproxy_install() {
    echo -e "${greenplus} Installing Web Proxies ${reset}"

    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install flathub ${ZAP}
}

recon_tools_install() {
    echo -e "${greenplus} Installing extra recon and scanning tools... ${reset}"
    if [ ! -d "${HOME}/tools" ]; then
        mkdir "${HOME}/tools/"
    fi

    echo "export PATH=${PATH}:${HOME}/go/bin" >> ${HOME}/.profile && source ${HOME}/.profile

    echo -e "${greenplus} Installing Gowitness ${reset}"
    if [ $(which gowitness) ]; then
        echo -e "\ngowitness is already installed\n"
    else
        go install "${GOWITNESS}"
    fi


    echo -e "${greenplus} Installing Waybackurls ${reset}"
    if [ $(which waybackurls) ]; then
        echo -e "\nWaybackurls is already installed\n"
    else
        go install "${WAYBACKURLS}"
    fi

    echo -e "${greenplus} Installing Nuclei Vulnerability Scanner ${reset}"
    if [ $(which nuclei) ]; then
        echo -e "\nWaybackurls is already installed\n"
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

    echo -e "${greenplus} All done! Happy Hacking!! ${reset}"
}

seclists_install() {
    echo -e "${greenplus} Installing Seclists ${reset}"
    if [ -d "${HOME}/tools/SecLists" ]; then
        echo -e "\nSeclists already installed\n"
    else
        cd "${HOME}/tools" && git clone --depth 1 "${SECLISTS}"
    fi
}

everything_install() {
    echo -e "${greenplus} Installing everything... ${reset}"

    if [ ! -d "${HOME}/tools" ]; then
        mkdir ${HOME}/tools/
    fi
    base_install
    webproxy_install
    recon_tools_install
    seclists_install

    echo -e "${greenplus} All done! Happy Hacking!! ${reset}"
}

main() {
    echo "SEC TOOLS"
    echo "==========="
    echo "A toolkit to configure a Fedora Linux Security Research System."

    echo "What do you want to do?"
    echo "1) Install Core Security Tools"
    echo "2) Install Web Proxies"
    echo "3) Install Extra Recon Tools"
    echo "4) Install SecLists"
    echo "5) Install Everything"

    echo "> "
    
    read OPT
    case "${OPT}" in
        1)
            base_install
            ;;
        2)  
            webproxy_install
            ;;
        3)
            recon_tools_install
            ;;
        4)
            seclists_install
            ;;
        5)
            everything_install
            ;;
        *)
            show_usage
            echo "Please select a number from 1-4."
    esac
}
main
