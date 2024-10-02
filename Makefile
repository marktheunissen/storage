
.PHONY: submodule build bash gen train mirror

DOCKER_RUN := @docker run --rm \
	-v ./data:/workspace/mlperfstorage/data \
	-v ./checkpoints:/workspace/mlperfstorage/checkpoints \
	-v ./results:/workspace/mlperfstorage/results \
	-v ./hydra_log:/workspace/mlperfstorage/hydra_log \
	-v ./dlio_benchmark/dlio_benchmark:/workspace/mlperfstorage/dlio_benchmark/dlio_benchmark \
	-v ./storage-conf:/workspace/mlperfstorage/storage-conf \
	-v ./benchmark.sh:/workspace/mlperfstorage/benchmark.sh \
	--env-file env-container \
	-it mlperfstorage

submodule:
	@cd dlio_benchmark && git submodule update --init --recursive
	@cd dlio_benchmark && git checkout s3torch

build:
	@docker build -t mlperfstorage .

bash:
	${DOCKER_RUN} bash

WORKLOAD := unet3d
ACCEL_TYPE := h100
RESULTS_DIR := results/${WORKLOAD}_${ACCEL_TYPE}

gen:
	@mkdir -p data/unet3d/train data/unet3d/valid
	${DOCKER_RUN} ./benchmark.sh datagen \
	--hosts 127.0.0.1 \
	--workload ${WORKLOAD} \
	--accelerator-type ${ACCEL_TYPE} \
	--num-parallel 1 \
	--param dataset.num_files_train=100

MINIO_ALIAS ?= local
MINIO_BUCKET ?= unetbucket
MINIO_ALIAS_BUCKET := ${MINIO_ALIAS}/${MINIO_BUCKET}

mirror:
	@mc mb -p ${MINIO_ALIAS_BUCKET}
	mc mirror --overwrite --remove ./data ${MINIO_ALIAS_BUCKET}/data

benchmark:
	${DOCKER_RUN} ./benchmark.sh run \
	-c open \
	--hosts 127.0.0.1 \
	--workload ${WORKLOAD} \
	--accelerator-type ${ACCEL_TYPE} \
	--num-accelerators 1 \
	--results-dir ${RESULTS_DIR} \
	--param storage.storage_type=s3 \
	--param storage.storage_root=${MINIO_BUCKET} \
	--param reader.data_loader_classname=dlio_benchmark.plugins.experimental.src.data_loader.s3_torch_data_loader.S3TorchDataLoader \
	--param reader.data_loader_sampler=index \
	--param dataset.num_files_train=100
