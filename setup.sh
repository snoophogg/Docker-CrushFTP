#!/usr/bin/env bash

if [[ -f /tmp/CrushFTP9.zip ]] ; then
    echo "Unzipping CrushFTP..."
    unzip -o -q /tmp/CrushFTP9.zip -d /var/opt/
    rm -f /tmp/CrushFTP9.zip

    if [[ -f /tmp/crushconfig.zip ]] ; then
        echo "Unzipping config..."
        unzip -o -q /tmp/crushconfig.zip -d /var/opt/CrushFTP9
    fi

    if [[ -f /tmp/prefs.XML ]] ; then
        echo "Copying prefs.XML..."
        cp /tmp/prefs.XML /var/opt/CrushFTP9/prefs.XML
        chmod +rwx /var/opt/CrushFTP9/prefs.XML
    fi
fi

[ -z ${CRUSH_ADMIN_USER} ] && CRUSH_ADMIN_USER=crushadmin
[ -z ${CRUSH_ADMIN_PASSWORD} ] && CRUSH_ADMIN_PASSWORD=crushadmin
[ -z ${CRUSH_ADMIN_PROTOCOL} ] && CRUSH_ADMIN_PROTOCOL=http
[ -z ${CRUSH_ADMIN_PORT} ] && CRUSH_ADMIN_PORT=8080
[ -z ${CONNECT} ] && CONNECT=0
[ -z ${MYSQL_HOST} ] && MYSQL_HOST=db
[ -z ${MYSQL_PORT} ] && MYSQL_PORT=3306
[ -z ${MYSQL_DATABASE} ] && MYSQL_DATABASE=crushftp
[ -z ${MYSQL_USER} ] && MYSQL_USER=crushftp
[ -z ${MYSQL_PASSWORD} ] && MYSQL_PASSWORD=crushftp

if [[ ! -d /var/opt/CrushFTP9/users/MainUsers/${CRUSH_ADMIN_USER} ]] || [[ -f /var/opt/CrushFTP9/admin_user_set ]] ; then
    echo "Creating default admin..."
    cd /var/opt/CrushFTP9 && java -jar /var/opt/CrushFTP9/CrushFTP.jar -a "${CRUSH_ADMIN_USER}" "${CRUSH_ADMIN_PASSWORD}"
    touch /var/opt/CrushFTP9/admin_user_set
fi

/var/opt/run-crushftp.sh start

sleep 30 # Wait for db and crush to startup

if [[ -f /tmp/post_setup.sh ]] && [[ $CONNECT = 1 ]] ; then
  /tmp/post_setup.sh
  [[ $? -ne 0 ]] && exit 1 # Exit if non-zero exit code
  rm -f /tmp/post_setup.sh
fi

while true; do sleep 86400; done