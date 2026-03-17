# 密码加密一致性修复计划

## Overview

修复小程序登录功能中用户密码加密不一致的问题。当前用户表(yonghu)通过管理后台保存时密码为明文存储，但登录时使用MD5加密验证，导致验证失败。

## Current State Analysis

### 问题现象
- 用户在小程序输入账号 `a1`，密码 `123456`，无法登录
- 弹窗提示"账号或密码不正确"

### 根本原因
系统存在密码处理不一致的问题：

| 用户类型 | 登录验证方式 | 保存时密码 | 注册时密码 |
|---------|------------|----------|----------|
| 用户(yonghu) | **MD5加密验证** | **明文"123456"** | MD5加密 |
| 商家(shangjia) | 明文验证 | 明文"123456" | 明文 |
| 管理员(users) | 明文验证 | 明文 | 明文 |

### 代码问题位置

#### YonghuController.java
- **第150行** (save方法): 密码直接存储明文
  ```java
  yonghu.setPassword("123456");  // 明文！
  ```

- **第311行** (login方法): 使用MD5加密验证
  ```java
  if(yonghu==null || !yonghu.getPassword().equals(DigestUtils.md5Hex(password)))
      return R.error("账号或密码不正确");
  ```

- **第342行** (register方法): 注册时正确使用MD5加密
  ```java
  yonghu.setPassword(DigestUtils.md5Hex(yonghu.getPassword()));
  ```

#### ShangjiaController.java
- 第304行: 登录验证使用明文比较
- 第151行: 保存时密码为明文"123456"

#### UsersController.java
- 第48行: 登录验证使用明文比较
- 整个系统未使用MD5加密

### 数据库当前状态
- `yonghu` 表中用户 `a1` 的密码为明文 `123456`
- MD5("123456") = `e10adc3949ba59abbe56e057f20f883e`
- 验证时比较 `e10adc3949ba59abbe56e057f20f883e` != `123456` → 失败

## Desired End State

修复后，所有用户类型的密码处理应当统一：
1. 所有密码在存储前使用MD5加密
2. 所有登录验证使用MD5加密比较
3. 修改密码功能使用MD5加密
4. 重置密码功能使用MD5加密

### 验证方式
- 用户 a1 可以使用密码 123456 正常登录
- 新添加的用户可以正常登录
- 密码修改功能正常工作
- 密码重置功能正常工作

## What We're NOT Doing

- 不修改现有的密码加密算法（继续使用MD5）
- 不修改数据库表结构
- 不修改前端代码
- 不升级到更安全的加密算法（如BCrypt）

## Implementation Approach

采用两阶段修复策略：
1. **Phase 1**: 修复后端代码中的密码加密不一致
2. **Phase 2**: 修复现有数据库中的明文密码

## Phase 1: 修复后端代码

### 1.1 修复 YonghuController.java

#### 修改 save 方法 (第150行)
**File**: `server/src/main/java/com/controller/YonghuController.java`

**修改前**:
```java
yonghu.setPassword("123456");
```

**修改后**:
```java
yonghu.setPassword(DigestUtils.md5Hex("123456"));
```

#### 修改 add 方法 (第507行)
**File**: `server/src/main/java/com/controller/YonghuController.java`

**修改前**:
```java
yonghu.setPassword("123456");
```

**修改后**:
```java
yonghu.setPassword(DigestUtils.md5Hex("123456"));
```

### 1.2 修复 ShangjiaController.java

#### 修改 save 方法 (第151行)
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**修改前**:
```java
shangjia.setPassword("123456");
```

**修改后**:
```java
shangjia.setPassword(DigestUtils.md5Hex("123456"));
```

#### 修改 login 方法 (第304行)
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**修改前**:
```java
if(shangjia==null || !shangjia.getPassword().equals(password))
```

**修改后**:
```java
if(shangjia==null || !shangjia.getPassword().equals(DigestUtils.md5Hex(password)))
```

#### 修改 add 方法 (第486行)
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**修改前**:
```java
shangjia.setPassword("123456");
```

**修改后**:
```java
shangjia.setPassword(DigestUtils.md5Hex("123456"));
```

