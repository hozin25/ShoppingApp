# 智能小程序商城

一个功能完整的全栈电商购物应用，支持多平台部署（微信小程序、H5、支付宝小程序等），配备完善的后台管理系统。

## 项目简介

本项目是一个现代化的智能电商解决方案，采用前后端分离架构，提供：

- **移动端商城** - 基于 uni-app 开发，支持微信小程序、H5、支付宝小程序等多平台
- **后台管理系统** - 基于 Vue.js + Element UI 的管理后台
- **RESTful API** - 基于 Spring Boot 的统一后端服务

集成百度 AI 智能推荐功能，为用户提供个性化购物体验。

## 功能特性

### 移动端商城
- 商品浏览与搜索
- 购物车管理
- 订单管理与支付
- 用户地址管理
- 在线客服聊天
- 论坛社区
- 新闻公告

### 后台管理
- 数据可视化看板（ECharts）
- 商品管理（增删改查、分类）
- 订单管理
- 用户管理
- 商家管理
- 论坛管理
- 新闻公告管理
- 系统配置
- Excel 数据导入导出
- 富文本编辑器
- 二维码生成
- 打印功能

### 技术亮点
- 基于 Apache Shiro 的权限认证
- JWT Token 无状态认证
- RESTful API 设计
- 文件上传与管理
- 百度 AI 智能推荐
- 响应式设计

## 技术栈

### 后端
- **框架**: Spring Boot 2.2.2
- **ORM**: MyBatis-Plus 2.3
- **安全**: Apache Shiro 1.3.2
- **数据库**: MySQL
- **AI**: 百度 AI SDK 4.4.1
- **工具库**: Hutool 4.0.12
- **文档处理**: Apache POI 3.9

### 前端管理面板
- **框架**: Vue.js 2.6.10
- **UI组件**: Element UI 2.15.10
- **路由**: Vue Router 3.1.5
- **HTTP**: Axios 0.19.2
- **图表**: ECharts 4.6.0
- **富文本**: vue-quill-editor 3.0.6
- **二维码**: vue-qr 3.2.2
- **打印**: print-js 1.5.0
- **Excel**: vue-json-excel 0.3.0

### 移动端
- **框架**: uni-app
- **UI库**: ColorUI
- **平台支持**:
  - 微信小程序
  - H5
  - 支付宝小程序
  - 百度小程序
  - 头条小程序
  - Android/iOS App

## 快速开始

### 环境要求
- JDK 8+
- Node.js 12+
- Maven 3.6+
- MySQL 5.7+
- HBuilderX（用于 uni-app 开发）

### 数据库配置

1. 创建数据库：
```sql
CREATE DATABASE db_mall CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. 导入数据表：
```bash
mysql -u root -p db_mall < db_mall.sql
```

### 后端启动

```bash
cd server
mvn clean install
mvn spring-boot:run
```

后端服务将运行在 `http://localhost:8080/zhinengxiaochengxsc`

### 前端管理面板启动

```bash
cd client
npm install
npm run serve
```

管理面板将运行在 `http://localhost:8081`

**注意**: 如遇 Sass 编译问题（Windows 环境），请设置 `SASS_BINARY_PATH` 环境变量。

### 移动端启动

**方法一：使用 HBuilderX**
1. 下载并安装 HBuilderX
2. 导入 `uni-mall` 目录
3. 选择目标平台（微信小程序/H5/等）
4. 点击运行

**方法二：使用命令行**
```bash
cd uni-mall
npm install

# 微信小程序
npm run dev:mp-weixin

# H5
npm run dev:h5
```

## 项目结构

```
shoppingapp/
├── server/                  # Spring Boot 后端
│   ├── src/main/java/com/jlwl/
│   │   ├── controller/      # REST API 控制器
│   │   ├── entity/          # 数据库实体
│   │   ├── dao/             # MyBatis Mapper
│   │   ├── service/         # 业务逻辑层
│   │   └── config/          # 配置类
│   ├── src/main/resources/
│   │   └── application.yml  # 配置文件
│   └── pom.xml              # Maven 依赖
├── client/                  # Vue 管理后台
│   ├── src/
│   │   ├── views/           # 页面组件
│   │   ├── router/          # 路由配置
│   │   ├── api/             # API 服务
│   │   ├── components/      # 公共组件
│   │   └── utils/           # 工具函数
│   └── package.json
├── uni-mall/                # uni-app 移动端
│   ├── pages/               # 页面
│   ├── components/          # 组件
│   ├── uni_modules/         # uni-app 插件
│   ├── static/              # 静态资源
│   ├── manifest.json        # 应用配置
│   └── pages.json           # 页面路由
└── db_mall.sql              # 数据库初始化脚本
```

## API 接口

后端遵循 RESTful 设计规范：

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/{table}/page` | 分页查询 |
| GET | `/{table}/info/{id}` | 根据 ID 查询 |
| POST | `/{table}/save` | 新增记录 |
| PUT | `/{table}/update` | 更新记录 |
| DELETE | `/{table}/{id}` | 删除记录 |

其中 `{table}` 为实体名称，如 `shangpin`（商品）、`yonghu`（用户）、`orders`（订单）等。

## 配置说明

### 后端配置 (`server/src/main/resources/application.yml`)

主要配置项：
- 服务端口：8080
- 上下文路径：`/zhinengxiaochengxsc`
- 数据库连接：MySQL localhost:3306/db_mall
- 文件上传限制：1000MB

### 前端配置 (`client/vue.config.js`)

开发环境代理配置将 `/zhinengxiaochengxsc` 请求代理到后端服务。

## 部署指南

### 后端部署

```bash
cd server
mvn clean package
java -jar target/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar
```

### 前端部署

```bash
cd client
npm run build
```

构建产物在 `client/dist/` 目录，可部署到 Nginx 等静态服务器。

### 移动端部署

使用 HBuilderX 进行云打包或本地打包，发布到对应应用商店。

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目采用 MIT 许可证。

## 联系方式

如有问题或建议，请提交 Issue。

---

**注意**: 本项目仅供学习交流使用，请勿用于商业用途。

---
最后更新: 2026-03-30
