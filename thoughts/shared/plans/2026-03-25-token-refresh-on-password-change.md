# 修改密码后刷新Token功能实现计划

## 概述

实现用户修改密码后自动刷新token的功能，提升安全性和用户体验。当前系统在用户修改密码后，旧token仍然有效直到过期（1小时），这存在安全隐患。本计划将在密码修改成功后生成新token并返回给前端，前端自动更新本地存储。

## 当前状态分析

### 后端现状

**文件位置：**
- `server/src/main/java/com/controller/UsersController.java:108-123`
- `server/src/main/java/com/controller/YonghuController.java:404-419`
- `server/src/main/java/com/controller/ShangjiaController.java:382-397`

**问题：**
1. 三个controller的`updatePassword()`方法只更新数据库中的密码
2. 不调用`tokenService.generateToken()`生成新token
3. 返回值只包含成功状态，不包含新token

**示例代码（UsersController.java:108-123）：**
```java
@GetMapping(value = "/updatePassword")
public R updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
    UsersEntity users = usersService.selectById((Integer)request.getSession().getAttribute("userId"));
    // 验证密码...
    users.setPassword(DigestUtils.md5Hex(newPassword));
    usersService.updateById(users);
    return R.ok();  // ❌ 没有刷新token
}
```

### 前端现状

**Client (管理后台)：**
- **文件：** `client/src/views/update-password.vue:98-110`
- **问题：** 密码修改成功后不更新localStorage中的token
- **存储位置：** `client/src/utils/storage.js` 使用 `localStorage.setItem()`

**Uni-Mall (移动端)：**
- **文件：** `uni-mall/pages/changepassword/changepassword.vue:45-47`
- **问题：** 密码修改成功后不更新uni.storage中的token
- **额外问题：** 硬编码只支持`yonghu`表，不支持`users`和`shangjia`

### Token机制现状

**Token生成（TokenServiceImpl.java:56-70）：**
- 每次调用`generateToken()`会生成新的32位随机字符串
- 新token会覆盖数据库中旧的token记录（upsert操作）
- 这意味着**生成新token后，旧token自动失效**

**Token验证（AuthorizationInterceptor.java:67-78）：**
- 每次请求时验证token是否存在且未过期
- 如果验证失败返回401错误

**关键发现：** 由于新token会覆盖旧token，我们只需要在密码修改成功后调用`generateToken()`即可实现旧token的失效！

## 期望的最终状态

### 功能需求

1. **用户修改密码成功后，系统自动生成新token**
2. **前端接收新token并更新本地存储**
3. **旧token立即失效（新token覆盖旧token）**
4. **用户无需重新登录即可继续使用系统**

### 验收标准

**自动化验证：**
- [ ] 后端编译成功：`cd server && mvn clean compile`
- [ ] 前端编译成功：`cd client && npm run build`
- [ ] 移动端编译成功：`cd uni-mall && npm run build:h5`
- [ ] 单元测试通过（如果有）：`mvn test`

**手动验证：**
- [ ] 管理员修改密码后，能继续操作不需要重新登录
- [ ] 普通用户修改密码后，能继续操作不需要重新登录
- [ ] 商家修改密码后，能继续操作不需要重新登录
- [ ] 修改密码后，使用旧token的请求返回401错误
- [ ] 修改密码后，刷新页面不会跳转到登录页
- [ ] 移动端修改密码后，返回操作不需要重新登录

## 我们不做的内容

1. **不实现多设备token管理**：不会实现"让用户选择在哪些设备保持登录"的功能
2. **不实现强制所有设备重新登录**：不会删除用户的所有token（当前设计下每个用户只有一个token）
3. **不实现token续期机制**：不修改现有的1小时过期时间
4. **不修改logout逻辑**：保持当前的logout行为（只清除session，不删除数据库中的token）
5. **不修改token验证逻辑**：不改变AuthorizationInterceptor的验证流程

## 实现方案

### 技术方案选择

采用**方案2：生成新token并返回给前端**，理由如下：

