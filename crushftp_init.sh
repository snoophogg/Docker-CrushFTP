#!/bin/bash
#!/bin/sh
#
# Control script for CrushFTP v1.9
#
# chkconfig: - 86 14
# description: CrushFTP
#
### BEGIN INIT INFO  
# Provides:          crushftp_init.sh  
# Required-Start:    $local_fs  
# Should-Start:      $network   
# Required-Stop:       
# Should-Stop:       $network   
# Default-Start:     2 3 5
# Default-Stop:      2 5  
# Short-Description: CrushFTP Server  
# Description:       Starts Crush on boot  
### END INIT INFO  
# THESE NEED TO BE SET
CRUSH_DIR="/var/opt/CrushFTP9/" #crushftp directory
CRUSH_INIT_SCRIPT="$CRUSH_DIR"crushftp_init.sh
BASH_CMD="/bin/bash"
USER="root" # only work for this user
JAVA="java"
###
PS="ps"
AWK="awk"
GREP="grep"
WHOAMI="whoami"
NOHUP="nohup"
###
OSDETECT=1 # set this to 0 to force off automatic sytem version detect
###
LC_ALL=en_US.UTF-8
export LC_ALL=en_US.utf8

# example of how to redirect a low port to a high port so Crush doesn't have to run as root
# iptables -t nat -A PREROUTING -p tcp -m tcp --dport 21 -j REDIRECT --to-ports 2121

# We MUST start the server in the proper directory. If we can not change to that directory, we exit.
change_dir()
{
 cd $CRUSH_DIR
 ret_val=$?
 if [ ${ret_val} -ne 0 ]; then
   echo FAIL
   echo could not change to CrushFTP directory
   echo the directory is setup as:
   echo $CRUSH_DIR
   exit 1
 fi
}


# get PID from process list.  Not from a 'stored' file.  Since Crush updates will
# restart the server, but NEVER run this script, then if we stored off the PID into
# a file, then after an update, this script would not be able to shut down the
# process.  We have added a couple greps into the get_pid() so that we 'know' we
# are getting the proper PID if it exists.
get_pid()
{
 CRUSH_PID="`$PS -ef | $GREP java | $GREP $CRUSH_DIR | awk '{print $2}'`"
 CRUSH_PARENT="`$PS -ef | $GREP java | $GREP $CRUSH_DIR | awk '{print $3}'`"
}

