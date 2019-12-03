# 文件
+ 递归删除文件夹下的文件
```shell
#!/bin/bash
for f in $(ls ./)
do
    if [[ -d $f ]]
    then 
        rm -rf $f
    fi

    if [[ -e $f ]]
    then 
        rm -f $f
    fi
done
```