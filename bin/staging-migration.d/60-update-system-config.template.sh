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


### BEGIN SYSTEM CONFIG UPDATE ###

host="localhost"
port="3306"
user="root"

cd "$composeProjectPath"
# docker compose exec -T database mariadb \
#   -h "$host" \
#   -P "$port" \
#   -u "$user" \
#   -p"$dbPassword" \
#   shopware \
#   << 'EOF'
#   /* Initialize migration */
#   SET FOREIGN_KEY_CHECKS=0;
# 
#   /* Delete webhooks */
#   DELETE FROM `shopware`.`webhook` WHERE `webhook`.`url` LIKE "https://www.domain.tld%";
#   DELETE FROM `shopware`.`webhook` WHERE `webhook`.`url` LIKE "http://localhost:3000%";
#   DELETE FROM `shopware`.`webhook` WHERE `webhook`.`url` LIKE "http://127.0.0.1:3000%";
# 
#   /* Adjust system configuration */
#   UPDATE `shopware`.`product` \
#     SET `product`.`stock` = 1000, \
#         `product`.`available_stock` = 1000;
# 
#   UPDATE `shopware`.`document_base_config` \
#     SET `document_base_config`.`custom_fields` = '{"custom_document_config_sw_domain": "sw-staging.domain.tld"}';
# 
#   UPDATE `shopware`.`sales_channel` \
#     SET `sales_channel`.`access_key` = 'STORE_API_KEY' \
#     WHERE `sales_channel`.`id` = CAST(0xSALES_CHANNEL_ID AS BINARY);
# 
#   UPDATE `shopware`.`sales_channel_translation` \
#     SET `sales_channel_translation`.`name` = 'staging.domain.tld' \
#     WHERE `sales_channel_translation`.`sales_channel_id` = CAST(0xSALES_CHANNEL_ID AS BINARY) AND `sales_channel_translation`.`language_id` = CAST(0xLANGUAGE_ID AS BINARY);
# 
#   TRUNCATE TABLE `shopware`.`sales_channel_domain`;
#   INSERT INTO `shopware`.`sales_channel_domain` \
#     (`id`, `sales_channel_id`, `language_id`, `url`, `currency_id`, `snippet_set_id`, `hreflang_use_only_locale`, `custom_fields`, `created_at`, `updated_at`) \
#     VALUES (0xSALES_CHANNEL_DOMAIN_ID, 0xSALES_CHANNEL_ID, 0xLANGUAGE_ID, 'https://staging.domain.tld', 0xCURRENCY_ID, 0xSNIPPET_SET_ID, '0', NULL, '2026-01-01 00:00:00.000000', NULL), \
#            (0xDEV_SALES_CHANNEL_DOMAIN_ID, 0xSALES_CHANNEL_ID, 0xLANGUAGE_ID, 'http://127.0.0.1:3000', 0xCURRENCY_ID, 0xSNIPPET_SET_ID, '0', NULL, '2026-01-01 00:00:00.000000', NULL);
# 
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":"staging.domain.tld"}' \
#     WHERE `system_config`.`configuration_key` = 'core.basicInformation.shopName';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":{"id":"SHOP_ID","fingerprints":{"sales_channel_domain_urls":"SALES_CHANNEL_DOMAIN_ID","installation_path":"\/usr\/share\/nginx\/html","app_url":"https:\/\/sw-staging.domain.tld"},"version":2}}' \
#     WHERE `system_config`.`configuration_key` = 'core.app.shopIdV2';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":"sw-staging.domain.tld"}' \
#     WHERE `system_config`.`configuration_key` = 'core.store.licenseHost';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":"2026-01-01 00:00:00.000000"}' \
#     WHERE `system_config`.`configuration_key` = 'core.frw.completedAt';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":"SHOP_SECRET"}' \
#     WHERE `system_config`.`configuration_key` = 'core.store.shopSecret';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":true}' \
#     WHERE `system_config`.`configuration_key` = 'SwagPayPal.settings.sandbox';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":"SANDBOX_WEBHOOK_TOKEN"}' \
#     WHERE `system_config`.`configuration_key` = 'SwagPayPal.settings.webhookExecuteToken';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":"SANDBOX_WEBHOOK_ID"}' \
#     WHERE `system_config`.`configuration_key` = 'SwagPayPal.settings.webhookId';
#   UPDATE `shopware`.`system_config` \
#     SET `system_config`.`configuration_value` = '{"_value":true}' \
#     WHERE `system_config`.`configuration_key` = 'MolliePayments.config.testMode';
# 
#   /* Finish migration */
#   SET FOREIGN_KEY_CHECKS=1;
# EOF