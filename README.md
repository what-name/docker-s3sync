# s3sync

S3sync is a Docker container which backs up one or more folders to S3 using
the aws cli tool. This is forked from joch's [original S3Backup container]
(https://github.com/joch/docker-s3backup) but has been modified to make use of the
aws cli rather than the outdated s3cmd. This has been also updated to Python 3.

This container makes use of the "aws s3 sync" command.

To tell s3sync what to back up, mount your desired volumes under the
`/data` directory.

s3sync is configured by setting the following environment variables during
the launch of the container.

Env var | Description | Example
--- | --- | ---
`ACCESS_KEY` | your AWS access key | `AKIABV38RBV38RBV38B3`
`SECRET_KEY` | your AWS secret key | `ubuUbuBubUuuBbuveubviurvurud6rDU3qpU`
`REGION` | your bucket's region | `eu-central-1`
`S3PATH` | your S3 bucket and path | `s3://my-nice-bucket`
`S3SYNCPARAMS` | [custom parameters to aws s3 sync](http://docs.aws.amazon.com/cli/latest/reference/s3/sync.html) | `--delete`

Files are by default backed up once every hour. You can customize this behavior
using an environment variable which uses the standard CRON notation.

- `CRON_SCHEDULE` - set to `0 * * * *` by default, which means every hour. *It's not recommended to set it to more frequent than this.*

## Example invocation

#### Simple run
This will sync your `/home/user` local directory every hour to your specified S3 bucket, leaving everything else in the bucket intact.

```
docker run \
-v /home/user:/data/user:ro \
-e "ACCESS_KEY=AWS_ACCESS_KEY_HERE" \
-e "SECRET_KEY=AWS_SECRET_KEY_HERE" \
-e "REGION=eu-central-1" \
-e "S3PATH=s3://BUCKET_NAME_HERE" \
whatname/docker-s3sync
```

#### Advanced run
If you want more customization on the S3 side, you can use the `S3SYNCPARAMS` to input `aws s3 sync` CLI parameters such as `--delete`. You can also specify deeper paths in S3, and a cron schedule.

This will sync both the `/home/user` and `/opt/files` local folders to `s3://your-bucket-name/this_prefix/` and **delete everything else** that's *inside that prefix*. Upon sync, the contents of `s3://your-bucket-name/this_prefix/` will only be the two folders [and their files] that you just synced.

```
docker run \
-v /home/user:/data/user:ro \
-v /opt/files:/data/files:ro\
-e "ACCESS_KEY=AWS_ACCESS_KEY_HERE" \
-e "SECRET_KEY=AWS_SECRET_KEY_HERE" \
-e "REGION=eu-central-1" \
-e "S3PATH=s3://BUCKET_NAME_HERE/this_prefix" \
-e "S3SYNCPARAMS=--delete" \
-e "CRON_SCHEDULE=* 0 * * *" \
whatname/docker-s3sync
```

## Unraid
```

```

## Future improvements
#### Ability to assume role automatically
You can also use an IAM role that the user with the provided AWS Access Keys should assume to perform the sync. If not present, the pair of access and secret keys will be used directly.