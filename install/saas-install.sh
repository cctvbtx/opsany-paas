#!/bin/bash
#******************************************
# Author:       Jason Zhao
# Email:        zhaoshundong@opsany.com
# Organization: https://www.opsany.com/
# Description:  OpsAny SAAS Install Script
#******************************************

#Data/Time
CTIME=$(date "+%Y-%m-%d-%H-%M")

#Shell ENV
SHELL_NAME="saas-install.sh"
SHELL_LOG="${SHELL_NAME}.log"

#Config 
source ./install.config

#Log
shell_log(){
    LOG_INFO=$1
    echo "----------------$CTIME ${SHELL_NAME} : ${LOG_INFO}----------------"
    echo "$CTIME ${SHELL_NAME} : ${LOG_INFO}" >> ${SHELL_LOG}
}

paas_check(){
    # check paas
    mkdir -p ${INSTALL_PATH}/{zabbix-volume/alertscripts,zabbix-volume/externalscripts,zabbix-volume/snmptraps,grafana-volume/plugins}
    mkdir -p ${INSTALL_PATH}/uploads/monitor/heartbeat-monitors.d
}

saltstack_install(){
shell_log "======启动SaltStack======"
docker run --restart=always --name opsany-saltstack --detach \
    --publish 4505:4505 --publish 4506:4506 --publish 8005:8005 \
    -v ${INSTALL_PATH}/logs:${INSTALL_PATH}/logs \
    -v ${INSTALL_PATH}/salt-volume/srv/:/srv/ \
    -v ${INSTALL_PATH}/salt-volume/certs/:/etc/pki/tls/certs/ \
    -v ${INSTALL_PATH}/salt-volume/etc/salt/:/etc/salt/ \
    -v ${INSTALL_PATH}/salt-volume/etc/salt/master.d:/etc/salt/master.d \
    ${PAAS_DOCKER_REG}/opsany-saltstack:${PAAS_VERSION}
sleep 20

docker exec opsany-saltstack salt-key -A -y
}

zabbix_install(){
    shell_log "=====Zabbix======"
    docker run --restart=always --name opsany-zabbix-server -t \
      -e DB_SERVER_HOST="${MYSQL_SERVER_IP}" \
      -e MYSQL_DATABASE="${ZABBIX_DB_NAME}" \
      -e MYSQL_USER="${ZABBIX_DB_USER}" \
      -e MYSQL_PASSWORD="${ZABBIX_DB_PASSWORD}" \
      -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
      -e ZBX_JAVAGATEWAY="zabbix-java-gateway" \
      -p 10051:10051 \
      -v ${INSTALL_PATH}/zabbix-volume/alertscripts:/usr/lib/zabbix/alertscripts \
      -v ${INSTALL_PATH}/zabbix-volume/externalscripts:/usr/lib/zabbix/externalscripts \
      -v ${INSTALL_PATH}/zabbix-volume/snmptraps:/var/lib/zabbix/snmptraps \
      -d ${PAAS_DOCKER_REG}/zabbix-server-mysql:alpine-5.0-latest

    sleep 20
    
    docker run --restart=always --name opsany-zabbix-web -t \
      -e ZBX_SERVER_HOST="${MYSQL_SERVER_IP}" \
      -e DB_SERVER_HOST="${MYSQL_SERVER_IP}" \
      -e MYSQL_DATABASE="${ZABBIX_DB_NAME}" \
      -e MYSQL_USER="${ZABBIX_DB_USER}" \
      -e MYSQL_PASSWORD="${ZABBIX_DB_PASSWORD}" \
      -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
      -p 8006:8080 \
      -d ${PAAS_DOCKER_REG}/zabbix-web-nginx-mysql:alpine-5.0-latest
}

grafana_install(){
    # Grafana
    shell_log "=====启动Grafana======"
    docker run -d --restart=always --name opsany-grafana \
    -v ${INSTALL_PATH}/conf/grafana/grafana.ini:/etc/grafana/grafana.ini \
    -v ${INSTALL_PATH}/conf/grafana/grafana.key:/etc/grafana/grafana.key \
    -v ${INSTALL_PATH}/conf/grafana/grafana.pem:/etc/grafana/grafana.pem \
    -p 8007:3000 \
    ${PAAS_DOCKER_REG}/opsany-grafana:7.3.5
}

es_install(){
    #Elasticsearch
    shell_log "====启动Elasticsearch"
    docker run -d --restart=always --name opsany-elasticsearch \
    -e "discovery.type=single-node" \
    -e "ELASTIC_PASSWORD=OpsAny@2020" \
    -e "xpack.license.self_generated.type=trial" \
    -e "xpack.security.enabled=true" \
    -e "bootstrap.memory_lock=true" \
    -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    -p 9200:9200 -p 9300:9300 \
    ${PAAS_DOCKER_REG}/elasticsearch:7.12.0
    
    #heartbeat
    shell_log "====启动Heartbeat===="
    docker run -d --restart=always --name opsany-heartbeat \
    -v ${INSTALL_PATH}/conf/heartbeat.yml:/etc/heartbeat/heartbeat.yml \
    -v ${INSTALL_PATH}/uploads/monitor/heartbeat-monitors.d:/etc/heartbeat/monitors.d \
    ${PAAS_DOCKER_REG}/heartbeat:7.13.1
    
}

