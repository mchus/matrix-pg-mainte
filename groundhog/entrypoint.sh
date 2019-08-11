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
SLEEP=0

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


###################################################################################################
#choose the rooms to prune old messages from (add a free comment at the end)
###################################################################################################
# the room_id's you can get e.g. from your Riot clients "View Source" button on each message
#ROOMS_ARRAY=(
#'!DgvjtOljKujDBrxyHk:matrix.org#riot:matrix.org'
#'!QtykxKocfZaZOUrTwp:matrix.org#Matrix HQ'
#)

# ALTERNATIVELY:
# you can select all the rooms that are not encrypted and loop over the result:
# SELECT room_id FROM rooms WHERE room_id NOT IN (SELECT DISTINCT room_id FROM events WHERE type ='m.room.encrypted')
# or
# select all rooms with at least 100 members:
# SELECT q.room_id FROM (select count(*) as numberofusers, room_id FROM current_state_events WHERE type ='m.room.member'
#   GROUP BY room_id) AS q LEFT JOIN room_aliases a ON q.room_id=a.room_id WHERE q.numberofusers > 100 ORDER BY numberofusers desc

###################################################################################################
# evaluate the EVENT_ID before which should be pruned
###################################################################################################
# choose a time before which the messages should be pruned:
#TIME='1 day ago'
# ALTERNATIVELY:
# a certain time:
# TIME='2016-08-31 23:59:59'

# creates a timestamp from the given time string:
#UNIX_TIMESTAMP=$(date +%s%3N --date='TZ="UTC+2" '"$TIME")


# ALTERNATIVELY:
# prune all messages that are older than 1000 messages ago:
# LAST_MESSAGES=1000
# SQL_GET_EVENT="SELECT event_id from events WHERE type='m.room.message' AND room_id ='$ROOM' ORDER BY received_ts DESC LIMIT 1 offset $(($LAST_MESSAGES - 1))"

# ALTERNATIVELY:
# select the EVENT_ID manually:
#EVENT_ID='$1471814088343495zpPNI:matrix.org' # an example event from 21st of Aug 2016 by Matthew

###################################################################################################
# make the admin user a server admin in the database with
###################################################################################################
# psql -A -t --dbname=synapse -c "UPDATE users SET admin=1 WHERE name LIKE '$ADMIN'"
# curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"type":"m.login.password", "user":"$ADMIN", "password":"$PASSWORD"}' '$API_URL/login'


echo "###################################################################################################"
echo " join rooms"
echo "###################################################################################################"
for ROOM in "${ROOMS_ARRAY[@]}"; do
    ROOM=${ROOM%#*}
    curl --header "$AUTH" -X POST --header "Content-Type: application/json" --header "Accept: application/json" -s -d "{}" "$API_URL/rooms/$ROOM/join"
    curl --header "$AUTH" "$API_URL/rooms/$ROOM/state/m.room.power_levels"
done

echo "###################################################################################################"
echo " start pruning the room"
echo "###################################################################################################"

echo "########################################### $(date) ################# "
echo "## pruning rooms:"
for ROOM in "${ROOMS_ARRAY[@]}"; do
    ROOM=${ROOM%#*}
    echo "$ROOM"
    OUT=$(curl --header "$AUTH" -s -d "$(post_data)" POST "$ADMIN_URL/purge_history/$ROOM")
    echo "$OUT"
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
        done
      sleep 1
echo "###################################################################################################"

done


###################################################################################################
# additionally
###################################################################################################
# to benefit from pruning large amounts of data, you need to call VACUUM to free the unused space.
# This can take a very long time (hours) and the client have to be stopped while you do so:
# $ synctl stop
# $ sqlite3 -line homeserver.db "vacuum;"
# $ synctl start

# This could be set, so you don't need to prune every time after deleting some rows:
# $ sqlite3 homeserver.db "PRAGMA auto_vacuum = FULL;"
# be cautious, it could make the database somewhat slow if there are a lot of deletions
#echo "###################################################################################################"
#echo " leave rooms"
#echo "###################################################################################################"
#for ROOM in "${ROOMS_ARRAY[@]}"; do
#    ROOM=${ROOM%#*}
#    curl --header "$AUTH" -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{}" "$API_URL/rooms/$ROOM/leave"
#done
echo "Sleeping"
for i in {0..360}
do
echo -n "#"
sleep 1
done
exit