**优点：**
- ✅ 用户体验最好：无需重新登录
- ✅ 实现简单：利用现有的generateToken()机制
- ✅ 自动失效旧token：新token覆盖数据库中的旧token
- ✅ 安全性提升：修改密码后立即让旧token失效

**权衡：**
- ⚠️ 其他设备仍然有旧token（但1小时后自动过期）
- ⚠️ 如果用户在多个设备同时修改密码，最后修改的生效

### 实现原理

```
用户修改密码流程：
1. 前端发送旧密码、新密码到后端
2. 后端验证旧密码正确性
3. 后端更新数据库中的密码
4. 后端调用 tokenService.generateToken() 生成新token
   → 新token自动覆盖数据库中的旧token
   → 旧token立即失效
5. 后端返回新token给前端
6. 前端接收新token并更新localStorage/uni.storage
7. 后续请求使用新token
```

## 实施阶段

### Phase 1: 后端Token刷新功能

**目标：** 修改三个controller的updatePassword方法，在密码修改成功后生成并返回新token。

#### 1.1 UsersController.updatePassword()

**文件：** `server/src/main/java/com/controller/UsersController.java`
**位置：** 行108-123

**当前代码：**
```java
@GetMapping(value = "/updatePassword")
public R updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
    UsersEntity users = usersService.selectById((Integer)request.getSession().getAttribute("userId"));
    if(newPassword == null){
        return R.error("新密码不能为空") ;
    }
    if(!DigestUtils.md5Hex(oldPassword).equals(users.getPassword())){
        return R.error("原密码输入错误");
    }
    if(DigestUtils.md5Hex(newPassword).equals(users.getPassword())){
        return R.error("新密码不能和原密码一致") ;
    }
    users.setPassword(DigestUtils.md5Hex(newPassword));
    usersService.updateById(users);
    return R.ok();
}
```

**修改后代码：**
```java
@GetMapping(value = "/updatePassword")
public R updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
    UsersEntity users = usersService.selectById((Integer)request.getSession().getAttribute("userId"));
    if(newPassword == null){
        return R.error("新密码不能为空") ;
    }
    if(!DigestUtils.md5Hex(oldPassword).equals(users.getPassword())){
        return R.error("原密码输入错误");
    }
    if(DigestUtils.md5Hex(newPassword).equals(users.getPassword())){
        return R.error("新密码不能和原密码一致") ;
    }

    // 1. 更新密码
    users.setPassword(DigestUtils.md5Hex(newPassword));
    usersService.updateById(users);

    // 2. 生成新token
    Integer userId = users.getId();
    String username = users.getUsername();
    String tableName = "users";
    String role = users.getRole();
    String newToken = tokenService.generateToken(userId, username, tableName, role);

    // 3. 返回新token
    R r = R.ok("密码修改成功");
    r.put("token", newToken);
    return r;
}
```

**修改说明：**
- 行120-122之后添加token生成逻辑
- 复用users对象中的用户信息
- 调用tokenService.generateToken()（已注入，见行40）
- 在返回值中添加新token

#### 1.2 YonghuController.updatePassword()

**文件：** `server/src/main/java/com/controller/YonghuController.java`
**位置：** 行404-419

**当前代码：**
```java
@GetMapping(value = "/updatePassword")
public R updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
    YonghuEntity yonghu = yonghuService.selectById((Integer)request.getSession().getAttribute("userId"));
    if(newPassword == null){
        return R.error("新密码不能为空") ;
    }
    if(!DigestUtils.md5Hex(oldPassword).equals(yonghu.getPassword())){
        return R.error("原密码输入错误");
    }
    if(DigestUtils.md5Hex(newPassword).equals(yonghu.getPassword())){
        return R.error("新密码不能和原密码一致") ;
    }
    yonghu.setPassword(DigestUtils.md5Hex(newPassword));
    yonghuService.updateById(yonghu);
    return R.ok();
}
```

