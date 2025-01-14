#!/bin/bash
#******************************************
# Author:       Jason Zhao
# Email:        zhaoshundong@opsany.com
# Organization: OpsAny https://www.opsany.com/
# Description:  OpsAny Enterprise edition SAAS Install Script
#******************************************

# Data/Time
CTIME=$(date "+%Y-%m-%d-%H-%M")

# Shell Envionment Variables
CDIR=$(pwd)
SHELL_NAME="saas-ee-install.sh"
SHELL_LOG="${SHELL_NAME}.log"

#Configuration file write to DB
cd $CDIR 
grep '^[A-Z]' install.config > install.env
source ./install.env && rm -f install.env
cd ../saas/
python3 add_ee_env.py

# Install Inspection
cd ${CDIR}
if [ ! -f ./install.config ];then
      echo "Please Change Directory to /opt/opsany-paas/install"
      exit
else
    grep '^[A-Z]' install.config > install.env
    source ./install.env && rm -f install.env
fi

# Shell Log Record
shell_log(){
    LOG_INFO=$1
    echo "----------------$CTIME ${SHELL_NAME} : ${LOG_INFO}----------------"
    echo "$CTIME ${SHELL_NAME} : ${LOG_INFO}" >> ${SHELL_LOG}
}

# SaaS DB Initialize
saas_db_init(){
    shell_log "======MySQL Initialize======"
    #event
    mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database event DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on event.* to event@'%' identified by "\"${MYSQL_OPSANY_EVENT_PASSWORD}\"";"
    mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on event.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";" 
    
    #auto
    mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "create database auto DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on auto.* to auto@'%' identified by "\"${MYSQL_OPSANY_AUTO_PASSWORD}\"";"
    mysql -h "${MYSQL_SERVER_IP}" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "grant all on auto.* to opsany@'%' identified by "\"${MYSQL_OPSANY_PASSWORD}\"";" 
}

# MonogDB Initialize
mongodb_init(){
    shell_log "======Enterprise SAAS MongoDB Initialize======"
    mongo --host $MONGO_SERVER_IP -u $MONGO_INITDB_ROOT_USERNAME -p$MONGO_INITDB_ROOT_PASSWORD <<END
    use auto;
    db.createUser( {user: "auto",pwd: "$MONGO_AUTO_PASSWORD",roles: [ { role: "readWrite", db: "auto" } ]});
    use event;
    db.createUser( {user: "event",pwd: "$MONGO_EVENT_PASSWORD",roles: [ { role: "readWrite", db: "event" } ]});
    exit;
END
    shell_log "======Enterprise SAAS MongoDB Initialize End======"
}

ee_saas_init(){
    #python3 init_script.py --domain $DOMAIN_NAME --private_ip $LOCAL_IP
    echo 'hehe'
}

# Main
main(){
    saas_db_init
    mongodb_init
}

main
