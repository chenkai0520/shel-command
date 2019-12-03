更新集群和数据库

# 目录介绍
+ backup:更新后存放数据库备份，yaml文件备份
+ images:存放需要更新的镜像tar包
+ yamls:存放需要更新到yaml文件
+ sql:存放更新的sql。sql文件命名规则:version__description.sql,如：`2.1.1__create_table_g_job_api.sql`
+ sql_project: 存放项目定制更新的sql

# 更新命令

```shell
<!-- 更新镜像 -->
./update.sh


<!-- 更新数据库 默认备份数据库并更新到最新版本-->
./db_update.sh
<!-- 不进行数据库备份 -->
./db_update.sh -n
<!-- 不进行数据库备份,更新数据库到1.1.0 -->
./db_update.sh -n -v 1.1.0
```

# 常用命令
+ 数据库恢复: `pg_restore -d g_default -U postgres -f ./geohey_dump.dump`
+ 发送文件: `scp -r /Users/chenkai/gh/geohey_update root@192.168.31.42:/root`
+ 发送时忽略（.）开头的文件文件: `rsync -avPz -e ssh --exclude='.*' /Users/chenkai/gh/geohey_update root@192.168.31.42:/root/`
+ 可执行权限: `chmod +x ./update.sh`