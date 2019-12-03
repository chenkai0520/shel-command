#!/bin/bash

CURRENT_PATH=$( dirname "${BASH_SOURCE[0]}" )
cd "$CURRENT_PATH"

# 配置文件
source ./config.sh
# 工具函数
source ./uitls.sh


i_dump="true"
# 获取命令行参数
while getopts "v:n" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        v)
            to_version="$OPTARG"
            if [[ !("${to_version}" =~ ^[0-9]+[0-9.]+[0-9]+$) ]]
            then
            console "版本参数错误" "e"
            exit
            fi
            ;;
        n)
            i_dump="false"
            ;;
        ?)  #当有不认识的选项的时候arg为?
            console "未知参数" "e"
            exit
        ;;
    esac
done




# 更新表是否存在不存在创建
is_exit_geohey_version=$(psql -v "ON_ERROR_STOP=1" -h $host -p $port -U $user -d $db_name -c "SELECT EXISTS ( SELECT 1 FROM pg_tables WHERE  schemaname = 'public' AND tablename = 'geohey_version') " | grep -v exists |grep t )

# 如果不存在更新记录表则创建
if [[ !("$is_exit_geohey_version" =~ ^.?t.?$) ]]
then
    psql -v "ON_ERROR_STOP=1" -h $host -p $port -U $user -d $db_name -c " CREATE TABLE public.geohey_version ( id bigserial NOT NULL, name text COLLATE pg_catalog.default NOT NULL, version text COLLATE pg_catalog.default NOT NULL, update_time timestamp without time zone NOT NULL DEFAULT now(), CONSTRAINT geohey_update_pkey PRIMARY KEY (id) ) "
fi

if [ "$?" -ne 0 ]
then
    console "创建public.geohey_version表失败" "e"
    exit
fi




# 查询当前最大版本
max_version=$(psql -v "ON_ERROR_STOP=1" -h $host -p $port -U $user -d $db_name -c " SELECT version FROM public.geohey_version ORDER BY string_to_array(version, '.')::int[] desc limit 1" | grep -v version | grep -v -|grep -v row)

if [[ ! ${max_version} = "" ]]
then
    # 如果当前最大版本大于|等于要更新的版本退出
    vercomp_sult=$(vercomp ${max_version} ${to_version})
    if [[ "${to_version}" && vercomp_sult -eq 1 || vercomp_sult -eq 0 ]]
    then
        console "******当前版本:${max_version}  大于|等于  要更新的版本:${to_version}; 退出******" "e"
        exit
    fi
fi


# 默认进行数据库备份
if [[ ${i_dump} = "true" ]]
then
    # 数据库备份
    echo "******开始备份数据库******"
    pg_dump -v -Fc -h $host -p $port -U $user -d $db_name -f ./backup/geohey_dump.tar
    if [ "$?" -eq 0 ]
    then 
        echo "******结束备份数据库******"
    else
        console "备份数据库失败" "e"
        exit
    fi
fi


# 更新数据库
echo "******开始更新数据库******"


# 按照版本大小的顺序遍历文件执行更新命令
# 逐次执行sql文件，如果public.geohey_version表存在该记录跳过否则执行更新

sql_files=$(ls ./sqls/ | sort -V)
for f in ${sql_files}
# for f in ./sqls/*
do  

    if [[ "$f" = "utils" ]]
    then 
        continue
    fi

    # f_name="${f##*/}"
    f_version="${f%__*}"

    # 当前要更新的文件版本小于|等于最大版本则跳过
    vercomp_sult=$(vercomp ${f_version} ${max_version})

    if [[ "${max_version}" &&  vercomp_sult -eq 2 || vercomp_sult -eq 0 ]]
    then
        continue
    fi

    # 当前要更新的文件版本大于要更新的版本则跳过
    vercomp_sult=$(vercomp ${f_version} ${to_version})

    if [[ "${to_version}" && vercomp_sult -eq 1 ]]
    then
        break
    fi

    # 执行要更新的文件
    psql -v "ON_ERROR_STOP=1" -h $host -p $port -U $user -d $db_name -f "./sqls/${f}"
    if [ "$?" -eq 0 ]
    then 
        psql -v "ON_ERROR_STOP=1" -h $host -p $port -U $user -d $db_name -c " INSERT INTO public.geohey_version( name,version) VALUES ('${f##*/}','${f_version}'); "
    else
        console "执行文件: ${f}时失败，请检查" "e"
        break
    fi

done

max_version=$(psql -v "ON_ERROR_STOP=1" -h $host -p $port -U $user -d $db_name -c " SELECT version FROM public.geohey_version ORDER BY string_to_array(version, '.')::int[] desc limit 1" | grep -v version | grep -v -|grep -v row)
echo "******更新数据库到:${max_version}******"