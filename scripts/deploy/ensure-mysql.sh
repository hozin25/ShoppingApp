#!/bin/bash

set -e

echo "=== 检查MySQL容器状态 ==="

# 检查MySQL容器是否存在
MYSQL_CONTAINER=$(docker ps -a | grep mysql | awk '{print $1}' | head -n 1)

if [ -z "$MYSQL_CONTAINER" ]; then
    echo "❌ 未找到MySQL容器，请手动创建MySQL容器"
    echo "提示: 使用以下命令创建MySQL容器："
    echo "docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=483288fjc -e MYSQL_DATABASE=db_mall mysql:5.7"
    exit 1
fi

echo "找到MySQL容器: $MYSQL_CONTAINER"

# 检查容器状态
MYSQL_STATUS=$(docker inspect --format='{{.State.Status}}' $MYSQL_CONTAINER)
echo "MySQL容器状态: $MYSQL_STATUS"

if [ "$MYSQL_STATUS" != "running" ]; then
    echo "⚠️  MySQL容器未运行，正在启动..."
    docker start $MYSQL_CONTAINER
    echo "✅ MySQL容器已启动"
else
    echo "✅ MySQL容器已在运行"
fi

# 等待MySQL完全启动
echo "⏳ 等待MySQL服务完全启动..."
MAX_WAIT=30
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if docker exec $MYSQL_CONTAINER mysqladmin ping -h localhost -uroot -p483288fjc --silent 2>/dev/null; then
        echo "✅ MySQL已就绪，可以接受连接"
        break
    fi

    WAIT_COUNT=$((WAIT_COUNT + 1))
    echo "等待中... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 1
done

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    echo "❌ MySQL启动超时"
    echo "=== MySQL容器日志 ==="
    docker logs --tail 50 $MYSQL_CONTAINER
    exit 1
fi

# 验证数据库是否存在
echo "=== 验证数据库 ==="
DB_EXISTS=$(docker exec $MYSQL_CONTAINER mysql -uroot -p483288fjc -e "SHOW DATABASES LIKE 'db_mall';" -s --skip-column-names 2>/dev/null)

if [ -z "$DB_EXISTS" ]; then
    echo "❌ 数据库 db_mall 不存在"
    exit 1
else
    echo "✅ 数据库 db_mall 存在"
fi

echo "=== MySQL容器检查完成 ==="
