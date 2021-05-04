#!/bin/vbash
#############################################################################
#                                                                           #
#  :::    ::: :::::::::  ::::    :::      :::    :::  ::::::::   ::::::::   #
#  :+:   :+:  :+:    :+: :+:+:   :+:      :+:    :+: :+:    :+: :+:    :+:  #
#  +:+  +:+   +:+    +:+ :+:+:+  +:+      +:+    +:+ +:+        +:+         #
#  +#++:++    +#++:++#+  +#+ +:+ +#+      +#+    +:+ +#++:++#++ :#:         #
#  +#+  +#+   +#+        +#+  +#+#+#      +#+    +#+        +#+ +#+   +#+#  #
#  #+#   #+#  #+#        #+#   #+#+#      #+#    #+# #+#    #+# #+#    #+#  #
#  ###    ### ###        ###    ####       ########   ########   ########   #
#                                                                           #
#############################################################################
# Author      : Henk van Achterberg (coolhva)                               #
# GitHub      : https://github.com/coolhva/usg-kpn-ftth/                    #
# Version     : 0.2 (ALPHA)                                                 #
#---------------------------------------------------------------------------#
# Description :                                                             #
#                                                                           #
# This file does the following things:                                      #
#   1. Checks and fixes the correct MTU on interface eth0 and eth0 vif 6    #
#                                                                           #
#---------------------------------------------------------------------------#
# Installation :                                                            #
#                                                                           #
# Place this file at /config/scripts/post-config.d/kpn.sh and make it       #
# executable (chmod +x /config/scripts/post-config.d/kpn.sh).               #
#############################################################################

readonly logFile="/var/log/kpn.log"

echo "[kpn.sh] Executed at $(date)" >> ${logFile}

# Check for lock file and exit if it is present
if [ -f "/config/scripts/post-config.d/kpn.lock" ]; then
echo "[kpn.sh] lock file /config/scripts/post-config.d/kpn.lock exists, stopping execution" >> ${logFile}
exit
fi

# Create lock file so kpn.sh will not execute simultaniously
echo "[kpn.sh] creating lock file at /config/scripts/post-config.d/kpn.lock" >> ${logFile}
touch /config/scripts/post-config.d/kpn.lock

# Delete the kpn crontab file, if exists, to avoid runnig this file every minute
if [ -f "/etc/cron.d/kpn" ]; then
echo "[kpn.sh] KPN found in crontab, removing /etc/cron.d/kpn" >> ${logFile}
    rm /etc/cron.d/kpn
fi

# Load environment variables to be able to configure the USG via this script
source /opt/vyatta/etc/functions/script-template

# Check if the mtu is set for eth0, if not, set the value for eth0 and vif 6
if [ ! $(cli-shell-api returnActiveValue interfaces ethernet eth0 mtu) ]; then
    echo "[kpn.sh] MTU for eth0 not configured, adjusting config" >> ${logFile}
    echo "[kpn.sh] Disconnecting pppoe2 before changing MTU" >> ${logFile}
    /opt/vyatta/bin/vyatta-op-cmd-wrapper disconnect interface pppoe2 >> ${logFile}
    configure >> ${logFile}
    echo "[kpn.sh] Setting mtu for eth0 to 1512" >> ${logFile}
    set interfaces ethernet eth0 mtu 1512 >> ${logFile}
    echo "[kpn.sh] Setting mtu for eth0 vif 6 to 1508" >> ${logFile}
    set interfaces ethernet eth0 vif 6 mtu 1508 >> ${logFile}
    echo "[kpn.sh] Commiting" >> ${logFile}
    commit
    echo "[kpn.sh] Connecting pppoe2 after changing MTU" >> ${logFile}
    /opt/vyatta/bin/vyatta-op-cmd-wrapper connect interface pppoe2 >> ${logFile}
    # This will remove the lock file and exit the bash script, and via the commit hook will run this script again.
    echo "[kpn.sh] removing lock file at /config/scripts/post-config.d/kpn.lock" >> ${logFile}
    rm /config/scripts/post-config.d/kpn.lock
    exit
fi

# removing lock file and finish execution
echo "[kpn.sh] removing lock file at /config/scripts/post-config.d/kpn.lock" >> ${logFile}
rm /config/scripts/post-config.d/kpn.lock
echo "[kpn.sh] Finished" >> ${logFile}