# if the wrong user runs this script then BAIL.  If this script should be run as user
# OTHER than 'root' (or su or sudo), then you must redirect port 21 (or 22) up to a higher
# port, such as 60021.  iptables can do this well.  Then setup the crush server to bind to
# these higher ports.  Running as non-root is much more secure.  NOTE, it 'is' valid for root
# to shut down the server (but not to start it, unless USER="root" is set at teh top of the file
ROOT_OK=0
chk_user()
{
  if [ "$USER" != `whoami` ]; then
    if [ `whoami` = "root" -a "$ROOT_OK" = "1" ]; then
	echo ""
      # echo "Not an error. Root user is OK here, even if 'not' the proper user (such as killing the process)."
    else
       echo "Wrong user. This script MUST be run as <$USER>, but you are <`whoami`>"
       exit 1;
    fi
  fi
}
##################################################################################################
# Get OS type, version, distro name
##################################################################################################
GetOsVer(){
	
	MEM=`awk '/MemTotal/ { print $2 }' /proc/meminfo`
	DIV="1024"
	MEMH=`expr ${MEM} / ${DIV}`
	
	if [ ${JAVA} == "java" -a -f ${CRUSH_DIR}Java/bin/java ];then
		JAVA=${CRUSH_DIR}Java/bin/java
		JAVAENV="local"
	else 
		JAVAENV="system"
	fi

	JAVAVER=$($JAVA -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')

	if [ ! "${JAVAVER:0:1}" ] ; then
	  echo "No Java runtime found. Please install Java then try again. Exiting ..."
	  exit 1
	fi
	if [ "$OSDETECT" == "0" ];then
	    echo "Manual service installation method is set"
	    INSTSCRIPT=0
	else
		OS=`uname -s`
		REV=`uname -r`

		if [ "${OS}" = "Linux" ] ; then
		    KERNEL=`uname -r`
		    if [ -f /etc/fedora-release ] ; then
			DIST='Fedora'
			REV=`cat /etc/fedora-release | sed s/.*release\ // | sed s/\ .*//`
				if [ ${REV} -gt "15" ] ; then
					INSTSCRIPT=1
				else
					INSTSCRIPT=2
				fi
		    elif [ -f /etc/redhat-release ] ; then
			DIST='RedHat'
			REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
				if [ ${REV:0:1} -eq "7" ] ; then
					INSTSCRIPT=1
				else
					INSTSCRIPT=2
				fi
					
		    elif [ -f /etc/SuSE-release ] ; then
			DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
			REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
				INSTSCRIPT=2
				
		    elif [ -f /etc/mandrake-release ] ; then
			DIST='Mandrake'
			REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
				INSTSCRIPT=2
				
		    elif [ -f /etc/debian_version ] ; then
			DIST="`lsb_release -i -s`"""
			REV="`lsb_release -r -s`"""
			if [ "${DIST}" == "Ubuntu" ]; then
				if [ ${REV:0:2} -gt "11" ] ; then
				  if [ ${REV:0:2} -ge "16" ] ; then
						INSTSCRIPT=1
				    else
						INSTSCRIPT=4
				  fi
					else
						INSTSCRIPT=3
					fi
			elif  [ "${DIST}" == "Debian" ]; then
				if [ ${REV:0:1} -lt "8" ] ; then
					INSTSCRIPT=3
				else
					INSTSCRIPT=4
				fi
				
			fi
		    #misc amazon linux                              
                    elif [ -f /etc/os-release ] ; then
                        if [ -f /etc/system-release ];then
                                DIST=`cat /etc/system-release`
                        else
                                DIST="Misc Linux"
                        fi
                        REV=`cat /etc/system-release | sed s/.*release\ // | sed s/\ .*//`
                                INSTSCRIPT=1

				
		    else 
				DIST="Misc Linux"		
			fi
			
		else 
			OS="Unknown"
			DIST="Unknown"
			REV="Unknown"
			KERNEL="Unknown"
		fi
	fi
	if [ "${INSTSCRIPT}" == "0" ]; then
		INITTYPE="MISC/UNKNOWN"
	elif [ "${INSTSCRIPT}" == "1" ]; then
		INITTYPE="systemd"
	else 
		INITTYPE="system V"
	fi
# lsb, if available, is more accurate for flavor detection, override. eye candy only
	if [ -f /usr/bin/lsb_release ];then
		FLAV="`lsb_release -i -s`"""
		REV="`lsb_release -r -s`"""

		if [[ ${FLAV} == *"${DIST}" ]];then	
			SYSINFO="OS Family: ${OS} \nDistro: ${DIST} \nRevision: ${REV} \nKernal Version: ${KERNEL} \nSystem init: $INITTYPE \nJava: ${JAVAVER} (${JAVAENV}) \nSystem memory: ${MEMH} MB"
		else
			SYSINFO="OS Family: ${OS} \nFlavor: ${FLAV} ( major ${DIST} )\nRevision: ${REV} \nKernal Version: ${KERNEL} \nSystem init: $INITTYPE \nJava: ${JAVAVER} (${JAVAENV}) \nSystem memory: ${MEMH} MB"
		fi	
	else
			SYSINFO="OS Family: ${OS} \nFlavor: ${DIST} \nRevision: ${REV} \nKernal Version: ${KERNEL} \nSystem init: $INITTYPE \nJava: ${JAVAVER} (${JAVAENV}) \nSystem memory: ${MEMH} MB"			
	fi
}
CrushFTP_start() {
            chk_user
             get_pid
             if [ "$CRUSH_PID" ]; then
               echo FAIL
               echo Found an already running instance of CrushFTP.
               echo It is not valid o start 2 sessions in the same directory.
               exit 1;
             fi
             echo -n "Starting CrushFTP... "
             change_dir

             # run daemon
             #$NOHUP $JAVA -Ddir=$CRUSH_DIR -Xmx512M --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED -jar CrushFTP.jar -dmz 9000 & >/dev/null 2>&1
             #$NOHUP $JAVA -Ddir=$CRUSH_DIR -Xmx512M --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED -jar plugins/lib/CrushFTPJarProxy.jar -d & >/dev/null 2>&1
             $NOHUP $JAVA -Ddir=$CRUSH_DIR -Xmx512M -jar plugins/lib/CrushFTPJarProxy.jar -d & >/dev/null 2>&1
             echo OK
}

CrushFTP_stop() {
             # root or $USER is ok to shut down the server.
             ROOT_OK=1
             chk_user
             get_pid
             if [ ! "$CRUSH_PID" ]; then
               echo FAIL
               echo Could not find Crush PID
               exit 1
             fi

             echo -n Shutting down CrushFTP...
             kill $CRUSH_PID
             ret_val=$?
             if [ ${ret_val} -ne 0 ]; then
                echo FAIL
                echo could not kill PID
                exit 1
             fi
             echo OK
}
CrushFTP_stop_silent() {
             # root or $USER is ok to shut down the server.
             ROOT_OK=1
             chk_user
             get_pid
             if [ ! "$CRUSH_PID" ]; then
               echo CrushFTP is not currently running...
             else
          
               echo -n Shutting down CrushFTP...
               kill $CRUSH_PID
               ret_val=$?
               if [ ${ret_val} -ne 0 ]; then
           	  echo FAIL
                  echo could not kill PID
                  exit 1
               fi 
               echo OK  
             fi
}
#############################################################################################
# Here is the 'main' script.  We can either start the server, or shutdown the current       #
# running server.   There is error checking to make sure the proper user is being used.     #
#############################################################################################
case "$1" in
        start)
            CrushFTP_stop_silent
            CrushFTP_start
        ;;

        stop)
            CrushFTP_stop
        ;;

        restart)
                CrushFTP_stop
		sleep 5
                CrushFTP_start 
        ;;


        status)
             get_pid
             if [ ! "$CRUSH_PID" ]; then
			if [ -f /etc/init.d/crushftp ];then
               			echo "System V service exists"
				echo "Service stopped."
			elif [ -f /etc/systemd/system/crushftp.service ];then
				echo "systemd service exists"
				echo "Service stopped."
			else
				echo "Process not running."
			fi
             		exit 3
             else
		if [ "$CRUSH_PARENT" = "1" ]; then
			echo "Running as daemon (pid $CRUSH_PID)"
		else
			echo "Running as user (pid $CRUSH_PID)"
		fi
             fi
        ;;
	install)
		echo ""
		if [ -f /etc/init.d/crushftp -o -f /etc/systemd/system/crushftp.service ];then
			echo "service already installed."
			echo "nothing to do."
			echo ""
			exit 3
		elif [ "$CRUSH_PID" ];then
			echo "CrushFTP already running (pid $CRUSH_PID), killing process "
			kill -9 $CRUSH_PID
			get_pid
			if [ "$CRUSH_PID" ];then
				echo "Process could not be terminated, exiting ..."
				exit 1
			fi
		fi
		GetOsVer
		if [ "$INSTSCRIPT" = "0" ];then
                        echo "Automatic OS version detection failed or manual method chosen."
                        echo ""
                        echo "Select your OS family:"
                        echo "1 - RHEL/CentOS 7 or Ubuntu 16  and newer based (systemD method)"
                        echo "2 - RHEL/CentOS 6 and prior  based (system V method)"
                        echo "3 - Prior to Debian 8 / All Ubuntu except 16 and 13 "
                        echo "0 - Not sure - EXIT -"
                        echo ""
			read -p 'Enter choice [0..3]: ' INSTSCRIPT

		fi
		#CentOS 7 , Ubuntu 16
		if [ "$INSTSCRIPT" = "1" ];then
			echo "using systemd installation method"
				touch /etc/systemd/system/crushftp.service
				cat <<-EOT >/etc/systemd/system/crushftp.service
				[Unit]
					Description=CrushFTP 9 Server
					Documentation=http://www.crushftp.com/
					After=network.target auditd.service named.service
				[Service]
					Type=forking
					ExecStart=${BASH_CMD} ${CRUSH_INIT_SCRIPT} start
					ExecStop=${BASH_CMD} ${CRUSH_INIT_SCRIPT} stop
                                	Restart=always
                                	RestartSec=5
				[Install]
					WantedBy=multi-user.target
				#dummy padding
