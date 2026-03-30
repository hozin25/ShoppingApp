#!/bin/bash

BACKUP_DIR="/opt/app/backups"
JAR_FILE="/opt/app/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

if [ -f "$JAR_FILE" ]; then
    cp $JAR_FILE "$BACKUP_DIR/zhinengxiaochengxsc-$TIMESTAMP.jar"
    echo "已备份到: $BACKUP_DIR/zhinengxiaochengxsc-$TIMESTAMP.jar"

    # 只保留最近 5 个备份
    ls -t $BACKUP_DIR/zhinengxiaochengxsc-*.jar | tail -n +6 | xargs rm -f
else
    echo "没有找到需要备份的 JAR 文件"
fi
