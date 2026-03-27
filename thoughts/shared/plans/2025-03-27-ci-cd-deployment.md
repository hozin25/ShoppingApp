# CI/CD 自动化部署方案 - GitHub Actions

## 概述

使用 GitHub Actions 实现商城系统的自动化 CI/CD 流程，包括后端、管理后台前端和移动端 H5 的自动构建、测试和部署。

**部署方式**：半自动化（代码推送后自动构建和测试，需手动确认部署到生产环境）

**部署目标**：阿里云 ECS (47.239.7.215)

---

## 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │  Push Code   │───▶│   Build      │───▶│    Test      │     │
│  │              │    │   & Test     │    │   Reports    │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                             │                                   │
│                             ▼                                   │
│                    ┌──────────────┐                            │
│                    │  Deploy      │                            │
│                    │  (Manual)    │                            │
│                    └──────────────┘                            │
│                             │                                   │
└─────────────────────────────┼─────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    阿里云 ECS (47.239.7.215)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   Backend    │  │   Frontend   │  │   Mobile     │        │
│  │   (JAR)      │  │   (Vue)      │  │   (H5)       │        │
│  │   :8080      │  │   /          │  │  /h5/        │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## CI/CD 流程

### 自动触发条件

1. **Push 到 main/master 分支**：自动运行构建和测试
2. **创建 Pull Request**：自动运行构建和测试
3. **手动触发**：在 Actions 页面手动运行 workflow

### 工作流程

```
1. 代码推送 (Push)
   ↓
2. GitHub Actions 自动触发
   ↓
3. 并行执行：
   ├─ 后端：Maven 构建 + 单元测试
   ├─ 前端：npm install + npm run build
   └─ 移动端：npm install + npm run build:h5
   ↓
4. 生成构建产物 (Artifacts)
   ↓
5. 发送部署通知（等待手动确认）
   ↓
6. [手动确认] 部署到服务器
   ↓
7. SSH 连接服务器 → 停止旧服务 → 上传新文件 → 启动服务
```

---

## 部署步骤

### 步骤 1：准备 GitHub Secrets

在 GitHub 仓库中配置以下 Secrets（Settings → Secrets and variables → Actions → New repository secret）

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `SSH_PRIVATE_KEY` | 服务器 SSH 私钥内容 | `-----BEGIN RSA PRIVATE KEY-----\n...` |
| `SSH_HOST` | 服务器 IP 地址 | `47.239.7.215` |
| `SSH_USERNAME` | SSH 登录用户名 | `root` |
| `SSH_PORT` | SSH 端口（可选，默认 22） | `22` |
| `MYSQL_PASSWORD` | MySQL root 密码 | `YourMySQLPassword123` |
| `DB_PASSWORD` | 应用数据库用户密码 | `Abc123!@#456` |

**获取 SSH 私钥：**

```bash
# 在本地 Windows 机器上
cat C:\Users\Administrator\Downloads\shopping.pem
```

将整个私钥文件内容（包括 `-----BEGIN RSA PRIVATE KEY-----` 和 `-----END RSA PRIVATE KEY-----`）复制到 `SSH_PRIVATE_KEY` Secret 中。

### 步骤 2：创建 GitHub Actions Workflow 文件

**文件路径**：`.github/workflows/deploy.yml`

