FROM ubuntu:22.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git \
    sysstat \
    mpich \
    libc6 \
    libhwloc-dev \
    python3.10 \
    python3-pip \
    python3-venv \
    cmake \
    iputils-ping \
    iproute2 \
    bc

RUN python3 -m pip install --upgrade pip
RUN python3 -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"
RUN python3 -m pip install pybind11

COPY . /workspace/mlperfstorage
WORKDIR /workspace/mlperfstorage/dlio_benchmark

RUN python setup.py build
RUN python setup.py develop

RUN pip install --no-cache-dir "git+https://github.com/awslabs/s3-connector-for-pytorch.git@main#egg=s3torchconnector&subdirectory=s3torchconnector"

WORKDIR /workspace/mlperfstorage
