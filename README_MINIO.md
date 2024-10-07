
# Configure

See `env-container` file for a place to put your MinIO keys and specify the URL to your instance.

It's also necessary to set up a MinIO alias for `mc mirror` to work.

# Running benchmark

Start with building container:

    make submodule
    make build

Generate data using container:

    make gen

Data is now available outside the container in `data` dir. Mirror it to the S3 bucket. Set the variables as you like them, e.g. MINIO_ALIAS.
TODO: Generate should save directly to S3

    make mirror MINIO_ALIAS=local

Do benchmark:

    make benchmark

# Debugging

In the yaml config file, set `debug: True` for debug level logging, under "workflow" section

# Notes on hacks

## fork

Note: This only applied to an old approach which used Ubuntu 22.04 as a base image, 24.04 has appeared to fix the need for this env var.

`RDMAV_FORK_SAFE=1` is set in env vars, due to error:

    A process has executed an operation involving a call
    to the fork() system call to create a child process.

    As a result, the libfabric EFA provider is operating in
    a condition that could result in memory corruption or
    other system errors.

- https://github.com/mlcommons/storage/issues/44
- https://github.com/mlcommons/storage/issues/62
- https://github.com/argonne-lcf/dlio_benchmark/issues/9

Tried changing `multiprocessing_context: spawn` in the yaml but there were further errors that indicated lack of support in DLIO

## s3 torch connector

Tried to install via setup.py pinned version, got:

    error: Couldn't find a setup script in /tmp/easy_install-jbjegl26/s3torchconnector-1.2.5.tar.gz

Instead just pulling in directly in Dockerfile
