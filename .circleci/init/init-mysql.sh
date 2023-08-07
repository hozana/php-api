#!/bin/bash
mysql -h 127.0.0.1 -u hozana -phozana hozana < hozana_org.sql
mysql -h 127.0.0.1 -u root -proot -e "create database if not exists hozana_e2e"
mysql -h 127.0.0.1 -u root -proot -e "GRANT ALL PRIVILEGES ON hozana_e2e.* TO 'hozana'@'%' WITH GRANT OPTION;"
cp hozana_org.sql hozana_e2e.sql && sed -i 's/USE `hozana`;/USE `hozana_e2e`;/g' hozana_e2e.sql
mysql -h 127.0.0.1 -u hozana -phozana hozana_e2e < hozana_e2e.sql && rm hozana_e2e.sql
mysql -h 127.0.0.1 -u root -proot -e "create database if not exists hozana_crm"
mysql -h 127.0.0.1 -u root -proot -e "GRANT ALL ON hozana_crm.* TO 'hozana'@'%' WITH GRANT OPTION;"
mysql -h 127.0.0.1 -u hozana -phozana hozana_crm < hozana_crm.sql
