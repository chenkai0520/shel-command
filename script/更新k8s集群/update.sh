#!/bin/bash

CURRENT_PATH=$( dirname "${BASH_SOURCE[0]}" )
cd "$CURRENT_PATH"


# 配置文件
source ./config.sh
# 工具函数
source ./uitls.sh


# 检查配置路径
if [[ ! -d "${KUBECTL_PATH}" ]]
then
console "****** 集群yaml配置路径:${KUBECTL_PATH}不存在 ******" "e"
exit
fi

echo "******开始更新集群******"

# 当前路径
path="$(pwd)"

# 备份yaml文件
cp -r ${KUBECTL_PATH}  ${path}/backup

echo "******备份yaml文件******"

# load镜像到master并根据镜像到tag替换对应yaml文件的版本

for f in ./images/*
do

    # 空文件跳过
    if [ ! -e $f ]
    then
        continue
    fi
    # 文件名
    f_all_name="${f##*/}"

    # 文件名带后缀
    image_name_tag="${f_all_name%*.tar}"
    # 提取镜像名称及后缀
    image_tag="${image_name_tag#*.}"
    image_name="${image_name_tag%%.v*}"

    # 判断image_tag是否合法
    if [[ !("${image_tag}" =~ ^v[0-9]+[0-9.]+[0-9]+$) ]]
    then
        console "###### 镜像tag标签不合法: ${f} ######" "e"
        exit
    fi

    #yaml不存在对应文件跳过
    if [ ! -e ${KUBECTL_PATH}/${image_name}".yaml" ]
    then

        console "###### ${KUBECTL_PATH}/${image_name}.yaml不存在 ######" 'w'
        continue
    fi

    #替换镜像tag
    common="s/\/${image_name}:\(.*\)/\/${image_name}:${image_tag}/g"

    # sed 命令在 macos 和 linux 有一些不同
    # macos
    # sed -i "" ${common} ${KUBECTL_PATH}/${image_name}".yaml"

    # shell
    sed -i ${common} ${KUBECTL_PATH}/${image_name}".yaml"

    echo "******修改 "${KUBECTL_PATH}/${image_name}".yaml 文件******"

    # 如果yamls文件中不包含该名称的yaml则复制到yaml中
    if [[ ! -e "./yamls/${image_name}.yaml" ]]
    then
    cp ${KUBECTL_PATH}/${image_name}".yaml"  "./yamls/${image_name}.yaml"
    fi
done

echo "******开始同步镜像******"

# laod镜像到每台node节点
NODE_IPS="$(kubectl get node| awk '{print $1}' | grep -v NAME)"
for ip in ${NODE_IPS}
do
# 清理之前的文件
   ssh "root@${ip}" "rm -rf ${path} && mkdir -p ${path}"
#    拷贝文件
   scp -r ${path}/images root@${ip}:${path}
#    load镜像
   ssh "root@${ip}" "cd ${path}/images && ls | xargs -n 1 docker load -i"

echo "******${ip}:load镜像结束******"
done

echo "******结束同步镜像******"


# 判断更新的yaml是否存在原先的yaml文件，
# 存在的话先执行delete，再替换yaml文件，apply，
# 不存在添加yaml文件，apply，

for f in ./yamls/*
do

    # 空文件跳过
    if [ ! -e $f ]
    then
        continue
    fi

    if [ -e ${KUBECTL_PATH}/${f##*/} ]
    then
        kubectl delete -f ${KUBECTL_PATH}/${f##*/}
        cp ${f} ${KUBECTL_PATH}/${f##*/}
        kubectl apply -f ${KUBECTL_PATH}/${f##*/}

        echo "******apply ${KUBECTL_PATH}/${f##*/}******"
    else
        cp ${f} ${KUBECTL_PATH}/${f##*/}
        kubectl apply -f ${KUBECTL_PATH}/${f##*/}

        echo "******apply ${KUBECTL_PATH}/${f##*/}******"
    fi
done


echo "******更新集群成功******"