#!/bin/bash

APP_NAME="zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar"
APP_PATH="/opt/app"
LOG_PATH="/opt/app/logs"
PID_FILE="$APP_PATH/app.pid"

# 创建日志目录
mkdir -p $LOG_PATH

# 检查是否已运行
if [ -f "$PID_FILE" ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "应用已在运行 (PID: $PID)，先停止..."
        kill $PID
        sleep 3
    fi
fi

# 启动应用
cd $APP_PATH
nohup java -jar -Xms512m -Xmx1024m $APP_NAME \
    --spring.profiles.active=prod \
    > $LOG_PATH/application.log 2>&1 &

# 保存 PID
echo $! > $PID_FILE

echo "应用启动中..."
sleep 5

# 检查是否启动成功
if ps -p $(cat $PID_FILE) > /dev/null; then
    echo "应用启动成功! PID: $(cat $PID_FILE)"
    echo "日志文件: $LOG_PATH/application.log"
else
    echo "应用启动失败，请查看日志"
    cat $LOG_PATH/application.log
    exit 1
fi
