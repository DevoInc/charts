{{- define "devo-relay.relayInit.sh.tpl" -}}

CONF_MOUNT_PATH={{ .Values.relay.initConfMountPath }}

if [ ! -f $CONF_MOUNT_PATH/relay/relay.properties ]; then
    ## ==== First installation ==== ##
    cp -R /opt/devo/ng-relay/conf/relay $CONF_MOUNT_PATH
else
    ## ==== Backup config files ==== ##
    mkdir -p $CONF_MOUNT_PATH/config-bck
    cp $CONF_MOUNT_PATH/relay/maduro.properties $CONF_MOUNT_PATH/config-bck
    cp $CONF_MOUNT_PATH/relay/devo-ng-relay.jvmoptions $CONF_MOUNT_PATH/config-bck
    cp $CONF_MOUNT_PATH/relay/relay.properties $CONF_MOUNT_PATH/config-bck
    cp $CONF_MOUNT_PATH/relay/run/keys.py $CONF_MOUNT_PATH/config-bck
    if [ -d $CONF_MOUNT_PATH/relay/run/keys ]; then
        cp -R $CONF_MOUNT_PATH/relay/run/keys $CONF_MOUNT_PATH/config-bck
    fi
    ## ==== Copy static files ==== ##
    rm -rf $CONF_MOUNT_PATH/relay
    cp -R /opt/devo/ng-relay/conf/relay $CONF_MOUNT_PATH
    ## ==== Restore config files ==== ##
    cp $CONF_MOUNT_PATH/config-bck/maduro.properties $CONF_MOUNT_PATH/relay
    cp $CONF_MOUNT_PATH/config-bck/devo-ng-relay.jvmoptions $CONF_MOUNT_PATH/relay
    cp $CONF_MOUNT_PATH/config-bck/relay.properties $CONF_MOUNT_PATH/relay
    cp $CONF_MOUNT_PATH/config-bck/keys.py $CONF_MOUNT_PATH/relay/run
    if [ -d $CONF_MOUNT_PATH/config-bck/keys ]; then
        cp -R $CONF_MOUNT_PATH/config-bck/keys $CONF_MOUNT_PATH/relay/run
    fi
    ## ==== Remove backup dir ==== ##
    rm -rf $CONF_MOUNT_PATH/config-bck
fi
{{- end }}