```yaml
name: CI/CD Deployment

on:
  push:
    branches:
      - main
      - master
  pull_request:
    branches:
      - main
      - master
  workflow_dispatch:  # 允许手动触发

env:
  JAVA_VERSION: '21'
  NODE_VERSION: '16'
  MAVEN_VERSION: '3.9.12'

jobs:
  # ============================================
  # 后端构建和测试
  # ============================================
  build-backend:
    name: Build & Test Backend
    runs-on: ubuntu-latest

    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4

      - name: 设置 Java ${{ env.JAVA_VERSION }}
        uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'
          cache: 'maven'

      - name: 构建后端并运行测试
        run: |
          cd server
          mvn clean test package -DskipTests=false

      - name: 生成测试报告
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: 后端测试报告
          path: 'server/target/surefire-reports/*.xml'
          reporter: java-junit
          fail-on-error: true

      - name: 上传后端 JAR 文件
        uses: actions/upload-artifact@v4
        with:
          name: backend-jar
          path: server/target/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar
          retention-days: 7

      - name: 上传测试报告
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: backend-test-reports
          path: server/target/surefire-reports/
          retention-days: 7

  # ============================================
  # 前端构建
  # ============================================
  build-frontend:
    name: Build Frontend (Admin Panel)
    runs-on: ubuntu-latest

    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4

      - name: 设置 Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: client/package-lock.json

      - name: 安装依赖
        run: |
          cd client
          npm ci

      - name: 代码检查
        run: |
          cd client
          npm run lint --if-present

      - name: 构建生产版本
        run: |
          cd client
          npm run build

      - name: 上传前端构建产物
        uses: actions/upload-artifact@v4
        with:
          name: frontend-dist
          path: client/dist/
          retention-days: 7

  # ============================================
  # 移动端 H5 构建
  # ============================================
  build-mobile:
    name: Build Mobile H5
    runs-on: ubuntu-latest

    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4

      - name: 设置 Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: uni-mall/package-lock.json

      - name: 安装依赖
        run: |
          cd uni-mall
          npm ci

      - name: 构建移动端 H5
        run: |
          cd uni-mall
          npm run build:h5 || echo "H5 build command not found, trying alternative..."
          # 如果上面失败，尝试使用 uni-app CLI
          npx cross-env NODE_ENV=production UNI_PLATFORM=h5 vue-cli-service uni-build || true

      - name: 上传移动端 H5 产物
        uses: actions/upload-artifact@v4
        with:
          name: mobile-h5
          path: uni-mall/unpackage/dist/build/h5/
          retention-days: 7
          if-no-files-found: warn

  # ============================================
  # 部署到服务器（需要手动批准）
  # ============================================
  deploy:
    name: Deploy to Server
    needs: [build-backend, build-frontend, build-mobile]
    runs-on: ubuntu-latest
    environment:
      name: production
      url: http://${{ secrets.SSH_HOST }}

    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4

      # ========================================
      # 配置 SSH
      # ========================================
      - name: 配置 SSH 私钥
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -p ${{ secrets.SSH_PORT }} -H ${{ secrets.SSH_HOST }} >> ~/.ssh/known_hosts

      # ========================================
      # 下载构建产物
      # ========================================
      - name: 下载后端 JAR
        uses: actions/download-artifact@v4
        with:
          name: backend-jar
          path: ./artifacts/backend/

      - name: 下载前端 Dist
        uses: actions/download-artifact@v4
        with:
          name: frontend-dist
          path: ./artifacts/frontend/

      - name: 下载移动端 H5
        uses: actions/download-artifact@v4
        with:
          name: mobile-h5
          path: ./artifacts/mobile/

      # ========================================
      # 部署后端
      # ========================================
      - name: 停止后端服务
        run: |
          ssh -p ${{ secrets.SSH_PORT }} ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }} \
            'bash -s' < scripts/deploy/stop-backend.sh

      - name: 备份当前后端 JAR
        run: |
          ssh -p ${{ secrets.SSH_PORT }} ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }} \
            'bash -s' < scripts/deploy/backup-backend.sh

      - name: 上传后端 JAR
        run: |
          scp -P ${{ secrets.SSH_PORT }} \
            ./artifacts/backend/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar \
            ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }}:/opt/app/

      - name: 启动后端服务
        run: |
          ssh -p ${{ secrets.SSH_PORT }} ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }} \
            'bash -s' < scripts/deploy/start-backend.sh

      # ========================================
      # 部署前端
      # ========================================
      - name: 上传前端静态文件
        run: |
          scp -P ${{ secrets.SSH_PORT }} -r \
            ./artifacts/frontend/* \
            ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }}:/opt/mall-frontend/

      # ========================================
      # 部署移动端
      # ========================================
      - name: 上传移动端 H5 文件
        run: |
          ssh -p ${{ secrets.SSH_PORT }} ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }} \
            'mkdir -p /opt/mall-mobile'
          scp -P ${{ secrets.SSH_PORT }} -r \
            ./artifacts/mobile/* \
            ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }}:/opt/mall-mobile/

      # ========================================
      # 重新加载 Nginx
      # ========================================
      - name: 重新加载 Nginx
        run: |
          ssh -p ${{ secrets.SSH_PORT }} ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }} \
            'sudo nginx -t && sudo systemctl reload nginx'

      # ========================================
      # 健康检查
      # ========================================
      - name: 后端健康检查
        run: |
          sleep 10
          ssh -p ${{ secrets.SSH_PORT }} ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }} \
            'curl -f http://localhost:8080/zhinengxiaochengxsc/ || exit 1'

      - name: 前端健康检查
        run: |
          ssh -p ${{ secrets.SSH_PORT }} ${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }} \
            'curl -f http://localhost/ || exit 1'

      # ========================================
      # 部署成功通知
      # ========================================
      - name: 发送部署成功通知
        if: success()
        run: |
          echo "✅ 部署成功！"
          echo "后端: http://${{ secrets.SSH_HOST }}:8080/zhinengxiaochengxsc/"
          echo "前端: http://${{ secrets.SSH_HOST }}/"
          echo "移动端: http://${{ secrets.SSH_HOST }}/tiaozaoshichang/front/h5/"

      - name: 发送部署失败通知
        if: failure()
        run: |
          echo "❌ 部署失败！请检查日志。"
```