**修改后代码：**
```java
@GetMapping(value = "/updatePassword")
public R updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
    YonghuEntity yonghu = yonghuService.selectById((Integer)request.getSession().getAttribute("userId"));
    if(newPassword == null){
        return R.error("新密码不能空") ;
    }
    if(!DigestUtils.md5Hex(oldPassword).equals(yonghu.getPassword())){
        return R.error("原密码输入错误");
    }
    if(DigestUtils.md5Hex(newPassword).equals(yonghu.getPassword())){
        return R.error("新密码不能和原密码一致") ;
    }

    // 1. 更新密码
    yonghu.setPassword(DigestUtils.md5Hex(newPassword));
    yonghuService.updateById(yonghu);

    // 2. 生成新token
    Integer userId = yonghu.getId();
    String username = yonghu.getYonghuzhanghao();  // 注意：用户名字段是yonghuzhanghao
    String tableName = "yonghu";
    String role = "用户";
    String newToken = tokenService.generateToken(userId, username, tableName, role);

    // 3. 返回新token
    R r = R.ok("密码修改成功");
    r.put("token", newToken);
    return r;
}
```

**修改说明：**
- 在行417之后添加token生成逻辑
- 注意用户名字段是`yonghuzhanghao`，不是`username`
- tokenService已在行54注入

#### 1.3 ShangjiaController.updatePassword()

**文件：** `server/src/main/java/com/controller/ShangjiaController.java`
**位置：** 行382-397

**当前代码：**
```java
@GetMapping(value = "/updatePassword")
public R updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
    ShangjiaEntity shangjia = shangjiaService.selectById((Integer)request.getSession().getAttribute("userId"));
    if(newPassword == null){
        return R.error("新密码不能为空") ;
    }
    if(!DigestUtils.md5Hex(oldPassword).equals(shangjia.getPassword())){
        return R.error("原密码输入错误");
    }
    if(DigestUtils.md5Hex(newPassword).equals(shangjia.getPassword())){
        return R.error("新密码不能和原密码一致") ;
    }
    shangjia.setPassword(DigestUtils.md5Hex(newPassword));
    shangjiaService.updateById(shangjia);
    return R.ok();
}
```

**修改后代码：**
```java
@GetMapping(value = "/updatePassword")
public R updatePassword(String oldPassword, String newPassword, HttpServletRequest request) {
    ShangjiaEntity shangjia = shangjiaService.selectById((Integer)request.getSession().getAttribute("userId"));
    if(newPassword == null){
        return R.error("新密码不能为空") ;
    }
    if(!DigestUtils.md5Hex(oldPassword).equals(shangjia.getPassword())){
        return R.error("原密码输入错误");
    }
    if(DigestUtils.md5Hex(newPassword).equals(shangjia.getPassword())){
        return R.error("新密码不能和原密码一致") ;
    }

    // 1. 更新密码
    shangjia.setPassword(DigestUtils.md5Hex(newPassword));
    shangjiaService.updateById(shangjia);

    // 2. 生成新token
    Integer userId = shangjia.getId();
    String username = shangjia.getShangjiazhanghao();  // 注意：用户名字段是shangjiazhanghao
    String tableName = "shangjia";
    String role = "商家";
    String newToken = tokenService.generateToken(userId, username, tableName, role);

    // 3. 返回新token
    R r = R.ok("密码修改成功");
    r.put("token", newToken);
    return r;
}
```

**修改说明：**
- 在行395之后添加token生成逻辑
- 注意用户名字段是`shangjiazhanghao`，不是`username`
- 需要注入tokenService（当前可能未注入）

**需要检查：** ShangjiaController是否已注入TokenService
```java
@Autowired
private TokenService tokenService;
```
如果未注入，需要在类开头添加此注入语句（参考YonghuController.java:54）

### 成功标准：

#### 自动化验证：
- [ ] 后端编译成功：`cd server && mvn clean compile`
- [ ] 没有编译错误或警告

#### 手动验证：
- [ ] 使用Postman/curl测试`/users/updatePassword?oldPassword=xxx&newPassword=yyy`
- [ ] 验证响应包含新token：`{"code":0,"token":"新token字符串"}`
- [ ] 使用新token能成功访问需要认证的接口
- [ ] 使用旧token访问接口返回401错误
- [ ] 对`/yonghu/updatePassword`和`/shangjia/updatePassword`进行相同测试

