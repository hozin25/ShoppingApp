# Token认证机制

**文档版本：** v1.0
**创建日期：** 2026-03-25
**项目：** 智能小程序商城系统

---

## 📋 目录

- [1. 概述](#1-概述)
- [2. Token生成机制](#2-token生成机制)
- [3. 客户端Token存储](#3-客户端token存储)
- [4. 移动端Token存储](#4-移动端token存储)
- [5. Token验证流程](#5-token验证流程)
- [6. 安全机制](#6-安全机制)
- [7. 数据存储结构](#7-数据存储结构)

---

## 1. 概述

本系统采用基于**自定义Token**的身份认证机制，实现了管理后台和移动端的统一认证体系。

### 技术栈

| 层级 | 技术 |
|------|------|
| **后端** | Spring Boot + MyBatis-Plus |
| **管理前端** | Vue.js 2 + Axios |
| **移动端** | uni-app |
| **存储** | MySQL + 本地存储 |

---

## 2. Token生成机制

### 2.1 Token实体结构

**文件位置：** `server/src/main/java/com/entity/TokenEntity.java`

```java
@TableName("token")
public class TokenEntity {
    private Integer id;              // 主键ID
    private Integer userid;          // 用户ID
    private String username;         // 用户名
    private String tablename;        // 表名（区分角色）
    private String role;             // 角色
    private String token;            // Token值
    private Date expiratedtime;      // 过期时间
    private Date addtime;            // 创建时间
}
```

### 2.2 Token生成服务

**文件位置：** `server/src/main/java/com/service/impl/TokenServiceImpl.java`

```java
@Override
public String generateToken(Integer userid, String username,
                            String tableName, String role) {
    // 1. 查询是否已有Token
    TokenEntity tokenEntity = this.selectOne(
        new EntityWrapper<TokenEntity>()
            .eq("userid", userid)
            .eq("role", role)
    );

    // 2. 生成32位随机Token
    String token = CommonUtil.getRandomString(32);

    // 3. 设置过期时间为1小时后
    Calendar cal = Calendar.getInstance();
    cal.setTime(new Date());
    cal.add(Calendar.HOUR_OF_DAY, 1);

    // 4. 更新或插入Token记录
    if(tokenEntity != null) {
        tokenEntity.setToken(token);
        tokenEntity.setExpiratedtime(cal.getTime());
        this.updateById(tokenEntity);
    } else {
        this.insert(new TokenEntity(userid, username,
                                   tableName, role, token, cal.getTime()));
    }

    return token;
}
```

### 2.3 Token特性

| 特性 | 说明 |
|------|------|
| **长度** | 32位随机字符串 |
| **有效期** | 1小时（自动续期） |
| **存储** | MySQL数据库 `token` 表 |
| **唯一性** | 每个用户+角色组合对应一个Token |

---

## 3. 客户端Token存储

### 3.1 存储方式

**文件位置：** `client/src/utils/storage.js`

```javascript
const storage = {
    set(key, value) {
        localStorage.setItem(key, JSON.stringify(value));
    },
    get(key) {
        return localStorage.getItem(key)
            ?localStorage.getItem(key).replace('"','').replace('"','')
            :"";
    },
    remove(key) {
        localStorage.removeItem(key);
    },
    clear() {
        localStorage.clear();
    }
}
```

**存储位置：** 浏览器 `localStorage`

### 3.2 登录时Token存储

**文件位置：** `client/src/views/login.vue:150`

```javascript
this.$http({
    url: `${this.tableName}/login?username=${username}&password=${password}`,
    method: "post"
}).then(({ data }) => {
    if (data && data.code === 0) {
        // 存储Token和用户信息
        this.$storage.set("Token", data.token);
        this.$storage.set("userId", data.userId);
        this.$storage.set("role", this.rulesForm.role);
        this.$storage.set("sessionTable", this.tableName);
        this.$storage.set("adminName", this.rulesForm.username);

        // 跳转到首页
        this.$router.replace({ path: "/index/" });
    }
});
```

### 3.3 HTTP请求拦截器

**文件位置：** `client/src/utils/http.js:14-16`

```javascript
// 请求拦截
http.interceptors.request.use(config => {
    // 从localStorage读取Token并添加到请求头
    config.headers['Token'] = storage.get('Token');
    return config;
}, error => {
    return Promise.reject(error);
})
```

### 3.4 Token失效处理

**文件位置：** `client/src/utils/http.js:21-24`

```javascript
// 响应拦截
http.interceptors.response.use(response => {
    // 401状态码表示Token失效
    if (response.data && response.data.code === 401) {
        router.push({ name: 'login' });
    }
    return response;
}, error => {
    return Promise.reject(error);
})
```

---

## 4. 移动端Token存储

### 4.1 登录时Token存储

**文件位置：** `uni-mall/pages/login/login.vue:172-180`

```javascript
let res = await this.$api.login(`${this.optionsValues[this.index]}`, {
    username: this.username,
    password: this.password
});

// 存储Token和用户信息
uni.setStorageSync("token", res.token);
uni.setStorageSync("nickname", this.username);
uni.setStorageSync("nowTable", `${this.optionsValues[this.index]}`);

// 获取完整用户信息
res = await this.$api.session(`${this.optionsValues[this.index]}`);
uni.setStorageSync("userid", res.data.id);
if(res.data.vip) {
    uni.setStorageSync("vip", res.data.vip);
}
uni.setStorageSync("role", `${this.options[this.index]}`);

// 跳转到首页
this.$utils.tab("../index/index");
```

### 4.2 HTTP请求拦截器

**文件位置：** `uni-mall/api/http.js:34-35`

```javascript
// 从本地存储读取Token
let token = {'Token': uni.getStorageSync("token")};
options.header = Object.assign({}, options.header, token);
```

### 4.3 Token验证

**文件位置：** `uni-mall/api/index.js:112-115`

```javascript
export const auth = () => {
    let token = uni.getStorageSync("token");
    if (!uni.getStorageSync("token")) {
        uni.navigateTo({
            url: '../login/login'
        });
    }
};
```

### 4.4 Token清理

**文件位置：** `uni-mall/pages/user-info/userinfo.vue:134`

```javascript
// 退出登录时清除Token
uni.setStorageSync('token', '');
```

---

## 5. Token验证流程

### 5.1 后端拦截器

**文件位置：** `server/src/main/java/com/interceptor/AuthorizationInterceptor.java`

```java
@Component
public class AuthorizationInterceptor implements HandlerInterceptor {

    public static final String LOGIN_TOKEN_KEY = "Token";

    @Autowired
    private TokenService tokenService;

    @Override
    public boolean preHandle(HttpServletRequest request,
                           HttpServletResponse response,
                           Object handler) throws Exception {

        String servletPath = request.getServletPath();

        // 白名单路径直接放行
        if("/dictionary/page".equals(servletPath) ||
           "/file/upload".equals(servletPath) ||
           "/yonghu/register".equals(servletPath)) {
            return true;
        }

        // 配置跨域
        response.setHeader("Access-Control-Allow-Methods",
                          "POST, GET, OPTIONS, DELETE");
        response.setHeader("Access-Control-Allow-Origin",
                          request.getHeader("Origin"));
        response.setHeader("Access-Control-Allow-Credentials", "true");

        // 检查是否有 @IgnoreAuth 注解
        IgnoreAuth annotation;
        if (handler instanceof HandlerMethod) {
            annotation = ((HandlerMethod) handler)
                .getMethodAnnotation(IgnoreAuth.class);
        } else {
            return true;
        }

        // 不需要验证权限的方法直接放过
        if(annotation != null) {
            return true;
        }

        // 从请求头获取Token
        String token = request.getHeader(LOGIN_TOKEN_KEY);

        TokenEntity tokenEntity = null;
        if(StringUtils.isNotBlank(token)) {
            tokenEntity = tokenService.getTokenEntity(token);
        }

        // Token验证成功
        if(tokenEntity != null) {
            request.getSession().setAttribute("userId",
                                             tokenEntity.getUserid());
            request.getSession().setAttribute("role",
                                             tokenEntity.getRole());
            request.getSession().setAttribute("tableName",
                                             tokenEntity.getTablename());
            request.getSession().setAttribute("username",
                                             tokenEntity.getUsername());
            return true;
        }

        // Token验证失败
        PrintWriter writer = null;
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=utf-8");
        try {
            writer = response.getWriter();
            writer.print(JSONObject.toJSONString(
                R.error(401, "请先登录")));
        } finally {
            if(writer != null) {
                writer.close();
            }
        }
        return false;
    }
}
```

### 5.2 Token验证服务

**文件位置：** `server/src/main/java/com/service/impl/TokenServiceImpl.java:72-79`

```java
@Override
public TokenEntity getTokenEntity(String token) {
    TokenEntity tokenEntity = this.selectOne(
        new EntityWrapper<TokenEntity>().eq("token", token)
    );

    // Token不存在或已过期
    if(tokenEntity == null ||
       tokenEntity.getExpiratedtime().getTime() < new Date().getTime()) {
        return null;
    }

    return tokenEntity;
}
```

### 5.3 验证流程图

```
┌─────────────┐
│  客户端请求  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│   后端拦截器接收请求          │
│   AuthorizationInterceptor   │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│   检查是否在白名单            │
│   (/dictionary/page,        │
│    /file/upload,            │
│    /yonghu/register)        │
└──────┬──────────────────────┘
       │
       ├─ 是 ─→ 放行
       │
       └─ 否 ─→ ▼
              ┌─────────────────────────────────┐
              │   检查是否有 @IgnoreAuth 注解     │
              └──────┬──────────────────────────┘
                     │
                     ├─ 有 ─→ 放行
                     │
                     └─ 无 ─→ ▼
                            ┌────────────────────┐
                            │ 从请求头获取Token   │
                            │ header: "Token"    │
                            └──────┬─────────────┘
                                   │
                                   ▼
                            ┌────────────────────┐
                            │ 验证Token有效性     │
                            │ 1. Token是否存在   │
                            │ 2. 是否过期        │
                            └──────┬─────────────┘
                                   │
                                   ├─ 有效 ─→ ▼
                                   │         ┌────────────────────┐
                                   │         │ 设置Session属性    │
                                   │         │ userId, role,      │
                                   │         │ tableName,        │
                                   │         │ username          │
                                   │         └──────┬────────────┘
                                   │                │
                                   │                ▼
                                   │         ┌────────────────────┐
                                   │         │ 放行请求           │
                                   │         └───────────────────┘
                                   │
                                   └─ 无效 ─→ ▼
                                            ┌────────────────────┐
                                            │ 返回401错误        │
                                            │ "请先登录"         │
                                            └────────────────────┘
```

---

## 6. 安全机制

### 6.1 Token过期机制

| 配置项 | 值 | 说明 |
|--------|---|------|
| **有效期** | 1小时 | Token生成后1小时过期 |
| **续期机制** | 登录时刷新 | 每次登录重新生成Token |
| **过期检查** | 每次请求 | 拦截器每次请求都验证有效期 |

### 6.2 白名单路径

| 路径 | 说明 |
|------|------|
| `/dictionary/page` | 字典表分页查询 |
| `/file/upload` | 文件上传 |
| `/yonghu/register` | 用户注册 |

### 6.3 请求头配置

```javascript
// 请求头字段名
Token: <32位随机字符串>

// 跨域支持
Access-Control-Allow-Headers: Token, Origin, Content-Type, ...
Access-Control-Allow-Credentials: true
```

---

## 7. 数据存储结构

### 7.1 数据库表结构

```sql
CREATE TABLE `token` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` int(11) DEFAULT NULL COMMENT '用户id',
  `username` varchar(100) DEFAULT NULL COMMENT '用户名',
  `tablename` varchar(100) DEFAULT NULL COMMENT '表名',
  `role` varchar(100) DEFAULT NULL COMMENT '角色',
  `token` varchar(200) DEFAULT NULL COMMENT 'token',
  `expiratedtime` datetime DEFAULT NULL COMMENT '过期时间',
  `addtime` datetime DEFAULT NULL COMMENT '新增时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 7.2 存储对比

| 存储位置 | 存储方式 | 数据类型 | 容量限制 | 持久化 |
|----------|----------|----------|----------|--------|
| **客户端** | localStorage | 字符串 | 5-10MB | 是 |
| **移动端** | uni.storage | 字符串 | 10MB | 是 |
| **服务端** | MySQL | TokenEntity | 无限制 | 是 |

---

## 8. 完整认证流程

### 8.1 登录流程

```
┌──────────────┐
│  用户输入账号密码 │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────┐
│ 前端发送登录请求             │
│ POST /{table}/login         │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│ 后端验证用户名密码           │
│ 查询数据库验证               │
└──────┬──────────────────────┘
       │
       ├─ 验证失败 ─→ 返回错误
       │
       └─ 验证成功 ─→ ▼
                       ┌─────────────────────┐
                       │ 调用generateToken()  │
                       │ 生成32位随机Token    │
                       │ 设置1小时过期时间    │
                       └──────┬──────────────┘
                              │
                              ▼
                       ┌─────────────────────┐
                       │ 存储到数据库         │
                       │ INSERT/UPDATE token │
                       └──────┬──────────────┘
                              │
                              ▼
                       ┌─────────────────────┐
                       │ 返回Token给前端      │
                       │ {code:0, token:xxx} │
                       └──────┬──────────────┘
                              │
                              ▼
                       ┌─────────────────────┐
                       │ 前端存储Token        │
                       │ localStorage/setStorage│
                       └─────────────────────┘
```

### 8.2 认证流程

```
┌──────────────┐
│  客户端发起请求  │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────┐
│ 请求拦截器自动添加Token       │
│ header.Token = storage.get() │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│ 后端拦截器验证Token          │
│ AuthorizationInterceptor    │
└──────┬──────────────────────┘
       │
       ├─ Token有效 ─→ ▼
       │                ┌─────────────────────┐
       │                │ 设置Session上下文    │
       │                │ 执行业务逻辑         │
       │                │ 返回业务数据         │
       │                └─────────────────────┘
       │
       └─ Token无效 ─→ ▼
                        ┌─────────────────────┐
                        │ 返回401错误          │
                        │ 前端跳转登录页       │
                        └─────────────────────┘
```

---

## 9. 关键代码位置速查

| 功能 | 文件路径 | 行号 |
|------|----------|------|
| **Token生成** | `server/src/main/java/com/service/impl/TokenServiceImpl.java` | 56-70 |
| **Token验证** | `server/src/main/java/com/service/impl/TokenServiceImpl.java` | 72-79 |
| **拦截器** | `server/src/main/java/com/interceptor/AuthorizationInterceptor.java` | 36-93 |
| **Token实体** | `server/src/main/java/com/entity/TokenEntity.java` | 全文 |
| **客户端存储** | `client/src/utils/storage.js` | 全文 |
| **客户端拦截器** | `client/src/utils/http.js` | 14-28 |
| **客户端登录** | `client/src/views/login.vue` | 150-155 |
| **移动端登录** | `uni-mall/pages/login/login.vue` | 172-181 |
| **移动端拦截器** | `uni-mall/api/http.js` | 34-35 |
| **移动端认证** | `uni-mall/api/index.js` | 112-115 |

---

## 10. 常见问题

### Q1: Token过期后如何处理？

**A:** 后端返回401状态码，前端自动跳转到登录页面。

```javascript
// client/src/utils/http.js
if (response.data && response.data.code === 401) {
    router.push({ name: 'login' });
}
```

### Q2: 如何实现Token续期？

**A:** 每次登录时调用`generateToken()`，会重新生成Token并更新过期时间。

### Q3: 如何注销登录？

**A:** 清除本地存储的Token。

```javascript
// 客户端
storage.remove('Token');

// 移动端
uni.setStorageSync('token', '');
```

### Q4: 哪些接口不需要Token验证？

**A:** 使用`@IgnoreAuth`注解或在白名单中的接口。

```java
@IgnoreAuth
@PostMapping("/register")
public R register(@RequestBody YonghuEntity user) {
    // 不需要Token即可访问
}
```

---

**文档结束**
