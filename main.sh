#!/bin/bash

if ! command -v zenity &> /dev/null
then
    function get_distro() {
        if [[ -f /etc/os-release ]]
        then
            source /etc/os-release
            echo $ID
        else
            uname
        fi
    }
    case $(get_distro) in 
        fedora)
            sudo dnf install zenity
            ;;
        ubuntu)
            sudo apt-get -y install zenity
            ;;
        debian)
            sudo apt-get -y install zenity
            ;;
    esac    
fi

if ! command -v docker &> /dev/null
then
    zenity --question \
        --title "DocGUI" \
        --text "Docker is not installed. Do you want to install it?"
        case $? in
            0)
            curl -sSL https://get.docker.com/ | sh
            sudo usermod -aG docker $USER
            newgrp docker
            ;;
            1)
            zenity --warning --title="Docker not Installed" --text="You need Docker to be installed to create containers."
            exit
            ;;
        esac 
fi

maindata=$(zenity --forms --title="DocGUI" --text="Run Container" \
    --add-entry="Image" \
    --add-entry="Container Name" \
    --add-entry="Host Port" \
    --add-entry="Container Port" \
    --add-entry="Volume" 
)
[[ "$?" != "0" ]] && exit 1

image=$(echo $maindata | awk 'BEGIN {FS="|" } { print $1 }')
name=$(echo $maindata | awk 'BEGIN {FS="|" } { print $2 }')
host_port=$(echo $maindata | awk 'BEGIN {FS="|" } { print $3 }')
container_port=$(echo $maindata | awk 'BEGIN {FS="|" } { print $4 }')
volume=$(echo $maindata | awk 'BEGIN {FS="|" } { print $5 }')

if [ -z "$name" ]
then
      container_name=""
else
      container_name="--name ${name}"
fi

options=$(zenity --list --checklist \
     --title 'Container Options' \
     --text 'Select the Options' \
     --column 'Select' \
     --column 'Options' TRUE "Detached Mode" FALSE "Delete Container after stopping"
)
[[ "$?" != "0" ]] && exit 1

if [[ $options == "Detached Mode|Delete Container after stopping" ]]; then
    detached="-d"
    removal="--rm"
elif [[ $options == "Detached Mode" ]]; then
    detached="-d"
elif [[ $options == "Delete Container after stopping" ]]; then
    removal="--rm"
fi 

tmpfile=$(mktemp)

docker run ${removal} ${detached} ${container_name} -p ${host_port}:${container_port} ${image} | tee >(zenity --title="Creating Container" \
--progress --pulsate --text="Creating Container..." \
--auto-kill --auto-close) >${tmpfile}
 
zenity --title "${name} Details" \
     --text-info --filename="${tmpfile}"