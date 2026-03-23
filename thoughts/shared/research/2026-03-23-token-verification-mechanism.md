---
date: 2026-03-22 23:08:14 +0800
researcher: Your Name
git_commit: 459ad93743315d5e880071aeabba1d3c6af60d6d
branch: master
repository: ShoppingApp
topic: "进行其他操作时的token验证是怎么实现的"
tags: [research, codebase, authentication, token, interceptor]
status: complete
last_updated: 2026-03-23
last_updated_by: Your Name
---

# Research: 进行其他操作时的token验证是怎么实现的

**Date**: 2026-03-22 23:08:14 +0800
**Researcher**: Your Name
**Git Commit**: 459ad93743315d5e880071aeabba1d3c6af60d6d
**Branch**: master
**Repository**: ShoppingApp

## Research Question

在ShoppingApp项目中，进行其他操作（非登录）时的token验证是如何实现的？

## Summary

项目使用自定义的token验证机制，基于Spring MVC拦截器实现。后端通过`AuthorizationInterceptor`拦截所有请求，从请求头获取`Token`字段，查询数据库验证token有效性。前端（Vue管理后台）通过Axios拦截器自动添加token，移动端（uni-app）通过请求封装自动添加token。Token以32位随机字符串形式存储在数据库中，有效期1小时。

## Detailed Findings

### 1. 后端Token验证机制

#### 1.1 拦截器配置

**文件**: `server/src/main/java/com/config/InterceptorConfig.java`

拦截器配置类继承`WebMvcConfigurationSupport`，主要功能：
- 创建`AuthorizationInterceptor` Bean（第14-17行）
- 注册拦截器匹配所有路径`/**`（第20-22行）
- 排除静态资源`/static/**`
- 配置静态资源从多个目录提供服务

#### 1.2 核心权限拦截器

**文件**: `server/src/main/java/com/interceptor/AuthorizationInterceptor.java`

实现`HandlerInterceptor`接口，核心验证逻辑在`preHandle`方法（第36-93行）：

**验证流程**:
```
请求到达
    ↓
1. 检查路径白名单 → 直接放行
   - /dictionary/page
   - /file/upload
   - /yonghu/register
    ↓
2. 设置CORS响应头
    ↓
3. 检查@IgnoreAuth注解 → 存在则放行
    ↓
4. 从请求头获取Token
   String token = request.getHeader("Token")
    ↓
5. 调用tokenService.getTokenEntity(token)验证
    ↓
6a. 验证成功 → 将用户信息存入session，放行请求
   - request.getSession().setAttribute("userId", tokenEntity.getUserid())
   - request.getSession().setAttribute("role", tokenEntity.getRole())
   - request.getSession().setAttribute("tableName", tokenEntity.getTablename())
   - request.getSession().setAttribute("username", tokenEntity.getUsername())
    ↓
6b. 验证失败 → 返回401错误 {"code": 401, "msg": "请先登录"}
```

**关键常量**:
- `LOGIN_TOKEN_KEY = "Token"` - 请求头字段名（第29行）

#### 1.3 Token服务

**接口**: `server/src/main/java/com/service/TokenService.java`

**实现**: `server/src/main/java/com/service/impl/TokenServiceImpl.java`

**核心方法**:

| 方法 | 功能 | 位置 |
|------|------|------|
| `generateToken(Integer userid, String username, String tableName, String role)` | 生成32位随机token，有效期1小时 | 第56-70行 |
| `getTokenEntity(String token)` | 根据token字符串查询数据库，验证是否过期 | 第73-79行 |

**Token生成逻辑** (`generateToken`方法):
1. 查询数据库是否已有该用户的token
2. 调用`CommonUtil.getRandomString(32)`生成32位随机字符串
3. 设置过期时间为当前时间+1小时
4. 更新或插入token记录到数据库
5. 返回生成的token字符串

**Token验证逻辑** (`getTokenEntity`方法):
1. 根据token字符串查询数据库
2. 如果token不存在，返回null
3. 如果token过期时间小于当前时间，返回null
4. 否则返回TokenEntity对象

#### 1.4 Token实体

**文件**: `server/src/main/java/com/entity/TokenEntity.java`

**数据库表**: `token`

**字段结构**:
- `id` - 主键
- `userid` - 用户ID
- `username` - 用户名
- `tablename` - 关联表名 (yonghu/shangjia/users)
- `role` - 用户角色
- `token` - token字符串
- `expiratedtime` - 过期时间
- `addtime` - 创建时间

#### 1.5 忽略认证注解

**文件**: `server/src/main/java/com/annotation/IgnoreAuth.java`

用于标记不需要token验证的方法：
- `@Target(ElementType.METHOD)` - 应用于方法
- `@Retention(RetentionPolicy.RUNTIME)` - 运行时可用
- 拦截器通过反射检测此注解决定是否放行

**使用示例**: 登录、注册、密码重置等公开接口

### 2. 前端Token发送（Vue管理后台）

#### 2.1 HTTP拦截器

**文件**: `client/src/utils/http.js`

**请求拦截器** (第12-14行):
```javascript
http.interceptors.request.use(config => {
    config.headers['Token'] = storage.get('Token')
    return config
})
```
- 从localStorage获取Token（键名为大写`Token`）
- 自动添加到所有请求的headers中