saas_db_init(){
shell_log "======进行MySQL初始化======"
#esb
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" opsany_paas < ./init/esb-init/esb_api_doc.sql
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" opsany_paas < ./init/esb-init/esb_channel.sql
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" opsany_paas < ./init/esb-init/esb_component_system.sql
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" opsany_paas -e "INSERT INTO esb_user_auth_token VALUES (1, 'workbench', 'admin', 'opsany-esb-auth-token-9e8083137204', '2031-01-01 10:27:18', '2020-12-08 10:20:22', '2020-12-08 10:20:24'), (2, 'rbac', 'admin', 'opsany-esb-auth-token-9e8083137204', '2031-01-01 10:27:18', '2020-12-08 10:20:22', '2020-12-08 10:20:24'), (3, 'cmdb', 'admin', 'opsany-esb-auth-token-9e8083137204', '2031-01-01 10:27:18', '2020-12-08 10:20:22', '2020-12-08 10:20:24'), (4, 'job', 'admin', 'opsany-esb-auth-token-9e8083137204', '2031-01-01 10:27:18', '2020-12-08 10:20:22', '2020-12-08 10:20:24'), (5, 'control', 'admin', 'opsany-esb-auth-token-9e8083137204', '2031-01-01 10:27:18', '2020-12-08 10:20:22', '2020-12-08 10:20:24'), (6, 'monitor', 'admin', 'opsany-esb-auth-token-9e8083137204', '2031-01-01 10:27:18', '2020-12-08 10:20:22', '2020-12-08 10:20:24');"
#rbac
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database rbac DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on rbac.* to rbac@'%' identified by "\"${MYSQL_OPSANY_RBAC_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on rbac.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";"

#workbench
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database workbench DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on workbench.* to workbench@'%' identified by "\"${MYSQL_OPSANY_WORKBENCH_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on workbench.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";"

#cmdb
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database cmdb DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on cmdb.* to cmdb@'%' identified by "\"${MYSQL_OPSANY_CMDB_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on cmdb.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";"

#control
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database control DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on control.* to control@'%' identified by "\"${MYSQL_OPSANY_CONTROL_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on control.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";"

#job
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database job DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on job.* to job@'%' identified by "\"${MYSQL_OPSANY_JOB_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on job.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";"

#monitor
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database monitor DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on monitor.* to monitor@'%' identified by "\"${MYSQL_OPSANY_MONITOR_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on monitor.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";" 

#cmp
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database cmp DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on cmp.* to cmp@'%' identified by "\"${MYSQL_OPSANY_CMP_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on cmp.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";" 

#devops
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database devops DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on devops.* to devops@'%' identified by "\"${MYSQL_OPSANY_DEVOPS_PASSWORD}\"";"
mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on devops.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";" 
}

mongodb_init(){
shell_log "======进行MongoDB初始化======"
mongo --host $MONGO_SERVER_IP -u $MONGO_INITDB_ROOT_USERNAME -p$MONGO_INITDB_ROOT_PASSWORD <<END
use cmdb;
db.createUser({user: "$MONGO_CMDB_USERNAME",pwd: "$MONGO_CMDB_PASSWORD",roles: [ { role: "readWrite", db: "cmdb" } ]});
use job;
db.createUser( {user: "$MONGO_JOB_USERNAME",pwd: "$MONGO_JOB_PASSWORD",roles: [ { role: "readWrite", db: "job" } ]});
use cmp;
db.createUser( {user: "$MONGO_CMP_USERNAME",pwd: "$MONGO_CMP_PASSWORD",roles: [ { role: "readWrite", db: "cmp" } ]});
use workbench;
db.createUser( {user: "$MONGO_WORKBENCH_USERNAME",pwd: "$MONGO_WORKBENCH_PASSWORD",roles: [ { role: "readWrite", db: "workbench" } ]});
use devops;
db.createUser( {user: "$MONGO_DEVOPS_USERNAME",pwd: "$MONGO_DEVOPS_PASSWORD",roles: [ { role: "readWrite", db: "devops" } ]});
use monitor;
db.createUser( {user: "$MONGO_MONITOR_USERNAME",pwd: "$MONGO_MONITOR_PASSWORD",roles: [ { role: "readWrite", db: "monitor" } ]});
exit;
END
shell_log "======MongoDB初始化完毕======"

shell_log "======初始化CMDB模型数据======"
mongoimport --host $MONGO_SERVER_IP -u cmdb -pOpsAny@2020 --db cmdb --drop --collection field_group < ./init/cmdb-init/field_group.json
mongoimport --host $MONGO_SERVER_IP -u cmdb -pOpsAny@2020 --db cmdb --drop --collection icon_model < ./init/cmdb-init/icon_model.json
mongoimport --host $MONGO_SERVER_IP -u cmdb -pOpsAny@2020 --db cmdb --drop --collection link_relationship_model < ./init/cmdb-init/link_relationship_model.json
mongoimport --host $MONGO_SERVER_IP -u cmdb -pOpsAny@2020 --db cmdb --drop --collection model_field < ./init/cmdb-init/model_field.json
mongoimport --host $MONGO_SERVER_IP -u cmdb -pOpsAny@2020 --db cmdb --drop --collection model_group < ./init/cmdb-init/model_group.json
mongoimport --host $MONGO_SERVER_IP -u cmdb -pOpsAny@2020 --db cmdb --drop --collection model_info < ./init/cmdb-init/model_info.json
shell_log "======数据初始化完毕，可以开始部署SAAS应用。======"
}

saas_deploy(){
    ls ../saas/*.gz
    if [ $? -ne 0 ];then
        echo "Please Download SAAS first" && exit
    fi
    cd ../saas/
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name rbac-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name workbench-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name cmdb-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name control-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name job-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name monitor-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name cmp-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
    python3 deploy.py --domain $DOMAIN_NAME --username admin --password admin --file_name devops-${DOMAIN_NAME}-${SAAS_VERSION}.tar.gz
}

main(){
    paas_check
    saas_db_init
    mongodb_init
    saltstack_install
    zabbix_install
    grafana_install
    es_install
    saas_deploy
}

main