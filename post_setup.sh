#!/usr/bin/env bash

wait=0
echo 'Starting post setup script...'

conn="$CRUSH_ADMIN_PROTOCOL"'://127.0.0.1:'"$CRUSH_ADMIN_PORT"'/'
#echo "$conn"

TryCurl () {
  # printf "%s" "waiting for crush ..."
  # while ! ping -c 1 -n -w 1 127.0.0.1 &> /dev/null
  # do
  #     printf "%c" "."
  # done
  # printf "\n%s\n"
  local args=(--cookie-jar /tmp/curlcookiejar --cookie /tmp/curlcookiejar --write-out %{http_code} --silent --output /tmp/curl.out)
  args+=("$@")
  args+=("$conn")
  # echo "${args[@]}"
  local -i fails=0
  touch /tmp/curl.out
  while [ $(curl "${args[@]}") -ne "200" ]; do 
    fails=$((fails+1))
    echo "Failed"
    if [[ $fails -gt 5 ]]; then
      cat /tmp/curl.out
      echo "EXITING..."
      exit 1
    fi
    sleep $((fails*3))
  done
  # cat /tmp/curl.out
}

echo 'Logging in...'
TryCurl -d command=login -d username="$CRUSH_ADMIN_USER" -d password="$CRUSH_ADMIN_PASSWORD"
response=$(grep -Pzo "(?<=<response>)[^<]+" /tmp/curl.out)
echo 'response: '"$response"
if [[ $response == "failure" ]] ; then
  exit 1
fi
c2f=$(grep -Pzo "(?<=<c2f>)[^<]+" /tmp/curl.out)
# echo 'c2f: '"$c2f"

echo 'Encrypting database password...'
TryCurl -d command=encryptPassword -d password="$MYSQL_PASSWORD" -d c2f="$c2f"
password=$(grep -Pzo "(?<=<response>)[^<]+" /tmp/curl.out)
# echo 'password: '"$password"

dburl='jdbc:mysql://'"$MYSQL_HOST"':'"$MYSQL_PORT"'/'"$MYSQL_DATABASE"'?autoReconnect=true&amp;useSSL='"$MYSQL_USESSL"
# echo 'dburl: '"$dburl"

echo 'Apply user database settings...'
xmldata='<sqlItems type="properties"><db_driver_file>/usr/share/java/mysql-connector-java.jar</db_driver_file><db_pass>'"$password"'</db_pass><db_url>'"$dburl"'</db_url><db_user>'"$MYSQL_USER"'</db_user><db_driver>com.mysql.jdbc.Driver</db_driver></sqlItems>'
TryCurl -d command=setServerItem -d key=server_settings/sqlItems -d data_type=properties -d data_action=update -d c2f="$c2f" --data-urlencode data="$xmldata"
echo 'Applied'

TryCurl -d command=getServerItem -d key=server_settings/server_groups -d c2f="$c2f"
groups=$(sed -n 's:.*<result_value_subitem>\(.*\)</result_value_subitem>.*:\1:p' /tmp/curl.out)
for group in $groups ; do
  echo 'Converting '"$group"' users...'
  TryCurl -d command=convertXMLSQLUsers -d serverGroup="$group" -d fromMode=XML -d toMode=SQL -d c2f="$c2f"
  echo 'Converted'
done

echo 'Switch to user database...'
xmldata='<server_prefs type="properties"><externalSqlUsers>true</externalSqlUsers><xmlUsers>false</xmlUsers></server_prefs>'
TryCurl -d command=setServerItem -d key=server_settings/server_prefs/ -d data_type=properties -d data_action=update --data-urlencode data="$xmldata" -d c2f="$c2f"
echo 'Using database'

echo 'Apply logging database settings...'
xmldata='<server_prefs type="properties"><logging_db_driver_file>/usr/share/java/mysql-connector-java.jar</logging_db_driver_file><logging_db_pass>'"$password"'</logging_db_pass><logging_db_url>'"$dburl"'</logging_db_url><logging_db_user>'"$MYSQL_USER"'</logging_db_user><logging_db_driver>com.mysql.jdbc.Driver</logging_db_driver><logging_provider>crushftp.handlers.log.LoggingProviderSQL</logging_provider></server_prefs>'
TryCurl -d command=setServerItem -d key=server_settings/server_prefs -d data_type=properties -d data_action=update -d c2f="$c2f" --data-urlencode data="$xmldata"
echo 'Applied'

echo 'Apply stats database settings...'
xmldata='<server_prefs type="properties"><stats_db_driver_file>/usr/share/java/mysql-connector-java.jar</stats_db_driver_file><stats_db_pass>'"$password"'</stats_db_pass><stats_db_url>'"$dburl"'</stats_db_url><stats_db_user>'"$MYSQL_USER"'</stats_db_user><stats_db_driver>com.mysql.jdbc.Driver</stats_db_driver></server_prefs>'
TryCurl -d command=setServerItem -d key=server_settings/server_prefs -d data_type=properties -d data_action=update -d c2f="$c2f" --data-urlencode data="$xmldata"
echo 'Applied'

echo 'Apply syncs database settings...'
xmldata='<server_prefs type="properties"><syncs_db_driver_file>/usr/share/java/mysql-connector-java.jar</syncs_db_driver_file><syncs_db_pass>'"$password"'</syncs_db_pass><syncs_db_url>'"$dburl"'</syncs_db_url><syncs_db_user>'"$MYSQL_USER"'</syncs_db_user><syncs_db_driver>com.mysql.jdbc.Driver</syncs_db_driver></server_prefs>'
TryCurl -d command=setServerItem -d key=server_settings/server_prefs -d data_type=properties -d data_action=update -d c2f="$c2f" --data-urlencode data="$xmldata"
echo 'Applied'

export CONNECT=0

echo 'Logging out...'
TryCurl -d command=logout -d c2f="$c2f"

echo 'Done post setup.'