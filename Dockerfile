FROM ubuntu:24.04

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
    curl \
    bc

RUN python3 -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

COPY ./benchmark.sh /workspace/mlperfstorage/benchmark.sh
COPY ./dlio_benchmark /workspace/mlperfstorage/dlio_benchmark
COPY ./report.py /workspace/mlperfstorage/report.py
WORKDIR /workspace/mlperfstorage/dlio_benchmark

RUN pip install setuptools pybind11

RUN python setup.py build
RUN python setup.py develop

RUN pip install --no-cache-dir "git+https://github.com/awslabs/s3-connector-for-pytorch.git@main#egg=s3torchconnector&subdirectory=s3torchconnector"

WORKDIR /workspace/mlperfstorage

# To avoid installing all of DALI, just grab the script that is a silent dependency of DLIO
RUN curl -s https://raw.githubusercontent.com/NVIDIA/DALI/refs/heads/main/tools/tfrecord2idx -o /usr/local/bin/tfrecord2idx
RUN chmod +x /usr/local/bin/tfrecord2idx