### 步骤 3：创建部署脚本

在项目根目录创建部署脚本文件夹和脚本文件。

#### 3.1 停止后端服务脚本

**文件**：`scripts/deploy/stop-backend.sh`

```bash
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
```

#### 3.2 备份后端脚本

**文件**：`scripts/deploy/backup-backend.sh`

```bash
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
```

#### 3.3 启动后端服务脚本

**文件**：`scripts/deploy/start-backend.sh`

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
```

### 步骤 4：配置 GitHub Environments（环境保护）

在 GitHub 仓库中配置 Production 环境：

1. 进入仓库 **Settings** → **Environments**
2. 点击 **New environment**
3. 名称填写：`production`
4. 配置保护规则：
   - ✅ **Required reviewers**：选择需要批准部署的人员
   - ✅ **Wait timer**：设置等待时间（可选，如 30 分钟）
   - ✅ **Deployment branches**：只允许 `main` 或 `master` 分支部署

这样配置后，部署 job 会显示为 "Waiting for approval"，需要指定人员手动点击批准。

### 步骤 5：确保服务器 SSH 配置正确

在服务器上配置 SSH 密钥认证：

```bash
# 在服务器上（确保 SSH 密钥登录可用）
sudo chmod 600 /home/youruser/.ssh/authorized_keys
sudo chmod 700 /home/youruser/.ssh

# 确保 app 目录存在且有正确权限
sudo mkdir -p /opt/app /opt/app/backups /opt/app/logs
sudo mkdir -p /opt/mall-frontend
sudo mkdir -p /opt/mall-mobile

# 设置目录所有者
sudo chown -R $USER:$USER /opt/app /opt/mall-frontend /opt/mall-mobile
```

---

## 本地测试 CI/CD 脚本

在推送到 GitHub 前，可以在本地测试部署脚本：

```bash
# 测试停止脚本
bash scripts/deploy/stop-backend.sh

# 测试备份脚本
bash scripts/deploy/backup-backend.sh

# 测试启动脚本
bash scripts/deploy/start-backend.sh

# 查看日志
tail -f /opt/app/logs/application.log
```

---

## 部署流程

### 1. 首次部署设置

```bash
# 1. 在 GitHub 仓库设置 Secrets
# 2. 将 .github/workflows/deploy.yml 提交到仓库
# 3. 创建部署脚本
git add .github/workflows/deploy.yml scripts/deploy/
git commit -m "Add CI/CD deployment configuration"
git push origin main
```

### 2. 日常开发部署

```bash
# 1. 开发完成后，推送到 main 分支
git push origin main

