# 阿里云服务器部署计划

## 部署进度记录

> **最后更新**: 2025-03-17 18:40
> **服务器**: 47.239.7.215 (CentOS 7.9)
> **SSH 密钥**: `C:\Users\Administrator\Downloads\shopping.pem`

### 已完成 ✅

- [x] **阶段 1**: 服务器环境准备
  - [x] Java 21 安装并配置（使用 Java 21 代替 Java 8）
  - [x] MySQL 8.0 安装并运行
  - [x] Maven 3.9.12 安装
  - [x] Node.js 安装
  - [x] Nginx 安装并运行

- [x] **阶段 2**: 数据库部署
  - [x] 重置 MySQL root 密码
  - [x] 创建数据库 `db_mall`
  - [x] 创建数据库用户 `malluser` (密码: Abc123!@#456)
  - [x] 导入数据库表结构

- [x] **阶段 3.1-3.2**: 后端打包和上传
  - [x] 本地打包后端 jar 文件
  - [x] 上传 jar 到服务器 `/opt/app/`

### 进行中 🔄

- [ ] **阶段 3.3**: 创建启动脚本（待执行）
  - 需要执行：创建 start.sh、stop.sh、restart.sh 脚本

### 待办 📋

- [ ] **阶段 3.4-3.7**: 启动后端应用
- [ ] **阶段 4**: 前端部署（管理后台）
- [ ] **阶段 5**: 移动端部署（小程序 H5 版本）

---

## 概述

将商城后台系统部署到阿里云 CentOS 服务器上，包括：
- **后端 API**：Spring Boot 服务（端口 8080）
- **管理面板**：Vue.js 前端（通过 Nginx 静态服务）
- **数据库**：MySQL 5.7/8.0

## 当前状态分析

### 项目技术栈
- **后端**：Spring Boot 2.2.2 + Java 8 + MyBatis-Plus
- **前端**：Vue 2.6.10 + Element UI
- **数据库**：MySQL (db_mall)
- **构建工具**：Maven 3.x / npm

### 关键配置
- 后端端口：8080，context path：`/zhinengxiaochengxsc`
- 数据库：db_mall，端口 3306
- 文件上传最大：1000MB

## 期望的最终状态

部署完成后，用户可以通过以下方式访问：
- **管理后台**：`http://服务器IP:80` （Nginx 代理前端静态文件 + 后端 API）
- **API 接口**：`http://服务器IP/zhinengxiaochengxsc/...`

### 验证方式
1. 浏览器访问管理后台可正常登录
2. API 接口返回正确的 JSON 数据
3. 文件上传功能正常
4. 数据库连接稳定

## 不包含的内容

- 域名配置和 SSL 证书（可后续添加）
- uni-mall 移动端部署
- RDS 云数据库配置
- 高可用集群部署
- 自动化 CI/CD 流程

## 部署架构

```
┌─────────────────────────────────────────────────────┐
│                   阿里云 ECS                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│   ┌──────────────┐      ┌──────────────┐          │
│   │   Nginx      │      │   MySQL      │          │
│   │   :80        │      │   :3306      │          │
│   │              │      │              │          │
│   │  ┌────────┐  │      │  db_mall     │          │
│   │  │ 前端    │  │      └──────────────┘          │
│   │  │ 静态文件 │  │                               │
│   │  └────────┘  │      ┌──────────────┐          │
│   │              │      │  Java 应用    │          │
│   │  ┌────────┐  │      │  :8080       │          │
│   │  │ API    │◄─┼──────┤              │          │
│   │  │ 代理   │  │      │ Spring Boot  │          │
│   │  └────────┘  │      └──────────────┘          │
│   └──────────────┘                                  │
└─────────────────────────────────────────────────────┘
```

---

## 阶段 1：服务器环境准备

### 概述
在阿里云服务器上安装必要的运行环境

### 所需环境

| 组件 | 版本 | 用途 |
|------|------|------|
| Java JDK | 1.8 | 运行 Spring Boot |
| MySQL | 5.7 或 8.0 | 数据库服务 |
| Maven | 3.6+ | 构建后端项目 |
| Node.js | 14.x 或 16.x | 构建前端项目 |
| Nginx | 1.18+ | Web 服务器和反向代理 |

### 步骤详解

#### 1.1 安装 Java JDK 8

```bash
# 检查是否已安装 Java
java -version

# 如果未安装，使用 yum 安装 OpenJDK 8
sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

# 配置 JAVA_HOME 环境变量
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk' | sudo tee -a /etc/profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee -a /etc/profile
source /etc/profile

# 验证安装
java -version
```

#### 1.2 安装 MySQL 8.0

```bash
# 添加 MySQL 8.0 仓库
sudo yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm

# 安装 MySQL
sudo yum install -y mysql-server

# 启动 MySQL 服务
sudo systemctl start mysqld
sudo systemctl enable mysqld

# 获取临时密码
sudo grep 'temporary password' /var/log/mysqld.log

# 运行安全配置（使用临时密码登录）
sudo mysql_secure_installation
```

**安全配置步骤：**
1. 输入临时密码
2. 设置 root 密码（请记录下来）
3. 是否删除匿名用户：`Y`
4. 是否禁止远程 root 登录：`N`（开发环境允许）
5. 是否删除 test 数据库：`Y`
6. 是否重新加载权限表：`Y`

#### 1.3 安装 Maven

```bash
# 下载 Maven
cd /opt
sudo wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz

# 解压
sudo tar -xzf apache-maven-3.6.3-bin.tar.gz

# 创建软链接
sudo ln -s /opt/apache-maven-3.6.3 /opt/maven

# 配置环境变量
echo 'export MAVEN_HOME=/opt/maven' | sudo tee -a /etc/profile
echo 'export PATH=$MAVEN_HOME/bin:$PATH' | sudo tee -a /etc/profile
source /etc/profile

# 验证安装
mvn -version
```

#### 1.4 安装 Node.js

```bash
# 使用 NodeSource 仓库安装 Node.js 16.x
curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
sudo yum install -y nodejs

# 验证安装
node -v
npm -v

# 配置 npm 淘宝镜像（加速下载）
npm config set registry https://registry.npmmirror.com
```

#### 1.5 安装 Nginx

```bash
# 添加 EPEL 仓库
sudo yum install -y epel-release

# 安装 Nginx
sudo yum install -y nginx

# 启动 Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# 开放防火墙端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

**阿里云安全组配置：**
在阿里云控制台添加安全组规则，开放以下端口：
- 80（HTTP）
- 443（HTTPS，如需要）
- 22（SSH，通常已开放）

### 成功标准

#### 自动化验证：
```bash
# 检查所有组件版本
java -version     # 应显示 1.8.x
mvn -version      # 应显示 3.6.x
node -v           # 应显示 v16.x.x
nginx -v          # 应显示 1.18.x 以上
mysql --version   # 应显示 8.0.x

# 检查服务状态
sudo systemctl status mysqld    # 应为 active (running)
sudo systemctl status nginx     # 应为 active (running)
```

#### 手动验证：
- [ ] 浏览器访问 `http://服务器IP` 可看到 Nginx 欢迎页
- [ ] 可以使用 MySQL 客户端连接数据库

**注意：** 完成此阶段后，请确认所有组件安装成功后再继续下一阶段。

---

## 阶段 2：数据库部署

### 概述
创建数据库、导入数据、配置访问权限

### 步骤详解

#### 2.1 创建数据库和用户

```bash
# 登录 MySQL
mysql -u root -p

# 在 MySQL 命令行中执行：
CREATE DATABASE db_mall DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建专用数据库用户（建议不使用 root）
CREATE USER 'malluser'@'%' IDENTIFIED BY 'YourStrongPassword123!';

-- 授予权限
GRANT ALL PRIVILEGES ON db_mall.* TO 'malluser'@'%';
FLUSH PRIVILEGES;

EXIT;
```

#### 2.2 导入数据库结构

```bash
# 方法一：如果 SQL 文件在服务器上
mysql -u root -p db_mall < /path/to/db_mall.sql

# 方法二：从本地上传 SQL 文件到服务器
# 在本地执行：
scp db_mall.sql root@服务器IP:/root/

# 然后在服务器上执行：
mysql -u root -p db_mall < /root/db_mall.sql

# 验证数据导入
mysql -u root -p -e "USE db_mall; SHOW TABLES;"
```

#### 2.3 修改后端数据库配置

**文件**：`server/src/main/resources/application.yml`

```yaml
spring:
    datasource:
        driver-class-name: com.mysql.cj.jdbc.Driver
        # 修改为实际的服务器配置
        url: jdbc:mysql://127.0.0.1:3306/db_mall?characterEncoding=utf8&useSSL=false&serverTimezone=GMT%2B8&allowPublicKeyRetrieval=true
        username: malluser          # 使用专用用户而非 root
        password: YourStrongPassword123!
```

### 成功标准

#### 自动化验证：
```bash
# 检查数据库是否存在
mysql -u malluser -p'YourStrongPassword123!' -e "SHOW DATABASES;" | grep db_mall

# 检查表是否创建成功
mysql -u malluser -p'YourStrongPassword123!' db_mall -e "SHOW TABLES;" | wc -l
```

#### 手动验证：
- [ ] 可以使用新用户登录数据库
- [ ] 数据库包含所有预期的表（users, yonghu, shangpin 等）

---

## 阶段 3：后端部署

### 概述
打包 Spring Boot 应用并部署到服务器

### 步骤详解

#### 3.1 本地打包后端应用

```bash
# 在项目根目录的 server 文件夹中执行
cd server
mvn clean package -DskipTests

# 打包成功后，jar 文件位于：
# server/target/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar
```

#### 3.2 上传到服务器

```bash
# 在本地执行（使用 scp）
scp server/target/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar root@服务器IP:/opt/app/

# 或者使用文件传输工具（如 WinSCP、FileZilla）上传
```

#### 3.3 创建启动脚本

**文件**：`/opt/app/start.sh`

```bash
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
        echo "应用已在运行 (PID: $PID)"
        exit 1
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
sleep 3

# 检查是否启动成功
if ps -p $(cat $PID_FILE) > /dev/null; then
    echo "应用启动成功! PID: $(cat $PID_FILE)"
    echo "日志文件: $LOG_PATH/application.log"
else
    echo "应用启动失败，请查看日志"
    rm -f $PID_FILE
    exit 1
fi
```

#### 3.4 创建停止脚本

**文件**：`/opt/app/stop.sh`

```bash
#!/bin/bash

PID_FILE="/opt/app/app.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "应用未运行"
    exit 0
fi

PID=$(cat $PID_FILE)

if ps -p $PID > /dev/null 2>&1; then
    echo "正在停止应用 (PID: $PID)..."
    kill $PID

    # 等待进程结束
    for i in {1..30}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            echo "应用已停止"
            rm -f $PID_FILE
            exit 0
        fi
        sleep 1
    done

    # 强制结束
    echo "强制停止应用..."
    kill -9 $PID
    rm -f $PID_FILE
else
    echo "应用进程不存在"
    rm -f $PID_FILE
fi
```

#### 3.5 创建重启脚本

**文件**：`/opt/app/restart.sh`

```bash
#!/bin/bash

/opt/app/stop.sh
sleep 2
/opt/app/start.sh
```

#### 3.6 设置脚本权限并启动

```bash
# 创建应用目录
sudo mkdir -p /opt/app /opt/app/logs

# 上传 jar 文件后，设置权限
sudo chmod +x /opt/app/start.sh
sudo chmod +x /opt/app/stop.sh
sudo chmod +x /opt/app/restart.sh

# 启动应用
/opt/app/start.sh

# 查看日志
tail -f /opt/app/logs/application.log
```

#### 3.7 配置开机自启（可选）

**创建 systemd 服务**：`/etc/systemd/system/mall-backend.service`

```ini
[Unit]
Description=Mall Backend Application
After=network.target mysql.service

[Service]
Type=forking
User=root
WorkingDirectory=/opt/app
ExecStart=/opt/app/start.sh
ExecStop=/opt/app/stop.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# 重载 systemd 配置
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable mall-backend

# 启动服务
sudo systemctl start mall-backend

# 查看状态
sudo systemctl status mall-backend
```

### 成功标准

#### 自动化验证：
```bash
# 检查进程
ps aux | grep zhinengxiaochengxsc

# 检查端口监听
netstat -tuln | grep 8080

# 测试 API
curl -I http://localhost:8080/zhinengxiaochengxsc/
```

#### 手动验证：
- [ ] 查看日志无错误信息
- [ ] 可以访问 `http://服务器IP:8080/zhinengxiaochengxsc/`

**注意：** 完成此阶段并确认后端运行正常后，再继续下一阶段。

---

## 阶段 4：前端部署

### 概述
构建 Vue 管理面板并使用 Nginx 提供静态服务

### 步骤详解

#### 4.1 修改前端 API 配置

**文件**：`client/src/utils/request.js`（或其他 API 配置文件）

确认 axios baseURL 配置，需要指向生产环境的后端地址：

```javascript
// 生产环境应该使用相对路径，让 Nginx 代理
const baseURL = process.env.NODE_ENV === 'production'
  ? '/zhinengxiaochengxsc'  // 生产环境使用相对路径，由 Nginx 代理
  : '/zhinengxiaochengxsc'; // 开发环境
```

#### 4.2 本地构建前端

```bash
cd client

# 安装依赖
npm install

# 构建生产版本
npm run build

# 构建完成后，dist 目录包含所有静态文件
```

#### 4.3 上传到服务器

```bash
# 在本地执行
scp -r client/dist/* root@服务器IP:/opt/mall-frontend/

# 或使用文件传输工具上传
```

#### 4.4 配置 Nginx

**文件**：`/etc/nginx/conf.d/mall.conf`

```nginx
# 管理后台前端
server {
    listen 80;
    server_name _;  # 使用 _ 表示匹配所有域名，或填入具体域名

    # 前端静态文件
    location / {
        root /opt/mall-frontend;
        index index.html;
        try_files $uri $uri/ /index.html;

        # 缓存配置
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # 后端 API 代理
    location /zhinengxiaochengxsc/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 文件上传相关
        client_max_body_size 1000M;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
    }

    # 静态资源代理（如上传的图片等）
    location /static/ {
        proxy_pass http://127.0.0.1:8080;
        expires 30d;
        add_header Cache-Control "public";
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
```

#### 4.5 启动 Nginx

```bash
# 测试配置
sudo nginx -t

# 如果测试通过，重新加载配置
sudo systemctl reload nginx

# 或重启 Nginx
sudo systemctl restart nginx
```

### 成功标准

#### 自动化验证：
```bash
# 检查 Nginx 配置
sudo nginx -t

# 检查前端文件
ls -la /opt/mall-frontend/

# 测试 HTTP 响应
curl -I http://localhost/
```

#### 手动验证：
- [ ] 浏览器访问 `http://服务器IP` 可看到登录页面
- [ ] 登录后可以正常使用管理后台功能
- [ ] API 请求正常（打开浏览器开发者工具 Network 查看无报错）

---

## 测试策略

### 功能测试

1. **登录功能**
   - 使用管理员账号登录
   - 验证 token 存储

2. **数据操作**
   - 查看商品列表
   - 添加/编辑/删除商品
   - 查看订单列表

3. **文件上传**
   - 上传商品图片
   - 验证图片显示

### 性能测试

1. **API 响应时间**
   ```bash
   time curl http://服务器IP/zhinengxiaochengxsc/shangpin/page
   ```

2. **服务器资源监控**
   ```bash
   # 查看内存使用
   free -h

   # 查看磁盘使用
   df -h

   # 查看 Java 进程资源
   top -p $(cat /opt/app/app.pid)
   ```

## 故障排查

### 常见问题

#### 1. 后端启动失败

```bash
# 查看日志
tail -100 /opt/app/logs/application.log

# 常见原因：
# - 数据库连接失败 → 检查 application.yml 配置
# - 端口被占用 → netstat -tuln | grep 8080
# - Java 版本不匹配 → java -version
```

#### 2. 前端页面空白

```bash
# 检查 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# 常见原因：
# - 静态文件路径错误 → 检查 root 路径
# - API 跨域问题 → 检查 Nginx 代理配置
# - vue.config.js publicPath 配置
```

#### 3. 数据库连接失败

```bash
# 检查 MySQL 状态
sudo systemctl status mysqld

# 测试连接
mysql -u malluser -p -h 127.0.0.1

# 检查防火墙
sudo firewall-cmd --list-all
```

## 部署后续建议

### 安全加固

1. **修改默认端口**：将 SSH 端口改为非 22 端口
2. **配置防火墙**：只开放必要的端口
3. **定期备份**：设置数据库自动备份
4. **使用 SSL**：配置 HTTPS（Let's Encrypt 免费证书）

### 运维建议

1. **日志轮转**：配置 logrotate 防止日志文件过大
2. **监控告警**：配置云监控服务
3. **定期更新**：及时安装安全补丁

## 参考信息

- 项目路径：`C:\Users\Administrator\Desktop\workspace\ShoppingApp`
- 后端配置：`server/src/main/resources/application.yml`
- 前端配置：`client/vue.config.js`
- 数据库文件：`server/db_mall.sql`

---

## 快速部署命令清单

```bash
# ========== 阶段 1：环境安装 ==========
# Java 8
sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

# MySQL 8.0
sudo yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
sudo yum install -y mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Maven
cd /opt && sudo wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
sudo tar -xzf apache-maven-3.6.3-bin.tar.gz
sudo ln -s /opt/apache-maven-3.6.3 /opt/maven

# Node.js 16
curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
sudo yum install -y nodejs

# Nginx
sudo yum install -y epel-release
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# ========== 阶段 2：数据库 ==========
# 创建数据库（替换密码）
mysql -u root -p
# 在 MySQL 中执行：
# CREATE DATABASE db_mall DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# CREATE USER 'malluser'@'%' IDENTIFIED BY 'YourPassword123!';
# GRANT ALL PRIVILEGES ON db_mall.* TO 'malluser'@'%';
# FLUSH PRIVILEGES;

# 导入数据
mysql -u root -p db_mall < /path/to/db_mall.sql

# ========== 阶段 3：后端 ==========
# 上传 jar 文件到 /opt/app/
# 创建启动脚本（见上文）
sudo mkdir -p /opt/app /opt/app/logs
/opt/app/start.sh

# ========== 阶段 4：前端 ==========
# 上传 dist 文件到 /opt/mall-frontend/
# 配置 Nginx（见上文）
sudo nginx -t
sudo systemctl reload nginx
```
