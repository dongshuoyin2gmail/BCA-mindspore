#!/bin/bash
# Copyright 2020-2021 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

if [ $# -lt 4 ]
then 
    echo "Usage: 
    bash run_standalone_train_gpu.sh [PRETRAINED_PATH] [BACKBONE] [COCO_ROOT] [DEVICE_ID] [MINDRECORD_DIR](option)
    "
exit 1
fi

if [ $2 != "resnet_v1_50" ] && [ $2 != "resnet_v1.5_50" ] && [ $2 != "resnet_v1_101" ] && [ $2 != "resnet_v1_152" ] && [ $2 != "inception_resnet_v2" ]
then 
  echo "error: the selected backbone must be resnet_v1_50, resnet_v1.5_50, resnet_v1_101, resnet_v1_152, inception_resnet_v2"
exit 1
fi

get_real_path(){
  if [ "${1:0:1}" == "/" ]; then
    echo "$1"
  else
    echo "$(realpath -m $PWD/$1)"
  fi
}

PATH1=$(get_real_path $1)
PATH2=$(get_real_path $3)
echo $PATH1
echo $PATH2

if [ ! -f $PATH1 ]
then 
    echo "error: PRETRAINED_PATH=$PATH1 is not a file"
exit 1
fi

if [ ! -d $PATH2 ]
then
    echo "error: COCO_ROOT=$PATH2 is not a dir"
exit 1
fi

mindrecord_dir=$PATH2/MindRecord_COCO_TRAIN/
if [ $# -eq 5 ]
then
    mindrecord_dir=$(get_real_path $5)
    if [ ! -d $mindrecord_dir ]
    then
        echo "error: mindrecord_dir=$mindrecord_dir is not a dir"
    exit 1
    fi
fi
echo $mindrecord_dir

BASE_PATH=$(cd ./"`dirname $0`" || exit; pwd)
if [ $# -ge 1 ]; then
  if [ $2 == 'resnet_v1.5_50' ]; then
    CONFIG_FILE="${BASE_PATH}/../default_config.yaml"
  elif [ $2 == 'resnet_v1_101' ]; then
    CONFIG_FILE="${BASE_PATH}/../default_config_101.yaml"
  elif [ $2 == 'resnet_v1_152' ]; then
    CONFIG_FILE="${BASE_PATH}/../default_config_152.yaml"
  elif [ $2 == 'resnet_v1_50' ]; then
    CONFIG_FILE="${BASE_PATH}/../default_config.yaml"
  elif [ $2 == 'inception_resnet_v2' ]; then
    CONFIG_FILE="${BASE_PATH}/../default_config_InceptionResnetV2.yaml"
  else
    echo "Unrecognized parameter"
    exit 1
  fi
else
  CONFIG_FILE="${BASE_PATH}/../default_config.yaml"
fi

export DEVICE_NUM=1
export CUDA_VISIBLE_DEVICES=$4
export RANK_ID=0
export RANK_SIZE=1

export PYTHONPATH=${BASE_PATH}:$PYTHONPATH
if [ -d "../train" ];
then
    rm -rf ../train
fi
mkdir ../train
cd ../train || exit

echo "start training for device $CUDA_VISIBLE_DEVICES"
env > env.log
pwd
python3 ${BASE_PATH}/../train.py --config_path=$CONFIG_FILE --coco_root=$PATH2 --mindrecord_dir=$mindrecord_dir \
--pre_trained=$PATH1 --device_target="GPU" --backbone=$2 &> train.log &
