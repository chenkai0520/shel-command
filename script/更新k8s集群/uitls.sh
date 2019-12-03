#!/bin/bash

# 输出颜色字符 警告：黄色，错误：红色
console () {
    type=$2
    if [[ "${type}" = "" ]]
    then
        type="i"
    fi
    case $type in
        w)
            echo -e "\e[33m WARNING: ${1} \e[0m"
            ;;
        e)
            echo -e "\e[31m ERROR: ${1} \e[0m"
            ;;
        i)
            echo -e "${1}"
            ;;
        ?) 
            echo -e "${1}"
            ;;
    esac
}



# 对比版本大小函数
vercomp () {
    if [[ $1 == $2 ]]
    then
        # echo "$1 = $2"
        echo "0"
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            # echo "$1 > $2"
            echo "1"
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo "2"
            # echo "$1 < $2"
            return 2
        fi
    done
    # echo "$1 = $2"
    echo "0"
    return 0
}