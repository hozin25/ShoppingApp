# GitHub Secrets 配置指南

## 必需的 GitHub Secrets

在 GitHub 仓库中配置以下 Secrets（Settings → Secrets and variables → Actions → New repository secret）

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `SSH_PRIVATE_KEY` | 服务器 SSH 私钥内容 | `-----BEGIN RSA PRIVATE KEY-----\n...` |
| `SSH_HOST` | 服务器 IP 地址 | `47.239.7.215` |
| `SSH_USERNAME` | SSH 登录用户名 | `root` |
| `SSH_PORT` | SSH 端口（可选，默认 22） | `22` |
| `MYSQL_PASSWORD` | MySQL root 密码 | `YourMySQLPassword123` |
| `DB_PASSWORD` | 应用数据库用户密码 | `Abc123!@#456` |

## 获取 SSH 私钥

### 在本地 Windows 机器上

```bash
cat C:\Users\Administrator\Downloads\shopping.pem
```

### 在服务器上（如果需要生成新的密钥对）

```bash
# 1. 生成新的 SSH 密钥对（如果还没有）
ssh-keygen -t rsa -b 4096 -C "github-actions"

# 2. 复制公钥到服务器的 authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# 3. 复制私钥内容（将整个内容复制到 GitHub Secrets）
cat ~/.ssh/id_rsa
```

### 将私钥复制到 GitHub Secrets

1. 复制整个私钥文件内容（包括 `-----BEGIN RSA PRIVATE KEY-----` 和 `-----END RSA PRIVATE KEY-----`）
2. 在 GitHub 仓库中：Settings → Secrets and variables → Actions → New repository secret
3. Name: `SSH_PRIVATE_KEY`
4. Secret: 粘贴私钥内容
5. 点击 Add secret

## 配置 GitHub Environments（环境保护）

在 GitHub 仓库中配置 Production 环境：

1. 进入仓库 **Settings** → **Environments**
2. 点击 **New environment**
3. 名称填写：`production`
4. 配置保护规则：
   - ✅ **Required reviewers**：选择需要批准部署的人员
   - ✅ **Wait timer**：设置等待时间（可选，如 30 分钟）
   - ✅ **Deployment branches**：只允许 `main` 或 `master` 分支部署

这样配置后，部署 job 会显示为 "Waiting for approval"，需要指定人员手动点击批准。

## 服务器端配置

确保服务器已正确配置：

```bash
# 1. 确保 SSH 密钥登录可用
sudo chmod 600 /home/youruser/.ssh/authorized_keys
sudo chmod 700 /home/youruser/.ssh

# 2. 确保 app 目录存在且有正确权限
sudo mkdir -p /opt/app /opt/app/backups /opt/app/logs
sudo mkdir -p /opt/mall-frontend
sudo mkdir -p /opt/mall-mobile

# 3. 设置目录所有者
sudo chown -R $USER:$USER /opt/app /opt/mall-frontend /opt/mall-mobile

# 4. 配置 Nginx（参考 deployment/nginx/mall.conf）
sudo cp deployment/nginx/mall.conf /etc/nginx/conf.d/
sudo nginx -t
sudo systemctl reload nginx
```

## 首次部署流程

```bash
# 1. 在 GitHub 仓库设置 Secrets 和 Environment

# 2. 提交 CI/CD 配置文件
git add .github/workflows/deploy.yml
git add scripts/deploy/
git add deployment/

# 3. 推送代码触发 CI/CD
git commit -m "Add CI/CD deployment configuration"
git push origin main

# 4. 在 GitHub Actions 页面查看构建状态

# 5. 构建成功后，手动批准部署到生产环境
```

## 监控和验证

### 检查部署状态

在 GitHub 仓库中：
- **Actions** 标签页：查看所有 workflow 运行记录
- **点击具体的运行**：查看详细日志
- **Environments** 页面：查看部署历史

### 验证部署成功

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

## 故障排查

### SSH 连接失败

- 检查 `SSH_PRIVATE_KEY` Secret 是否正确
- 检查服务器防火墙是否开放 SSH 端口
- 检查服务器 SSH 配置允许密钥登录

### 测试失败

- 查看测试报告 Artifacts
- 下载并检查具体失败的测试日志

### 后端启动失败

```bash
# 查看日志
ssh root@47.239.7.215 'tail -100 /opt/app/logs/application.log'
```

### Nginx 配置错误

```bash
# 测试配置
ssh root@47.239.7.215 'sudo nginx -t'

# 查看错误日志
ssh root@47.239.7.215 'sudo tail -f /var/log/nginx/error.log'
```

### 回滚部署

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

## 自动化测试

确保后端项目包含测试用例。测试文件位于：
- `server/src/test/java/com/jlwl/ShoppingApplicationTests.java`

当前测试包括：
- Spring Boot 上下文加载测试
- 后端 API 基本访问测试

如需添加更多测试，请在该目录下创建相应的测试类。
