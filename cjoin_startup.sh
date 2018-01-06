#! /bin/bash
#
echo "current tenant URL: " $URL
echo "IP address to use:" $ADDRESS
echo "host name to use:" $NAME
echo "current setting for PORT:" $PORT
echo "connectors setting: " $CONNECTOR
echo "login role: " $LOGIN_ROLE

# check required parameters

if [ "$URL" = "" ] ; then
  echo No tenant URL specified.
  exec /usr/sbin/init
fi

if [ "$CODE" = "" ] ; then
  echo No enrollment code specified.
  exec /usr/sbin/init
fi

if [ "$LOGIN_ROLE" = "" ] ; then
  echo No login role specified.
  exec /usr/sbin/init
fi

# set up command line parameters
CMDPARAM=" "

if [ "$PORT" != "" ] ; then
  CMDPARAM="-S Port:$PORT "
fi

if [ "$NAME" != "" ] ; then
  CMDPARAM="$CMDPARAM""--name $NAME "
fi

if [ "$ADDRESS" != "" ] ; then
  CMDPARAM="$CMDPARAM""--address $ADDRESS "
fi

if [ "$CONNECTOR" != "" ] ; then
  CMDPARAM="$CMDPARAM""-S Connectors:$CONNECTOR "
fi

if [ "$OPTION" != "" ] ; then
  CMDPARAM="$CMDPARAM""$OPTION"
fi

set +e
if [ -f /etc/systemd/system/multi-user.target.wants/centrifycc.service ]; then
  rm /etc/systemd/system/multi-user.target.wants/centrifycc.service
fi

/usr/sbin/cunenroll -f

echo "`date`: ready to enroll" >> /var/centrify/enroll.log
echo " paramters: $CMDPARAM"

/usr/sbin/cenroll -t $URL -F all --agentauth $LOGIN_ROLE --code $CODE $CMDPARAM -f & 
set -e

exec /usr/sbin/init