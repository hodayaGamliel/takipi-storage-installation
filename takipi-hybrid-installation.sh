#!/bin/bash

SERVICE_NAME=takipi-hybrid
TAKIPI_STORAGE_HOME=/opt/takipi-storage
PATH_TO_JAR=$TAKIPI_STORAGE_HOME/lib/takipi-storage-1.0.0.jar
PATH_TO_SETTINGS=$TAKIPI_STORAGE_HOME/settings.yml
LOG=$TAKIPI_STORAGE_HOME/log/takipi-storage.log
SCRIPT_LOG=$TAKIPI_STORAGE_HOME/log/takipi-storage-install.log
TAKIPI_STORAGE_SERVICE=$TAKIPI_STORAGE_HOME/etc/$SERVICE_NAME

#set -x

function log
{
  DATE=`date +%Y-%m-%d-%H-%M-%S`
  MASSEGE=$1

  echo $DATE $MASSEGE >> $SCRIPT_LOG
}

function privileges_validation()
{
  if [ `id -u` -ne 0 ]; then
  		echo "You need root privileges to run this script."
      log "You need root privileges to run this script"
      exit 1
  else
    log "Privileges validation completed successfully"
  fi

}

function java_version_check()
{
  readonly java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
  if [[ "$java_version" == "" ]]; then
    echo
    echo No java installations was detected.
    echo Please go to http://www.java.com/getjava/ and download
    echo
    exit 1
  elif [[ ! "$java_version" > "1.7" ]]; then
    echo
    echo The java installation you have is not up to date
    echo $SERVICE_NAME requires at least version 1.7+, you have
    echo version $java_version
    echo
    echo Please go to http://www.java.com/getjava/ and download
    echo a valid Java Runtime and install before running $SERVICE_NAME .
    echo
    exit 1
  else
    log  "Java version check completed successfully"
  fi
}

function configure_takipi_storage_home_dir()
{
  if [ ! -d "$TAKIPI_STORAGE_HOME" ]; then
    mkdir $TAKIPI_STORAGE_HOME
    cp -r ./* $TAKIPI_STORAGE_HOME/
  fi
  log  "Takipi storage home directory is Configured successfully"
}

function init_os()
{
	if [ ! "$os_name" ]; then
		if [ -f /etc/lsb-release ]; then
			distrib_line=$(cat /etc/lsb-release | grep '^DISTRIB_ID=')
			if [ ! -z "$distrib_line" ]; then
				os_name=${distrib_line:11}
			fi
		fi
	fi

	if [ ! "$os_name" ]; then
		if [ -f /etc/os-release ]; then
			id_like_line=$(cat /etc/os-release | grep '^ID_LIKE=')
			if [ ! -z "$id_like_line" ]; then
				id_like=${id_like_line:8}
				if [ "$id_like" = "suse" -o "$id_like" = "\"suse\"" ]; then
					os_name="SuSE"
				fi
			fi
		fi
	fi

	if [ "$os_name" ]; then
		log "$os_name detected."
	elif [ -f /etc/debian_version ]; then
		os_name="Ubuntu"
		log "Ubuntu/Debian detected."
	elif [ -f /etc/redhat-release ]; then
		os_name="Redhat"
		log "RedHat/Fedora detected."
	elif [ -f /etc/centos-release ]; then
		os_name="Redhat"
		log "CentOS detected."
	elif [ -f /etc/gentoo-release ]; then
		os_name="Gentoo"
		log "Gentoo detected."
	elif [ -f /etc/SuSE-release ]; then
		os_name="SuSE"
		log "SuSE detected."
	elif [ -f /etc/arch-release ]; then
		os_name="Arch"
		log "Arch Linux detected."
	elif [ -f /etc/system-release ]; then
		os_name="Redhat"
		log "Amazon Linux assumed."
	elif [ -d /etc/sysconfig ]; then
		if [ -f /etc/init.d/functions ]; then
			os_name="Redhat"
			log "RedHat/Fedora assumed."
		elif [ -f /etc/rc.status ]; then
			os_name="SuSE"
			log "SuSE assumed."
		fi
	elif [ -d /etc/conf.d ]; then
		os_name="Gentoo"
		log "Gentoo assumed."
	elif [ -d /Users ] && [ -d /Applications ]; then
		os_name="OSX"
		log "OSX detected"
	else
		os_name="Ubuntu"
		log "Ubuntu/Debian assumed."
	fi

	if [ "$os_name" = "Ubuntu" -o "$os_name" = "Debian" -o "$os_name" = "Mint" -o "$os_name" = "LinuxMint" -o "$os_name" = "MintLinux" ]; then
		os_name="Ubuntu"
	fi

  echo $os_name
}


function configure_init()
{
  os_name=$(init_os)

			if [ "$os_name" = "Ubuntu" ]; then
				cp -f $TAKIPI_STORAGE_SERVICE /etc/init.d/$SERVICE_NAME
				/usr/sbin/update-rc.d -f $SERVICE_NAME remove >/dev/null 2>&1
				/usr/sbin/update-rc.d $SERVICE_NAME defaults >/dev/null 2>&1
			elif [ "$os_name" = "Gentoo" ]; then
				cp -f $TAKIPI_STORAGE_SERVICE /etc/init.d/$SERVICE_NAME
				/sbin/rc-update del $SERVICE_NAME default >/dev/null 2>&1
				/sbin/rc-update add $SERVICE_NAME default >/dev/null 2>&1
			elif [ "$os_name" = "SuSE" ]; then
				cp -f $TAKIPI_STORAGE_SERVICE /etc/init.d/$SERVICE_NAME
				/sbin/insserv -r $SERVICE_NAME >/dev/null 2>&1
				/sbin/insserv -d $SERVICE_NAME >/dev/null 2>&1
			elif [ "$os_name" = "Arch" ]; then
				cp -f $TAKIPI_STORAGE_SERVICE  /lib/systemd/system/$SERVICE_NAME.service
				systemctl daemon-reload >/dev/null 2>&1
				systemctl enable $SERVICE_NAME.service >/dev/null 2>&1
			else # "Redhat"
				cp -f $TAKIPI_STORAGE_SERVICE /etc/init.d/$SERVICE_NAME
				/sbin/chkconfig $SERVICE_NAME on >/dev/null 2>&1
			fi

      if [ "$os_name" = "OSX" ]; then
        echo
        echo
        echo "This is OSX - We work with linux only"
        echo
        echo
      fi

	    if [ -f "/etc/init.d/takipi-hybrid" ]; then
			chmod +x /etc/init.d/takipi-hybrid
		  fi

	log "Configured init daemon $SERVICE_NAME"
}


function main()
{
  privileges_validation
  java_version_check
  configure_takipi_storage_home_dir
  configure_init
}

main
