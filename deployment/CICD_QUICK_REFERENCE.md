# CI/CD 快速参考卡

## 🚀 快速开始

### 首次部署（3 步）

```bash
# 1️⃣ 在 GitHub 配置 Secrets（必需）
SSH_PRIVATE_KEY, SSH_HOST, SSH_USERNAME, SSH_PORT

# 2️⃣ 推送代码触发 CI/CD
git add .github/ scripts/ deployment/ server/src/test/
git commit -m "Add CI/CD"
git push origin main

# 3️⃣ 在 GitHub Actions 页面批准部署
```

---

## 📋 GitHub Secrets 清单

| Secret | 值示例 | 必需 |
|--------|--------|------|
| `SSH_PRIVATE_KEY` | `-----BEGIN RSA...` | ✅ |
| `SSH_HOST` | `47.239.7.215` | ✅ |
| `SSH_USERNAME` | `root` | ✅ |
| `SSH_PORT` | `22` | 可选 |
| `MYSQL_PASSWORD` | `yourpwd` | 可选 |
| `DB_PASSWORD` | `yourpwd` | 可选 |

---

## 🔧 常用命令

### 本地测试部署脚本

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

### 服务器验证

```bash
# 检查后端进程
ssh root@47.239.7.215 'ps aux | grep zhinengxiaochengxsc'

# 检查端口
ssh root@47.239.7.215 'netstat -tuln | grep 8080'

# 测试 API
curl -I http://47.239.7.215/zhinengxiaochengxsc/
curl -I http://47.239.7.215/
curl -I http://47.239.7.215/tiaozaoshichang/front/h5/
```

### 回滚部署

```bash
ssh root@47.239.7.215
/opt/app/stop.sh
cp /opt/app/backups/zhinengxiaochengxsc-YYYYMMDD_HHMMSS.jar /opt/app/
/opt/app/start.sh
```

---

## 📊 CI/CD 流程

```
Push → 构建 → 测试 → [等待批准] → 部署 → 验证
         ↓         ↓
      并行执行   生成报告
    - 后端     - 测试结果
    - 前端     - 代码覆盖率
    - 移动端   - 构建日志
```

---

## 📁 文件结构

```
.github/
└── workflows/
    └── deploy.yml          # GitHub Actions 工作流

scripts/
└── deploy/
    ├── stop-backend.sh     # 停止服务
    ├── backup-backend.sh   # 备份 JAR
    └── start-backend.sh    # 启动服务

deployment/
├── nginx/
│   └── mall.conf          # Nginx 配置
├── GITHUB_SETS_SETUP.md   # 详细设置指南
├── CICD_IMPLEMENTATION_SUMMARY.md  # 实施总结
└── CICD_QUICK_REFERENCE.md # 本文件

server/src/test/
└── java/com/jlwl/
    └── ShoppingApplicationTests.java  # 单元测试
```

---

## ⚡ 快速故障排查

| 问题 | 检查项 | 命令 |
|------|--------|------|
| SSH 失败 | 密钥、防火墙 | 检查 Secrets |
| 测试失败 | 代码、依赖 | 查看测试报告 |
| 启动失败 | 日志、配置 | `tail -f logs/application.log` |
| Nginx 错误 | 配置语法 | `nginx -t` |
| 404 错误 | 路径、权限 | 检查 Nginx 配置 |

---

## 🔗 重要链接

- **GitHub Actions**: `https://github.com/你的仓库/actions`
- **Secrets 配置**: Settings → Secrets and variables → Actions
- **环境配置**: Settings → Environments → production
- **详细文档**: `deployment/GITHUB_SETS_SETUP.md`

---

## ✅ 部署检查清单

### 部署前
- [ ] 代码已提交并推送
- [ ] 所有测试通过
- [ ] GitHub Secrets 已配置
- [ ] 生产环境已设置

### 部署后
- [ ] 后端服务运行正常
- [ ] 前端页面可访问
- [ ] 移动端 H5 可访问
- [ ] API 调用正常
- [ ] 日志无错误

---

## 💡 提示

1. **首次部署**：建议在测试环境先验证
2. **生产部署**：确保有回滚计划
3. **监控日志**：部署后密切关注应用日志
4. **定期备份**：保留最近 5 个 JAR 备份
5. **权限管理**：限制 GitHub Environment 批准人员

---

## 🆘 获取帮助

1. 查看 `deployment/GITHUB_SETS_SETUP.md`
2. 检查 GitHub Actions 日志
3. 查看服务器日志：`/opt/app/logs/application.log`
4. 查看 Nginx 日志：`/var/log/nginx/error.log`

---

**版本**: 1.0
**更新**: 2026-03-30