#### 修改 updatePassword 方法 (第363行)
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**修改前**:
```java
if(!oldPassword.equals(shangjia.getPassword())){
    return R.error("原密码输入错误");
}
```

**修改后**:
```java
if(!shangjia.getPassword().equals(DigestUtils.md5Hex(oldPassword))){
    return R.error("原密码输入错误");
}
```

#### 修改 updatePassword 方法 (第369行)
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**修改前**:
```java
shangjia.setPassword(newPassword);
```

**修改后**:
```java
shangjia.setPassword(DigestUtils.md5Hex(newPassword));
```

#### 修改 resetPassword 方法 (第349行)
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**修改前**:
```java
shangjia.setPassword("123456");
```

**修改后**:
```java
shangjia.setPassword(DigestUtils.md5Hex("123456"));
```

#### 修改 resetPass 方法 (第384行)
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**修改前**:
```java
shangjia.setPassword("123456");
```

**修改后**:
```java
shangjia.setPassword(DigestUtils.md5Hex("123456"));
```

### 1.3 修复 UsersController.java

#### 修改 login 方法 (第48行)
**File**: `server/src/main/java/com/controller/UsersController.java`

需要先添加 import:
```java
import org.apache.commons.codec.digest.DigestUtils;
```

**修改前**:
```java
if(user==null || !user.getPassword().equals(password)) {
    return R.error("账号或密码不正确");
}
```

**修改后**:
```java
if(user==null || !user.getPassword().equals(DigestUtils.md5Hex(password))) {
    return R.error("账号或密码不正确");
}
```

#### 修改 updatePassword 方法 (第91行)
**File**: `server/src/main/java/com/controller/UsersController.java`

**修改前**:
```java
if(!oldPassword.equals(users.getPassword())){
    return R.error("原密码输入错误");
}
```

**修改后**:
```java
if(!users.getPassword().equals(DigestUtils.md5Hex(oldPassword))){
    return R.error("原密码输入错误");
}
```

#### 修改 updatePassword 方法 (第97行)
**File**: `server/src/main/java/com/controller/UsersController.java`

**修改前**:
```java
users.setPassword(newPassword);
```

**修改后**:
```java
users.setPassword(DigestUtils.md5Hex(newPassword));
```

#### 修改 resetPass 方法 (第112行)
**File**: `server/src/main/java/com/controller/UsersController.java`

**修改前**:
```java
user.setPassword("123456");
```

**修改后**:
```java
user.setPassword(DigestUtils.md5Hex("123456"));
```

### Success Criteria - Phase 1:

#### Automated Verification:
- [ ] 代码编译成功: `cd server && mvn clean compile`
- [ ] 无编译错误

#### Manual Verification:
- [ ] 重启后端服务成功
- [ ] 检查编译后的class文件无异常

---

## Phase 2: 修复现有数据库密码

### 2.1 使用已有升级接口

后端已经提供了一个密码升级接口 `YonghuController.upgradePasswords()` (第517-536行)。

**操作步骤**:
1. 确保后端服务正在运行
2. 访问URL: `http://localhost:8080/zhinengxiaochengxsc/yonghu/upgradePasswords`
3. 验证返回成功消息

### 2.2 为其他表添加升级接口

由于 `upgradePasswords` 接口只针对 `yonghu` 表，需要为 `shangjia` 和 `users` 表添加类似接口。

#### 添加到 ShangjiaController.java
**File**: `server/src/main/java/com/controller/ShangjiaController.java`

**在第495行之前添加**:
```java
// 添加一个新的方法用于升级已有密码
@GetMapping(value = "/upgradePasswords")
@IgnoreAuth  // 仅在需要时使用，使用后请删除此接口
public R upgradePasswords() {
    try {
        List<ShangjiaEntity> users = shangjiaService.selectList(new EntityWrapper<ShangjiaEntity>().eq("shangjia_delete", 1));
        int count = 0;
        for (ShangjiaEntity user : users) {
            // 假设密码长度大于32的已经是MD5加密过的
            if (user.getPassword() != null && user.getPassword().length() != 32) {
                user.setPassword(DigestUtils.md5Hex(user.getPassword()));
                shangjiaService.updateById(user);
                count++;
            }
        }
        return R.ok("成功更新 " + count + " 个商家的密码");
    } catch (Exception e) {
        e.printStackTrace();
        return R.error("密码升级失败：" + e.getMessage());
    }
}
```