EOT

				systemctl daemon-reload && systemctl enable crushftp.service && systemctl start crushftp.service
				sleep 5
				get_pid	
				echo ""				
				echo "Service succesfully installed and running ... PID:$CRUSH_PID" 
				echo ""	
		#CentOS 6.6 and below					
		elif [ "$INSTSCRIPT" = "2" ];then
			echo "using System V installation method"
			ln -f -s "$CRUSH_DIR"crushftp_init.sh /etc/init.d/crushftp 
			chkconfig --add crushftp
			chkconfig crushftp on
			service crushftp start 
			sleep 5
			get_pid					
			echo "Service succesfully installed and running ... PID:$CRUSH_PID"
			echo "" 											
		#Debian and Ubuntu Old, some obsolete CentOS
		elif [ "$INSTSCRIPT" = "3" ];then
			echo "using System V installation method"
			ln -f -s "$CRUSH_DIR"crushftp_init.sh /etc/init.d/crushftp
			/etc/init.d/crushftp start
			sleep 5
			get_pid					
			echo "Service succesfully installed and running ... PID:$CRUSH_PID"
			echo ""
		#Ubuntu 12,14,15 except 13
		echo "using System V installation method"
		elif [ "$INSTSCRIPT" = "4" ]; then
				ln -f -s "$CRUSH_DIR"crushftp_init.sh /etc/init.d/crushftp
				update-rc.d crushftp defaults
				service crushftp start
				get_pid
									
				echo "Service succesfully installed and running ... PID:$CRUSH_PID"							
		else
			echo "Exiting..."
			
		fi
	;;
        uninstall)
		chk_user
		get_pid
		GetOsVer
		echo ""
		if [ "$INSTSCRIPT" = "0" ];then
                        echo ""
                        echo "Automatic OS version detection failed. Please try to uninstall service manually"
                        echo ""
                        echo "Select your OS family:"
                        echo "1 - RHEL/CentOS 7 or Ubuntu 16  based (systemD method)"
                        echo "2 - RHEL/CentOS 6 and prior  based (system V method)"
                        echo "3 - Legacy"
                        echo "0 - Not sure - EXIT -"
                        echo ""
                        read -p 'Enter choice [0..3]: ' INSTSCRIPT

                fi

		if [ "$INSTSCRIPT" = "0" ];then
			echo "Exiting..."
			exit 1
		fi
               #CentOS 7 , Ubuntu 16, RHEL 7 family
                if [ "$INSTSCRIPT" = "1" -a -f "/etc/systemd/system/crushftp.service" ];then
                		if [ "$CRUSH_PID" ];then
                			echo "already running ( pid no.: $CRUSH_PID). stopping service"
					systemctl stop crushftp.service
				else
					echo "service not running."
				fi 
			if [ "$(systemctl is-enabled crushftp.service)" = "enabled" ];then
				echo "disabled service"
				systemctl disable crushftp.service
                	fi
			rm -f /etc/systemd/system/crushftp.service
			echo "cleanup done."
			systemctl daemon-reload 
                        systemctl reset-failed
			echo "service uninstalled."
			echo ""                 
               #CentOS 6.6 and below 
               elif [ "$INSTSCRIPT" = "2" -a -f /etc/init.d/crushftp ];then
			if [ "$CRUSH_PID" ];then
				echo "already running ( pid no.: $CRUSH_PID). stopping service"
			fi
			service crushftp stop                      
			chkconfig crushftp off
                        chkconfig --del crushftp
			echo "disabled service."
			rm -f /etc/init.d/crushftp
			echo "cleanup done."
			echo "service uninstalled."
			echo ""
                elif [ "$INSTSCRIPT" = "3" -a -f /etc/init.d/crushftp ];then
			if [ "$CRUSH_PID" ];then
				echo "already running ( pid no.: $CRUSH_PID). stopping service"
				/etc/init.d/crushftp stop
			fi
                                rm -f /etc/init.d/crushftp
                                echo "service uninstalled (obsolete method)."
				echo ""
                #Ubuntu 12,14,15 except 13
                elif [ "$INSTSCRIPT" = "4" -a -f /etc/init.d/crushftp ];then
			
				if [ "$CRUSH_PID" ];then
					echo "already running ( pid no.: $CRUSH_PID). stopping service"
					service crushftp stop
				fi   
				rm -f /etc/init.d/crushftp
				update-rc.d -f crushftp remove
				echo "service uninstalled (obsolete method)."
				echo ""
		else                   
			echo "an installed service was not found."
			echo "nothing to do."
			echo ""
                fi
        ;;
	info)
		if [ "$OSDETECT" == "0" ];then
    			echo "Manual service installation method is set, automatic OS detection is disabled"
		else
			GetOsVer
			echo ""
			echo "System info:"
			echo ""
			echo | sed "i$SYSINFO" 
		fi	
	;;		

        *)
             echo "Usage: $0 [start|stop|restart|status|install|uninstall|info] Note: you must be logged in as $USER to run this script"

esac

exit 0

