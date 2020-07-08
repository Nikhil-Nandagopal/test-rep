#!/bin/bash
declare -A osInfo;

mkdir template
cd template
wget https://raw.githubusercontent.com/Nikhil-Nandagopal/test-rep/master/application-prod.properties.sh
wget https://raw.githubusercontent.com/Nikhil-Nandagopal/test-rep/master/docker-compose.yml.sh
wget https://raw.githubusercontent.com/Nikhil-Nandagopal/test-rep/master/init-letsencrypt.sh.sh
wget https://raw.githubusercontent.com/Nikhil-Nandagopal/test-rep/master/mongo-init.js.sh
wget https://raw.githubusercontent.com/Nikhil-Nandagopal/test-rep/master/opa-config.yml.sh
wget https://raw.githubusercontent.com/Nikhil-Nandagopal/test-rep/master/nginx_app.conf.sh
cd ..

osInfo[/etc/debian_version]="apt-get"
osInfo[/etc/centos-release]="yum"
osInfo[/etc/redhat-release]="yum"

read -p 'install_dir [/root/deploy/]: ' install_dir
install_dir=${install_dir:-/root/deploy/}
read -p 'mongo_host [mongo]: ' mongo_host
mongo_host=${mongo_host:-mongo}
read -p 'mongo_root_user: ' mongo_root_user
read -sp 'mongo_root_pass: ' mongo_root_pass
echo ""
read -p 'mongo_database [appsmith]: ' mongo_database
mongo_database=${mongo_database:-appsmith}

# Validating domain
while :
do
    status=""
    read -p 'custom_domain: ' custom_domain
    if [ $custom_domain ];then
        status=1
    else
        status=0
    fi

    case $status in
          1)
              echo "Domain is valid."
              break
              ;;
          *)
              echo "Please provide a valid domain."
              ;;
    esac
done
echo

# Checking OS and assiging package manager
desired_os=0
echo "Assiging package manager"
for f in ${!osInfo[@]}
do
    if [[ -f $f ]];then
        package_manager=${osInfo[$f]}
	echo $package_manager
	desired_os=1
    fi
done

if [[ desired_os -eq 0 ]];then
	echo "Desired OS(Ubuntu | RedHat | CentOS) is not found. Please run this script on Ubuntu | RedHat | CentOS.\nExiting now..."
	exit
fi

# Role - Base
echo "kill automatic updating script, if any"
pkill --full /usr/bin/unattended-upgrade

echo "apt update"
sudo ${package_manager} -y update

echo "Upgrade all packages to the latest version"
sudo ${package_manager} -y upgrade

echo "Install ntp"
sudo ${package_manager} -y install ntp bc python3-pip

echo "Install the boto package"
pip3 install boto3

echo "apt update"
sudo ${package_manager} -y update

# Need to set usr limit for files 

# Role - Docker
echo "Checking and installing Docker along with it's dependencies"
sudo ${package_manager} -y install apt-transport-https ca-certificates curl software-properties-common virtualenv python3-setuptools

if [[ $package_manager -eq apt-get ]];then
    echo "++++++++++++++++++++"
    echo "Setting up docker repos"	
    sudo $package_manager update
    
    sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
else
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
fi

sudo ${package_manager} -y update
echo "++++++++++Installing docker+++++++++++"
sudo ${package_manager} -y install docker-ce docker-ce-cli containerd.io

echo "++++++++++Installing Docker-compose++++++"
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

pip3 install docker


# Role - Mongo
echo "Role - Mongo"
if [[ $package_manager -eq apt-get ]];then
    echo "++++++++++++++++++++"
    echo "Setting up mongo DB"
    sudo ${package_manager} -y install gnupg
    wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
    sudo ${package_manager} update
    sudo ${package_manager} install -y mongodb-org
else
    touch /etc/yum.repos.d/mongodb-org-4.2.repo

    echo '[mongodb-org-4.2]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
    gpgcheck=1
    enabled=1
    gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc' > /etc/yum.repos.d/mongodb-org-4.2.repo

    sudo ${package_manager} update
    sudo ${package_manager} install -y mongodb-org

fi

# Role - folders
#parent_directory="."
ubuntu="/etc/debian_version"
centos="/etc/centos-release"
redhat="/etc/redhat-release"

if [ -f $ubuntu ]
then
    user="ubuntu"
    group="ubuntu"
elif [ -f $centos ]
then
   user="centos"
   group="centos"
elif [ -f $redhat ]
then
   user="redhat"
   group="redhat"
fi

for directory_name in nginx certbot mongo/db opa/config appsmith-server/config
do
  if [ -d "$install_dir/data/$directory_name" ]
  then
    echo "Directory already exists"
  else
    mkdir -p "$install_dir/data/$directory_name"
    #chown -R $user:$group $parent_directory/data
  fi
done

${package_manager} install -y moreutils
public_ip=`ifdata -pa eth0`

echo $public_ip

echo "++++++++++++"
echo "Building custom template"
. ./template/nginx_app.conf.sh
. ./template/docker-compose.yml.sh
. ./template/application-prod.properties.sh
. ./template/mongo-init.js.sh
. ./template/opa-config.yml.sh
. ./template/init-letsencrypt.sh.sh
chmod 0755 init-letsencrypt.sh

declare -A fileInfo

fileInfo[/data/nginx/app.conf]="nginx_app.conf"
fileInfo[/docker-compose.yml]="docker-compose.yml"
fileInfo[/data/appsmith-server/config/application-prod.properties]="application-prod.properties"
fileInfo[/data/mongo/init.js]="mongo-init.js"
fileInfo[/data/opa/config/config.yml]="opa-config.yml"
fileInfo[/init-letsencrypt.sh]="init-letsencrypt.sh"

for f in ${!fileInfo[@]}
do

    if [ -f $install_dir$f ]
    then
        echo "File already exist."
        read -p "File $f already exist. Would you like to replace it? [Y]: " value

        if [ $value == "Y" -o $value == "y" -o $value == "yes" -o $value == "Yes" ]
        then
            mv -f  ${fileInfo[$f]} $install_dir$f 
            echo "File $install_dir$f replaced succeffuly!"
        else
            echo "You choose not to replae existing file: $install_dir$f"
	    rm -rf ${fileInfo[$f]}
	    echo "File ${fileInfo[$f]} removed from source directory."
        fi
    else
        mv -f ${fileInfo[$f]} $install_dir$f
    fi

done


echo "++++++++++++++++++++"
docker pull appsmith/appsmith-server
echo "Running init-letsencrypt.sh...."
cd $install_dir
sudo bash $install_dir/init-letsencrypt.sh
sudo docker-compose -f docker-compose.yml up -d