**实施注意：** 完成本阶段后，请手动验证旧token确实失效（使用旧token请求返回401），然后再进行下一阶段。

---

### Phase 2: Client (管理后台) Token更新

**目标：** 修改管理后台的密码修改页面，在收到成功响应后更新localStorage中的token。

#### 2.1 修改密码成功处理逻辑

**文件：** `client/src/views/update-password.vue`
**位置：** 行98-110

**当前代码：**
```javascript
this.$http({
    url: `${this.tableName}/update`,
    method: "post",
    data: this.user
}).then(({ data }) => {
    if (data && data.code === 0) {
        this.$message({
            message: "修改密码成功,下次登录系统生效",
            type: "success",
            duration: 1500
        });
    }
});
```

**修改后代码：**
```javascript
this.$http({
    url: `${this.tableName}/update`,
    method: "post",
    data: this.user
}).then(({ data }) => {
    if (data && data.code === 0) {
        // 1. 检查响应中是否包含新token
        if (data.token) {
            // 2. 更新localStorage中的token
            this.$storage.set("Token", data.token);
        }

        // 3. 显示成功消息
        this.$message({
            message: "修改密码成功,token已更新",
            type: "success",
            duration: 1500
        });
    }
});
```

**修改说明：**
- 在行99-106之间添加token更新逻辑
- 检查`data.token`是否存在（兼容旧版本后端）
- 使用`this.$storage.set("Token", data.token)`更新token
- 更新成功提示消息（可选）

#### 2.2 添加调试日志（可选）

如果需要调试，可以在更新token前后添加日志：

```javascript
if (data.token) {
    console.log("旧token:", this.$storage.get("Token"));
    this.$storage.set("Token", data.token);
    console.log("新token:", data.token);
    console.log("验证存储:", this.$storage.get("Token"));
}
```

**注意：** 生产环境应该移除console.log

### 成功标准：

#### 自动化验证：
- [ ] 前端编译成功：`cd client && npm run build`
- [ ] 没有ESLint错误：`npm run lint`

#### 手动验证：
- [ ] 打开浏览器开发者工具 → Application → Local Storage
- [ ] 记录当前Token值
- [ ] 登录管理后台，修改密码
- [ ] 验证Local Storage中的Token值已更新
- [ ] 修改密码后能继续操作，不需要重新登录
- [ ] 刷新页面后仍然保持登录状态
- [ ] 修改密码后打开新的浏览器标签，使用旧token操作返回401并跳转登录页

**实施注意：** 完成本阶段后，请在浏览器开发者工具中验证token确实已更新，然后再进行下一阶段。

---

### Phase 3: Uni-Mall (移动端) Token更新

**目标：** 修改移动端的密码修改页面，在收到成功响应后更新uni.storage中的token。

#### 3.1 修改密码成功处理逻辑

**文件：** `uni-mall/pages/changepassword/changepassword.vue`
**位置：** 行44-47

**当前代码：**
```javascript
async onUpdateTap() {
    // ...验证逻辑...

    this.user.password = this.$utils.md5(this.$mdp.confirmPassword);

    await this.$api.update('yonghu', this.user);

    this.$utils.msgBack('密码修改成功,下次登录时生效');
}
```

**修改后代码：**
```javascript
async onUpdateTap() {
    // ...验证逻辑...

    this.user.password = this.$utils.md5(this.$mdp.confirmPassword);

    // 1. 调用更新接口
    let res = await this.$api.update('yonghu', this.user);

    // 2. 检查响应中是否包含新token
    if (res && res.token) {
        // 3. 更新uni.storage中的token
        uni.setStorageSync("token", res.token);

        // 4. 显示成功消息（可选：添加token已更新提示）
        this.$utils.msgBack('密码修改成功,token已更新');
    } else {
        // 兼容旧版本后端
        this.$utils.msgBack('密码修改成功,下次登录时生效');
    }
}
```

