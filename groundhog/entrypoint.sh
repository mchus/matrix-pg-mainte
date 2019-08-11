#!/bin/bash

# this script will use the api:
#    https://github.com/matrix-org/synapse/blob/master/docs/admin_api/purge_history_api.rst
#
# It will purge all messages in a list of rooms up to a cetrain event
# Originaly posted at https://github.com/matrix-org/synapse/blob/master/contrib/purge_api/purge_history.sh

###################################################################################################
# define your domain and admin user
###################################################################################################
# add this user as admin in your home server:
#DOMAIN=yourserver.tld
#ADMIN="@you_admin_username:$DOMAIN"

API_URL="${DOMAIN}/_matrix/client/r0"
ADMIN_URL="${DOMAIN}/_synapse/admin/v1"
UNIX_TIMESTAMP=$(date +%s%3N --date="$TIME")
AUTH="Authorization: Bearer $TOKEN"
SLEEP=3

# this will really delete local events, so the messages in the room really disappear unless they are restored by remote federation
post_data()
{
  cat <<EOF
{
  "delete_local_events":"true",
  "purge_up_to_ts":$UNIX_TIMESTAMP
}
EOF
}


# curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"type":"m.login.password", "user":"$ADMIN", "password":"$PASSWORD"}' '$API_URL/login'

echo "+=================================================================================================+"
echo " $(date) "
echo "+-------------------------------------------------------------------------------------------------+"
echo "+-------------------------------------------------------------------------------------------------+"

echo "+ Join $ROOM"
echo "+-------------------------------------------------------------------------------------------------+"
curl --header "$AUTH" -X POST --header "Content-Type: application/json" --header "Accept: application/json" -s -d "{}" "$API_URL/rooms/$ROOM/join"
echo "+-------------------------------------------------------------------------------------------------+"

echo "+ Testing $ROOM"
curl --header "$AUTH" -X GET --header "Content-Type: application/json" --header "Accept: application/json" -s -d "{}" "$API_URL/rooms/$ROOM/state/m.room.name"
echo "+-------------------------------------------------------------------------------------------------+"

echo "+ Purge $ROOM"
OUT=$(curl --header "$AUTH" -s -d "$(post_data)" POST "$ADMIN_URL/purge_history/$ROOM")
echo "+-------------------------------------------------------------------------------------------------+"

PURGE_ID=$(echo "$OUT" |grep purge_id|cut -d'"' -f4 )
echo $PURGE_ID
    while : ; do
      # get status of purge and sleep longer each time if still active
      sleep $SLEEP
      STATUS=$(curl --header "$AUTH" -s GET "$ADMIN_URL/purge_history_status/$PURGE_ID" |grep status|cut -d'"' -f4)
      : "$ROOM --> Status: $STATUS"
      echo $STATUS
      [[ "$STATUS" == "active" ]] || break
      SLEEP=$((SLEEP + 1))
      echo "+-------------------------------------------------------------------------------------------------+"
    done
echo "+=================================================================================================+"


#echo "###################################################################################################"
#echo " leave rooms"
#echo "###################################################################################################"
#for ROOM in "${ROOMS_ARRAY[@]}"; do
#    ROOM=${ROOM%#*}
#    curl --header "$AUTH" -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{}" "$API_URL/rooms/$ROOM/leave"
#done
echo "Sleeping"
for i in {0..60}
do
  for i in {0..60}
  do
    echo -n "#"
    sleep 1
  done
  echo
done
exit
