# PG Docker Backup

Small docker container that allows you to setup backups of Posgres DBs as a docker container itself.
It uses the `pg_dumpall` tool and pipes it to `gzip` and then pipes it to `aws s3 cp`.

I built this because it is dumb that managed DB's cost 5 to 10x the CPU and Memory prices for the same VPS.

## Status

This is a work in progress but I am using it in production now! I plan on updating this to also support PITR
backups using a docker volume

## Environment Varables All Required

- S3_APPLICATION_KEY_ID: { Compatible S3 Key Id (Can by a secret file) }
- S3_SECRET_ACCESS_KEY: { Compatible S3 Secret Key (Can by a secret file) }
- S3_BUCKET_NAME: { Name of the S3 bucket }
- S3_REGION: { Compatible S3 Region }
- S3_API_URL: { Compatible S3 Endpoint URL }
- OBJECT_KEY_PREFIX: { Defaults to: `db-backup-` all files end with date time in format `YYYYmmDD-HHMMSS.sql.gz` }
- DB_HOST: { The db host. Can use internal name for stack and compose files }
- DB_PORT: { The db port defaults to 5432 }
- DB_NAME: { The db name to initially connect too, defaults to postgres }
- DB_USER: { The db user to initially connect with, defaults to postgres }
- DB_PASSWORD: { The db users password (Can by a secret file) }
- CRON_SCHEDULE: { The standard cron schedule pattern: \* \* \* \* \* }
- COMPRESSOR_CMD: { The cli tool to compress the backup. (gzip or xz) Defaults to gzip but xz is installed }
- OBJECT_KEY_SUFFIX: { Defaults to `.sql.gz` but good to change if you change the compressor tool }
- EXPECTED_SIZE: { Only if it is going to be over 50 GB }

### How It works

We start crond -f wit hthe backup command. So it will output the cron logs to standard out.

This first version takes the full backups of the whole cluster based on the cron schedule. It
runs `pg_dumpall -c -w` with the `DB_` environment varables to take a backup. It
pipes the backup to `gzip` and then pipes it to `aws s3 cp` command to copy the file up.

There is a 50 GB limit the way it is written so test the bachup size ahead of time by running
`pg_dumpall | xz > dump.sql.gz` to see the gzip size and add `--expected-size` to the command if
it is over.

### xz over gzip

If you use xz over gzip it does make much smaller files but takes more cpu and memory to run. You can limit
xz memory by setting a max like `xz --memlimit-compress=200MiB` as well as it is muti-threaded so you can limit
the cpu by forcing a single thread like this `xz -T1`. Both of those settings will jsut mean it takes longer to backup.
You can make it take less cpu, memory, and time by just changing the compression ration with values from 0 to 9 like
`xz -0` for the dastest and `xz -9` the slowest but most compression.

### Test

There is a docker-compose.yaml file showing how to set it up. You can also use it to test if you wanted or make your own image.
Add a `.env` with the environment varables you want to keep a secret and run `source .env && docker compose up -d`.