**修改说明：**
- 保存API响应结果到变量`res`
- 检查`res.token`是否存在
- 如果存在，调用`uni.setStorageSync("token", res.token)`更新token
- 更新成功提示消息
- 添加else分支兼容不返回token的旧版本后端

#### 3.2 修复：支持所有用户类型的密码修改

**当前问题：** uni-mall硬编码只支持`yonghu`表

**文件：** `uni-mall/pages/changepassword/changepassword.vue`
**位置：** 整个文件

**建议修改：**
如果移动端需要支持管理员和商家修改密码，需要参考client的做法：

1. 从storage获取当前用户的sessionTable：
```javascript
data() {
    return {
        user: {},
        sessionTable: uni.getStorageSync("nowTable") || 'yonghu'
    }
}
```

2. 修改API调用：
```javascript
let res = await this.$api.update(this.sessionTable, this.user);
```

**注意：** 如果移动端确实只需要支持普通用户修改密码，可以跳过此修改。

### 成功标准：

#### 自动化验证：
- [ ] H5编译成功：`cd uni-mall && npm run build:h5`
- [ ] 微信小程序编译成功（使用HBuilderX或CLI）

#### 手动验证：
- [ ] 在微信开发者工具中打开项目
- [ ] 在调试器 → Storage中记录当前token值
- [ ] 登录移动端，修改密码
- [ ] 验证Storage中的token值已更新
- [ ] 修改密码后能继续操作，不需要重新登录
- [ ] 返回上一页后再次进入修改密码页，仍能正常操作
- [ ] 修改密码后关闭小程序重新打开，仍保持登录状态

**实施注意：** 完成本阶段后，请在微信开发者工具的Storage调试面板中验证token确实已更新。

---

## 测试策略

### 单元测试

当前项目没有针对controller的单元测试，建议添加：

**测试用例：**
1. 测试密码修改成功返回token
2. 测试旧密码错误返回错误
3. 测试新密码为空返回错误
4. 测试新密码与旧密码相同返回错误

**示例测试代码（可选）：**
```java
@Test
public void testUpdatePassword_ReturnsNewToken() {
    // Setup
    UsersEntity user = new UsersEntity();
    user.setId(1);
    user.setUsername("admin");
    user.setPassword(DigestUtils.md5Hex("oldPass"));

    // Execute
    R result = usersController.updatePassword("oldPass", "newPass", request);

    // Verify
    assertEquals(0, result.get("code"));
    assertNotNull(result.get("token"));
    assertNotEquals(oldToken, result.get("token"));
}
```

### 集成测试

**端到端测试流程：**

1. **准备阶段：**
   - 启动MySQL数据库
   - 启动后端服务：`cd server && mvn spring-boot:run`
   - 启动前端服务：`cd client && npm run serve`
   - 启动移动端（H5）：`cd uni-mall && npm run dev:h5`

2. **测试场景A：管理后台密码修改**
   - 使用管理员账号登录
   - 记录当前token（从localStorage获取）
   - 修改密码
   - 验证：localStorage中的token已更新
   - 验证：使用旧token访问API返回401
   - 验证：使用新token能正常访问
   - 验证：刷新页面不需要重新登录

3. **测试场景B：移动端密码修改**
   - 使用普通用户账号登录
   - 记录当前token（从uni.storage获取）
   - 修改密码
   - 验证：uni.storage中的token已更新
   - 验证：使用旧token访问API返回401
   - 验证：使用新token能正常访问
   - 验证：返回后再次进入不需要重新登录

4. **测试场景C：商家密码修改**
   - 使用商家账号登录
   - 执行与场景A相同的验证步骤

5. **边界条件测试：**
   - 测试旧密码错误的情况
   - 测试新密码为空的情况
   - 测试新密码与旧密码相同的情况
   - 测试未登录时访问修改密码接口（应返回401）

### 手动测试步骤

#### 测试步骤清单