#### 添加到 UsersController.java
**File**: `server/src/main/java/com/controller/UsersController.java`

**在第192行之前添加**:
```java
// 添加一个新的方法用于升级已有密码
@GetMapping(value = "/upgradePasswords")
@IgnoreAuth  // 仅在需要时使用，使用后请删除此接口
public R upgradePasswords() {
    try {
        List<UsersEntity> users = usersService.selectList(null);
        int count = 0;
        for (UsersEntity user : users) {
            // 假设密码长度大于32的已经是MD5加密过的
            if (user.getPassword() != null && user.getPassword().length() != 32) {
                user.setPassword(DigestUtils.md5Hex(user.getPassword()));
                usersService.updateById(user);
                count++;
            }
        }
        return R.ok("成功更新 " + count + " 个管理员的密码");
    } catch (Exception e) {
        e.printStackTrace();
        return R.error("密码升级失败：" + e.getMessage());
    }
}
```

### 2.3 执行密码升级

**操作步骤**:
1. 重新编译并部署后端代码
2. 访问以下URL执行密码升级：
   - `http://localhost:8080/zhinengxiaochengxsc/yonghu/upgradePasswords`
   - `http://localhost:8080/zhinengxiaochengxsc/shangjia/upgradePasswords`
   - `http://localhost:8080/zhinengxiaochengxsc/users/upgradePasswords`

### Success Criteria - Phase 2:

#### Automated Verification:
- [ ] 所有升级接口返回成功

#### Manual Verification:
- [ ] 用户 a1 使用密码 123456 可以成功登录
- [ ] 商家 a1 使用密码 123456 可以成功登录
- [ ] 管理员可以正常登录
- [ ] 修改密码功能正常
- [ ] 重置密码功能正常

**Implementation Note**: 完成Phase 2后，请删除所有升级接口或添加权限保护，以防安全风险。

---

## Testing Strategy

### 单元测试建议:
- 测试MD5加密后的密码长度是否为32位
- 测试密码比较逻辑是否正确

### 手动测试步骤:
1. **用户登录测试**
   - 账号: a1, 密码: 123456 → 应成功登录
   - 账号: a1, 密码: wrong → 应提示密码错误

2. **商家登录测试**
   - 账号: a1, 密码: 123456 → 应成功登录

3. **管理员登录测试**
   - 使用现有管理员账号登录

4. **密码修改测试**
   - 修改密码后，用新密码登录验证

5. **密码重置测试**
   - 重置密码后，用默认密码123456登录验证

6. **新用户注册测试**
   - 注册新用户后，用注册密码登录验证

7. **后台添加用户测试**
   - 通过管理后台添加新用户后，用默认密码123456登录验证

## Performance Considerations

- MD5加密计算成本极低，对性能无明显影响
- 密码升级接口一次性执行，建议在低峰期运行

## Migration Notes

1. **数据备份**: 执行密码升级前，建议备份数据库
2. **停机时间**: 代码更新需要短暂重启服务
3. **回滚方案**: 如需回滚，需将数据库密码还原为明文

## Security Considerations

1. **升级接口安全**: `/upgradePasswords` 接口使用 `@IgnoreAuth` 注解，无需认证即可访问，存在安全风险
   - 建议：执行完后立即删除这些接口
   - 或：添加IP白名单限制

2. **MD5安全性**: MD5已被证明不够安全，建议后续升级到BCrypt等更安全的算法
   - 本计划不包含此升级，以保持变更范围最小

## References

- 问题报告: 用户 a1 密码 123456 无法登录小程序
- 相关文件:
  - `server/src/main/java/com/controller/YonghuController.java`
  - `server/src/main/java/com/controller/ShangjiaController.java`
  - `server/src/main/java/com/controller/UsersController.java`
  - `uni-mall/pages/login/login.vue`
- 数据库文件: `db_mall.sql`
