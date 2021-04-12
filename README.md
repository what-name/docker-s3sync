# S3Backup

S3Backup is a Docker container which backs up one or more folders to S3 using
the aws cli tool. This is forked from joch's original S3Backup container
[https://github.com/joch/docker-s3backup] but has been modified to make use of the
aws cli rather than s3cmd as I had problems getting s3cmd to sync files containing
special characters. The AWS cli also seems to have some problems running with python
version 2 so this has been updated to version 3. 

This container makes use of the "aws s3 sync" command.

To tell s3backup what to back up, mount your desired volumes under the
`/data` directory.

s3backup is configured by setting the following environment variables during
the launch of the container.

FIXME put this into a table
- ACCESS_KEY - your AWS access key
- SECRET_KEY - your AWS secret key
- S3PATH - your S3 bucket and path
- S3SYNCPARAMS - custom parameters to aws s3 sync [http://docs.aws.amazon.com/cli/latest/reference/s3/sync.html]

Files are by default backed up once every hour. You can customize this behavior
using an environment variable which uses the standard CRON notation.

- `CRON_SCHEDULE` - set to `0 * * * *` by default, which means every hour.

## Example invocation

#### Simple run
To backup your home folder at 03:00 every day, you could use something like this. This will sync your `/home/user` local directory to your specified S3 bucket, leaving everything else in the bucket intact (except if there's already something in the prefix `s3://your-bucket-name/user/`)

```
docker run \
-v /home/user:/data/user:ro \
-e "ACCESS_KEY=AWS_ACCESS_KEY_HERE" \
-e "SECRET_KEY=AWS_SECRET_KEY_HERE" \
-e "S3PATH=s3://BUCKET_NAME_HERE/" \
-e "CRON_SCHEDULE=0 3 * * *" \
whatname/docker-s3sync
```

#### Advanced run
If you want more customization on the S3 side, you can use the `S3SYNCPARAMS` to input `aws s3 sync` CLI parameters such as `--delete`. You can also use an IAM role that the user with the provided AWS Access Keys should assume to perform the sync. If not present, the pair of access and secret keys will be used directly.

This will sync both the `/home/user` and `/opt/files` local folders to `s3://your-bucket-name/this_prefix/` and **delete everything else** that's under that prefix. Upon sync, the contents of `s3://your-bucket-name/this_prefix/` will only be the two folders [and their files] that you just synced.
```
docker run \
-v /home/user:/data/user:ro \
-v /opt/files:/data/files:ro\
-e "ACCESS_KEY=AWS_ACCESS_KEY_HERE" \
-e "SECRET_KEY=AWS_SECRET_KEY_HERE" \
-e "ROLEARN=YOUR_ROLES_ARN_HERE" \
-e "S3PATH=s3://BUCKET_NAME_HERE/this_prefix/" \
-e "S3SYNCPARAMS=--delete" \
-e "CRON_SCHEDULE=* * * * *" \
whatname/docker-s3sync
```

## Unraid
```

```