**管理后台（Client）：**
1. ✅ 打开浏览器访问 `http://localhost:8081`
2. ✅ 使用管理员账号登录（admin / admin123）
3. ✅ 打开开发者工具 → Application → Local Storage
4. ✅ 复制当前Token值（例如：token_old）
5. ✅ 点击"修改密码"菜单项
6. ✅ 输入旧密码：admin123
7. ✅ 输入新密码：newpass123
8. ✅ 确认新密码：newpass123
9. ✅ 点击"确认"按钮
10. ✅ 验证：提示"修改密码成功,token已更新"
11. ✅ 验证：Local Storage中的Token值已改变
12. ✅ 点击其他菜单项，验证能正常访问
13. ✅ 刷新页面（F5），验证不需要重新登录
14. ✅ 在新标签页打开，验证不需要重新登录
15. ✅ 在开发者工具Console中执行：
    ```javascript
    // 设置旧token
    localStorage.setItem('Token', 'token_old');
    // 发送请求
    fetch('/zhinengxiaochengxsc/shangpin/page', {
        headers: { 'Token': 'token_old' }
    }).then(r => r.json()).then(console.log);
    ```
16. ✅ 验证：返回 `{ code: 401, msg: "请先登录" }`

**移动端（Uni-Mall H5）：**
1. ✅ 打开浏览器访问 `http://localhost:8080/zhinengxiaochengxsc/front/h5/`
2. ✅ 使用普通用户账号登录
3. ✅ 打开开发者工具 → Application → Local Storage
4. ✅ 复制当前token值
5. ✅ 点击"个人中心" → "修改密码"
6. ✅ 输入旧密码、新密码、确认密码
7. ✅ 点击"确认"按钮
8. ✅ 验证：提示"密码修改成功,token已更新"
9. ✅ 验证：Local Storage中的token值已改变
10. ✅ 返回上一页，验证能正常操作
11. ✅ 刷新页面，验证不需要重新登录

## 性能考虑

### 性能影响分析

**Token生成开销：**
- `generateToken()`操作包括：数据库查询 + 随机字符串生成 + 数据库更新
- 预计每次调用耗时：**10-50ms**（取决于数据库性能）
- 修改密码是低频操作，性能影响可忽略

**数据库写操作：**
- 每次密码修改增加一次`UPDATE token`操作
- Token表已有索引（userid, role），更新操作很快
- 预计额外数据库负载：**每秒<0.01次**（假设每天100次密码修改）

**前端性能：**
- localStorage.setItem()是同步操作，耗时<1ms
- uni.setStorageSync()也是同步操作，耗时<1ms
- 对用户体验无影响

### 优化建议

**当前不需要优化，原因：**
1. 修改密码是低频操作（每天每人<1次）
2. 额外开销极小（<50ms）
3. 安全性提升带来的价值远大于性能开销

**如果未来需要优化（可选）：**
1. 考虑使用Redis缓存token，减少数据库查询
2. 实现批量token失效机制（如果需要"一键注销所有设备"）

## 迁移注意事项

### 向后兼容性

**前端兼容性：**
- 新代码检查`response.token`是否存在，兼容不返回token的旧版本后端
- 旧版本前端忽略返回的token，不影响正常使用
- **可以灰度发布：先发布后端，再发布前端**

**后端兼容性：**
- 新后端始终返回token，不影响旧前端（旧前端忽略token字段）
- **建议发布顺序：后端 → 前端**

### 数据库迁移

**不需要数据库迁移：**
- Token表结构不变
- 只是利用现有的generateToken()机制
- 新token会覆盖旧token（upsert操作）

### 回滚方案

**如果需要回滚：**

**方案1：代码回滚**
```bash
# 后端回滚
git revert <commit-hash>
mvn clean package
java -jar target/zhinengxiaochengxsc-0.0.1-SNAPSHOT.jar

# 前端回滚
git revert <commit-hash>
npm run build
```

**方案2：配置开关（可选，如果需要）**
在后端application.yml添加配置：
```yaml
token:
  refresh-on-password-change: true
```

在updatePassword方法中检查配置：
```java
if (tokenRefreshEnabled) {
    String newToken = tokenService.generateToken(...);
    r.put("token", newToken);
}
```

