# glacier-swift

This Swift package provides a command-line utility that implements a couple hashing algorithms used by Amazon S3 and S3 Glacier. This is not a replacement for uploading files (check out the [AWS CLI](https://github.com/aws/aws-cli)), but can be used to verify  checksums for some extra peace of mind.

## Usage

### `swift run glacier treehash [file]`

Computes the [tree hash](https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html) checksum of a file.

### `swift run glacier etag [file]`

Computes the S3 `ETag` checksum using the algorithm described [here](https://stackoverflow.com/questions/12186993/what-is-the-algorithm-to-compute-the-amazon-s3-etag-for-a-file-larger-than-5gb). A default chunk size of 8MB is used; this can be configured with the `--chunk-size-mb` option.
