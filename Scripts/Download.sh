#!/bin/bash -x
echo "the $1 eats a $2 every time there is a $3"
echo "bye:-)"
ORGANIZATION="releasea"
PROJECTNAME="AprovisionamientoAutomatico"
REPOID="ArtefactosAprovisionamiento"
APPPATH="Binarios/AutomicUnix.zip"
USER=""
TOKEN="uvay7nxx5zq3mgktj66lnlsmr5ouhins3n5z43pekg26judfzyca"
OUTPATH="/tmp"
AGENTNAME=$HOSTNAME
INSTALLPATH="/opt/CA"
LOGFILE="/home/test.log"
AEHOST="172.26.28.23"
#
echo $agentName
#TO DO use Yum install for red hat distribution
echo "Updating Packages......."
sudo apt-get update
echo "Install zip      ......."
sudo apt-get -y install zip
echo "Install Unzip    ......."
sudo apt-get -y install unzip
#
URI="https://dev.azure.com/$ORGANIZATION/$PROJECTNAME/_apis/git/repositories/$REPOID/items?scopePath=$APPPATH&format=zip&api-version=5.0"
echo $URI
IFS=’/’ read -ra NAMES <<< "$APPPATH" 
echo "El nombre del archivo es ${NAMES[-1]}"
AUTH=$(echo -ne "$USER:$TOKEN" | base64 --wrap 0)
curl -X GET -H "Authorization: Basic $AUTH" -H "Content-Type: application/zip" $URI --output "$OUTPATH/${NAMES[-1]}"
#
unzip $OUTPATH/${NAMES[-1]} -d $OUTPATH
#Install CAPKI
echo "Installing CAPKI ........"
#Permissions
chmod +x $OUTPATH/AutomicUnix/CAPKI/unix/linux/x64/setup
#alias cdo='cd ${OUTPATH}/AutomicUnix/CAPKI/unix/linux/x64/'
$OUTPATH/AutomicUnix/CAPKI/unix/linux/x64/setup install caller=AE122 verbose env=all
export CAPKIHOME=/opt/CA/SharedComponents/CAPKI
echo "End Installing CAPKI ........"

#Install ServiceManager
echo "Installing ServiceManager ........"
echo "Creating Servicemager folder"
mkdir $INSTALLPATH/servicemanager
tar -xvf $OUTPATH/AutomicUnix/ServiceManager/unix/linux/x64/ucsmgrlx6.tar.gz --directory $INSTALLPATH/servicemanager
#Permissions
chown root $INSTALLPATH/servicemanager *
chgrp root $INSTALLPATH/servicemanager *
#
mv $INSTALLPATH/servicemanager/bin/ucybsmgr.ori.ini $INSTALLPATH/servicemanager/bin/ucybsmgr.ini
mv $INSTALLPATH/servicemanager/bin/uc4.ori.smd $INSTALLPATH/servicemanager/bin/uc4.smd
cat /dev/null > $INSTALLPATH/servicemanager/bin/uc4.smd
echo "CREATE UC4 $AGENTNAME" > $INSTALLPATH/servicemanager/bin/uc4.smc
echo "DEFINE UC4 $AGENTNAME;*OWN/../../Agents/unix/bin/ucxjlx6;*OWN/../../Agents/unix/bin/" >> $INSTALLPATH/servicemanager/bin/uc4.smd
#Install Agents
echo "Installing Agents ........"
mkdir $INSTALLPATH/Agents/
mkdir $INSTALLPATH/Agents/unix
tar -xvf $OUTPATH/AutomicUnix/Agents/unix/linux/x64/ucxjlx6.tar.gz --directory $INSTALLPATH/Agents/unix
#Permissions
chown root $INSTALLPATH/Agents *
chgrp root $INSTALLPATH/Agents *
#
mv $INSTALLPATH/Agents/unix/bin/ucxjxxx.ori.ini $INSTALLPATH/Agents/unix/bin/ucxjlx6.ini
#
chown root $INSTALLPATH/Agents/unix/bin/ucxjlx6.ini
chmod 4755 $INSTALLPATH/Agents/unix/bin/ucxjlx6.ini
#
sed -i 's/UNIX01/'$AGENTNAME'/g' $INSTALLPATH/Agents/unix/bin/ucxjlx6.ini
sed -i 's/license_Class=9/license_Class=V/g' $INSTALLPATH/Agents/unix/bin/ucxjlx6.ini
sed -i 's/cphost/'$AEHOST'/g' $INSTALLPATH/Agents/unix/bin/ucxjlx6.ini
echo "2218=$AEHOST" >> $INSTALLPATH/Agents/unix/bin/ucxjlx6.ini
export LD_LIBRARY_PATH=/lib
$(nohup $INSTALLPATH/servicemanager/bin/ucybsmgr -i$INSTALLPATH/servicemanager/bin/ucybsmgr.ini DEVS &)