

function choose_init_type()
{
	has_systemd="false"
	has_upstart="false"

	which systemctl >/dev/null 2>&1

	if [ $? -eq "0" ]; then
		report_install_status 71 "systemd"
		has_systemd="true"

		log "Init daemon available: systemd"
	fi

	which initctl >/dev/null 2>&1

	if [ $? -eq "0" ]; then
		report_install_status 71 "upstart"
		has_upstart="true"

		log "Init daemon available: upstart"
	fi

	if [ "$has_systemd" == "true" ];then
		init_type="systemd"
	elif [ "$has_upstart" == "true" ];then
		init_type="upstart"
	else
		init_type="sysvinit"
	fi

	log "Chosen init daemon: $init_type"
}
