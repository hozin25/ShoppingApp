#!/bin/bash

echo "正在停止后端服务..."

if [ -f "/opt/app/stop.sh" ]; then
    /opt/app/stop.sh
    echo "后端服务已停止"
else
    # 如果 stop.sh 不存在，手动停止
    if [ -f "/opt/app/app.pid" ]; then
        PID=$(cat /opt/app/app.pid)
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            echo "已停止进程 $PID"
        fi
    fi
fi