**注意：** 当前实现不需要配置开关，因为改进是向后兼容的。

## 安全考虑

### 安全提升

**修改密码后旧token立即失效：**
- ✅ 防止密码泄露后攻击者继续使用旧token
- ✅ 减少密码泄露的窗口期（从1小时降至0）
- ✅ 符合安全最佳实践

**潜在安全考虑：**

**1. 中间人攻击：**
- 攻击者可能拦截响应并窃取新token
- **缓解措施：** 已有HTTPS加密传输（生产环境）
- **建议：** 确保生产环境使用HTTPS

**2. XSS攻击：**
- 如果前端存在XSS漏洞，攻击者可能窃取新token
- **缓解措施：** 前端需要防范XSS攻击（输入验证、输出转义）
- **当前状态：** Vue.js默认转义输出，风险较低

**3. 并发修改密码：**
- 如果用户在多个设备同时修改密码，最后修改的生效
- **影响：** 先修改的设备的token立即失效
- **用户期望：** 合理行为，最后一次修改生效

**4. 密码修改请求未验证：**
- 当前实现没有防止CSRF攻击的措施
- **建议：** 确保其他安全措施已到位（如CSRF token）

### 不影响的安全机制

**Token过期机制：**
- 仍然保持1小时过期时间
- 新token的过期时间重新计算

**Token验证机制：**
- AuthorizationInterceptor的验证逻辑不变
- 白名单机制不变

**@IgnoreAuth机制：**
- 不影响不需要认证的接口

## 参考资料

### 相关文档

- Token认证机制研究：`thoughts/shared/research/2026-03-25-token-authentication-mechanism.md`
- 项目CLAUDE.md：`CLAUDE.md`

### 相关代码文件

**后端：**
- `server/src/main/java/com/service/impl/TokenServiceImpl.java` - Token生成和验证
- `server/src/main/java/com/entity/TokenEntity.java` - Token实体
- `server/src/main/java/com/interceptor/AuthorizationInterceptor.java` - Token验证拦截器
- `server/src/main/java/com/controller/UsersController.java` - 管理员Controller
- `server/src/main/java/com/controller/YonghuController.java` - 用户Controller
- `server/src/main/java/com/controller/ShangjiaController.java` - 商家Controller

**前端（Client）：**
- `client/src/views/login.vue:150` - 登录时token存储
- `client/src/views/update-password.vue:98-110` - 密码修改成功处理
- `client/src/utils/storage.js` - 存储工具
- `client/src/utils/http.js:14-28` - HTTP拦截器

**前端（Uni-Mall）：**
- `uni-mall/pages/login/login.vue:172` - 登录时token存储
- `uni-mall/pages/changepassword/changepassword.vue:44-47` - 密码修改成功处理
- `uni-mall/api/http.js:34-35` - Token头设置
- `uni-mall/api/http.js:52-68` - 响应处理

### 类似实现

**登录时的token处理模式（可参考）：**
- `UsersController.java:74-79` - 管理员登录返回token
- `YonghuController.java:321` - 用户登录返回token
- `ShangjiaController.java:333` - 商家登录返回token

这些方法展示了如何生成和返回token，密码修改可以遵循相同模式。

## 总结

本计划实现了修改密码后自动刷新token的功能，通过以下三个阶段：

1. **Phase 1（后端）：** 修改三个controller的updatePassword方法，在密码修改成功后生成并返回新token
2. **Phase 2（Client前端）：** 修改管理后台密码修改页面，更新localStorage中的token
3. **Phase 3（Uni-Mall前端）：** 修改移动端密码修改页面，更新uni.storage中的token

**关键优势：**
- ✅ 利用现有的generateToken()机制，新token自动覆盖旧token
- ✅ 向后兼容，支持灰度发布
- ✅ 用户体验好，无需重新登录
- ✅ 安全性提升，旧token立即失效
- ✅ 实现简单，代码改动量小

**预期效果：**
- 用户修改密码后能继续使用系统，不需要重新登录
- 修改密码后旧token立即失效，减少安全风险
- 对现有系统无破坏性影响
