#!/bin/bash
scriptDir="$(realpath "$(dirname "$0")")"

if [ $# -ne 4 ]; then
  echo "Usage: $0 <compose project path> <db password> <locale> <currency>"
  exit 1
fi


### BEGIN VALIDATION ###

composeProjectPath="$(realpath "$1")"
dbPassword="$2"
locale="$3"
currency="$4"


### BEGIN USER DATA DELETION ###

host="localhost"
port="3306"
user="root"

cd "$composeProjectPath"
docker compose exec -T database mariadb \
  -h "$host" \
  -P "$port" \
  -u "$user" \
  -p"$dbPassword" \
  shopware \
  << 'EOF'
  /* Initialize migration */
  SET FOREIGN_KEY_CHECKS=0;

  TRUNCATE TABLE `shopware`.`cart`;
  TRUNCATE TABLE `shopware`.`customer`;
  TRUNCATE TABLE `shopware`.`customer_address`;
  TRUNCATE TABLE `shopware`.`customer_wishlist`;
  TRUNCATE TABLE `shopware`.`document`;
  TRUNCATE TABLE `shopware`.`newsletter_recipient`;
  TRUNCATE TABLE `shopware`.`order`;
  TRUNCATE TABLE `shopware`.`order_address`;
  TRUNCATE TABLE `shopware`.`order_customer`;
  TRUNCATE TABLE `shopware`.`order_delivery_position`;
  TRUNCATE TABLE `shopware`.`order_delivery`;
  TRUNCATE TABLE `shopware`.`order_line_item`;
  TRUNCATE TABLE `shopware`.`order_transaction`;
  DELETE FROM `shopware`.`product_review` WHERE `product_review`.`customer_id` IS NOT NULL;
  TRUNCATE TABLE `shopware`.`sales_channel_api_context`;
  TRUNCATE TABLE `shopware`.`state_machine_history`;
  TRUNCATE TABLE `shopware`.`version_commit`;
  TRUNCATE TABLE `shopware`.`version_commit_data`;
  TRUNCATE TABLE `shopware`.`webhook_event_log`;

  /* Finish migration */
  SET FOREIGN_KEY_CHECKS=1;
EOF