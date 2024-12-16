#!/bin/sh
set -euxo pipefail

echo "${CRON_SCHEDULE} sh /backup/backup.sh" > /var/spool/cron/crontabs/root
crond -f