**响应拦截器** (第17-23行):
```javascript
http.interceptors.response.use(response => {
    if (response.data && response.data.code === 401) {
        router.push({ name: 'login' })
    }
    return response
})
```
- 检测401状态码
- 自动跳转到登录页

#### 2.2 Token存储

**文件**: `client/src/utils/storage.js`

封装localStorage操作，`get`方法会自动去除首尾引号。

#### 2.3 登录Token保存

登录成功后，将返回的token保存到localStorage：
```javascript
this.$storage.set('Token', res.token)
```

### 3. 移动端Token发送（uni-app）

#### 3.1 HTTP请求封装

**文件**: `uni-mall/api/http.js`

**请求方法** (第30-32行):
```javascript
let token = {'Token': uni.getStorageSync("token")}
options.header = Object.assign({}, options.header, token)
```
- 从uni.storage获取token（键名为小写`token`）
- 合并到请求头（字段名为大写`Token`）

#### 3.2 登录Token保存

**文件**: `uni-mall/pages/login/login.vue` (第161行)

```javascript
uni.setStorageSync("token", res.token)
```

#### 3.3 文件上传Token携带

**文件**: `uni-mall/api/index.js` (第272-274行)

```javascript
uni.uploadFile({
    header: {
        'Token': uni.getStorageSync("token")
    }
})
```

### 4. 各类用户登录Token生成

#### 4.1 管理员登录

**文件**: `server/src/main/java/com/controller/UsersController.java` (第45-80行)

- 接口: `POST /users/login`
- 注解: `@IgnoreAuth`
- 调用: `tokenService.generateToken(user.getId(), username, "users", user.getRole())`
- 返回: token, role, userId

#### 4.2 普通用户登录

**文件**: `server/src/main/java/com/controller/YonghuController.java` (第307-329行)

- 接口: `POST /yonghu/login`
- 注解: `@IgnoreAuth`
- 调用: `tokenService.generateToken(yonghu.getId(), username, "yonghu", "用户")`
- 返回: token, role, tableName, userId, username

#### 4.3 商家登录

**文件**: `server/src/main/java/com/controller/ShangjiaController.java` (第301-341行)

- 接口: `POST /shangjia/login`
- 注解: `@IgnoreAuth`
- 调用: `tokenService.generateToken(shangjia.getId(), username, "shangjia", "商家")`
- 返回: token, role, tableName, userId, username

### 5. Token传输格式总结

| 平台 | 请求头字段 | 本地存储键 | 存储方式 |
|------|-----------|----------|---------|
| Vue管理后台 | `Token` | `Token` | localStorage |
| uni-app移动端 | `Token` | `token` | uni.storage |

所有平台的请求头字段统一为大写`Token`。

### 6. 安全特性

1. **Token生成**: 32位随机字符串（小写字母+数字）
2. **Token存储**: 数据库持久化存储
3. **Token有效期**: 固定1小时，从生成/更新时间开始计算
4. **默认拒绝**: 所有接口默认需要token验证
5. **显式放行**: 必须使用`@IgnoreAuth`注解或路径白名单才能豁免
6. **Session绑定**: 验证成功后将用户信息存入session供后续业务使用
7. **密码安全**: 使用MD5哈希存储密码，支持明文密码自动升级

## Code References

### 后端核心文件
- `server/src/main/java/com/config/InterceptorConfig.java:12-39` - 拦截器配置
- `server/src/main/java/com/interceptor/AuthorizationInterceptor.java:26-94` - 核心验证逻辑
- `server/src/main/java/com/service/impl/TokenServiceImpl.java:56-79` - Token生成和验证
- `server/src/main/java/com/annotation/IgnoreAuth.java:1-13` - 忽略认证注解

### 登录接口
- `server/src/main/java/com/controller/UsersController.java:45-80` - 管理员登录
- `server/src/main/java/com/controller/YonghuController.java:307-329` - 用户登录
- `server/src/main/java/com/controller/ShangjiaController.java:301-341` - 商家登录

### 前端文件
- `client/src/utils/http.js:12-23` - Axios拦截器
- `client/src/utils/storage.js:1-18` - LocalStorage封装

### 移动端文件
- `uni-mall/api/http.js:30-32` - 请求Token添加
- `uni-mall/pages/login/login.vue:161` - Token保存
- `uni-mall/api/index.js:272-274` - 文件上传Token

## Architecture Documentation

### 认证架构流程图

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   前端/移动端  │  Token  │  后端拦截器    │  验证    │   数据库     │
│             ├────────>│              ├────────>│             │
│  localStorage│  Header │ Interceptor │  Query  │  token表    │
└─────────────┘         └──────────────┘         └─────────────┘
                              │
                              │ 验证成功
                              ↓
                       ┌──────────────┐
                       │    Session   │
                       │  userId      │
                       │  role        │
                       │  tableName   │
                       │  username    │
                       └──────────────┘
```

### 设计模式

1. **拦截器模式**: 使用HandlerInterceptor统一处理所有请求的认证
2. **注解驱动**: @IgnoreAuth注解灵活控制哪些接口需要认证
3. **Token服务分离**: TokenService封装生成和验证逻辑
4. **前后端分离**: 前端通过请求头传递token，后端统一验证

### 技术特点

- 项目依赖中有Apache Shiro，但实际未使用
- 使用自定义的数据库存储token方案，而非JWT
- Token采用随机字符串生成，无签名验证
- 支持多角色统一认证机制（管理员、用户、商家）

## Related Research

暂无相关研究文档

## Open Questions

无