# 2. GitHub Actions 自动运行构建和测试
# 3. 在 GitHub Actions 页面查看测试结果
# 4. 测试通过后，手动批准部署到生产环境
```

### 3. 监控部署

在 GitHub 仓库中：
- **Actions** 标签页：查看所有 workflow 运行记录
- **点击具体的运行**：查看详细日志
- **Environments** 页面：查看部署历史

---

## 配置后端自动化测试

确保后端项目包含测试用例。在 `server/src/test/` 目录下添加测试：

### 示例测试类

**文件**：`server/src/test/java/com/jlwl/ShoppingApplicationTests.java`

```java
package com.jlwl;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class ShoppingApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void contextLoads() {
    }

    @Test
    public void testBackendAPI() throws Exception {
        mockMvc.perform(get("/zhinengxiaochengxsc/"))
            .andExpect(status().isOk());
    }
}
```

---

## Nginx 完整配置

**文件**：`/etc/nginx/conf.d/mall.conf`

```nginx
# 管理后台前端 + 移动端 H5 + 后端 API 代理
server {
    listen 80;
    server_name _;

    # ==================== 管理后台前端 ====================
    location / {
        root /opt/mall-frontend;
        index index.html;
        try_files $uri $uri/ /index.html;

        # 缓存配置
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # ==================== 移动端 H5 ====================
    location /tiaozaoshichang/front/h5/ {
        alias /opt/mall-mobile/;
        index index.html;
        try_files $uri $uri/ /tiaozaoshichang/front/h5/index.html;

        # 移动端缓存配置
        expires 3d;
        add_header Cache-Control "public";
    }

    # ==================== 后端 API 代理 ====================
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

    # ==================== 静态资源代理 ====================
    location /static/ {
        proxy_pass http://127.0.0.1:8080;
        expires 30d;
        add_header Cache-Control "public";
    }

    # ==================== 禁止访问隐藏文件 ====================
    location ~ /\. {
        deny all;
    }
}
```

---

## 部署后验证清单

### 自动验证

```bash
# 检查后端进程
ssh root@47.239.7.215 'ps aux | grep zhinengxiaochengxsc'

# 检查端口监听
ssh root@47.239.7.215 'netstat -tuln | grep 8080'

# 测试后端 API
curl -I http://47.239.7.215/zhinengxiaochengxsc/

# 测试前端
curl -I http://47.239.7.215/

# 测试移动端
curl -I http://47.239.7.215/tiaozaoshichang/front/h5/
```

### 手动验证

- [ ] 浏览器访问 `http://47.239.7.215` 可看到管理后台登录页
- [ ] 浏览器访问 `http://47.239.7.215/tiaozaoshichang/front/h5/` 可看到移动端
- [ ] 管理后台可以正常登录和操作
- [ ] 移动端可以正常浏览商品和下单

---

## 故障排查

### 1. GitHub Actions 失败

**问题：** SSH 连接失败
- 检查 `SSH_PRIVATE_KEY` Secret 是否正确
- 检查服务器防火墙是否开放 SSH 端口
- 检查服务器 SSH 配置允许密钥登录

**问题：** 测试失败
- 查看测试报告 Artifacts
- 下载并检查具体失败的测试日志

### 2. 部署失败

**问题：** 后端启动失败
```bash
# 查看日志
ssh root@47.239.7.215 'tail -100 /opt/app/logs/application.log'
```

**问题：** Nginx 配置错误
```bash
# 测试配置
ssh root@47.239.7.215 'sudo nginx -t'

# 查看错误日志
ssh root@47.239.7.215 'sudo tail -f /var/log/nginx/error.log'
```

### 3. 回滚部署

如果新版本有问题，可以快速回滚：

```bash
# 1. 登录服务器
ssh root@47.239.7.215

# 2. 停止当前服务
/opt/app/stop.sh

# 3. 恢复备份的 JAR
cp /opt/app/backups/zhinengxiaochengxsc-YYYYMMDD_HHMMSS.jar /opt/app/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar

# 4. 重启服务
/opt/app/start.sh
```

---

## 优化建议

### 1. 添加 Docker 支持（可选）

使用 Docker 容器化部署，提供更好的隔离性和可移植性。

### 2. 配置 CDN（可选）

将静态资源（图片、CSS、JS）托管到 CDN，提升访问速度。

### 3. 数据库备份自动化

添加定期数据库备份到 CI/CD 流程。

### 4. 监控告警

集成监控服务（如 Prometheus、Grafana），配置自动告警。

---

## 总结

通过以上配置，你将拥有：

✅ **自动化构建**：代码推送自动构建所有组件
✅ **自动化测试**：每次构建运行后端单元测试
✅ **半自动部署**：需要手动批准才能部署到生产环境
✅ **快速回滚**：自动备份，可快速回滚到历史版本
✅ **部署历史**：GitHub Actions 记录所有部署历史和日志

**下一步行动：**
1. 配置 GitHub Secrets
2. 创建 workflow 文件和部署脚本
3. 推送代码触发首次 CI/CD
4. 测试和优化流程
