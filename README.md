# glacier-swift

This Swift package provides a command-line utility that implements some checksum algorithms used by Amazon S3 and S3 Glacier. This is not a replacement for uploading files (check out the [AWS CLI](https://github.com/aws/aws-cli)), but can be used to verify checksums for some extra peace of mind.

## Usage

```
swift run glacier etag <file-path> [--chunk-size-mb <chunk-size-mb>] [--chunk-size-bytes <chunk-size-bytes>]
swift run glacier sha1 <file-path> [--chunk-size-mb <chunk-size-mb>] [--chunk-size-bytes <chunk-size-bytes>]
swift run glacier sha256 <file-path> [--chunk-size-mb <chunk-size-mb>] [--chunk-size-bytes <chunk-size-bytes>]
```

Computes the S3 `ETag` (MD5), SHA-1, or SHA-256 checksum using the algorithm described [here](https://stackoverflow.com/questions/12186993/what-is-the-algorithm-to-compute-the-amazon-s3-etag-for-a-file-larger-than-5gb) and [here](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html). A default chunk size of 8MB is used; this can be configured with the `--chunk-size-mb` or `--chunk-size-bytes` option. (For files uploaded via the AWS Console web UI, use [`--chunk-size-bytes 17179870`](https://stackoverflow.com/questions/12186993/what-is-the-algorithm-to-compute-the-amazon-s3-etag-for-a-file-larger-than-5gb#comment136008274_43819225).)

```
swift run glacier treehash [file]
```

Computes the [tree hash](https://docs.aws.amazon.com/cli/v1/userguide/cli-services-glacier.html#cli-services-glacier-complete) of a file (used with the older `aws glacier complete-multipart-upload`).
