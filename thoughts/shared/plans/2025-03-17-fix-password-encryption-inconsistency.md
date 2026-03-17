# 密码加密一致性修复计划

## Overview

修复小程序登录功能中用户密码加密不一致的问题。当前用户表(yonghu)通过管理后台保存时密码为明文存储，但登录时使用MD5加密验证，导致验证失败。

## Current State Analysis

### 问题现象
- 用户在小程序输入账号 `a1`，密码 `123456`，无法登录
- 弹窗提示"账号或密码不正确"

### 根本原因
| 用户类型 | 登录验证方式 | 保存时密码 | 注册时密码 |
|---------|------------|----------|----------|
| 用户(yonghu) | **MD5加密验证** | **明文"123456"** | MD5加密 |
| 商家(shangjia) | 明文验证 | 明文"123456" | 明文 |
| 管理员(users) | 明文验证 | 明文 | 明文 |

### YonghuController.java 问题位置

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

### 数据库当前状态
- `yonghu` 表中用户 `a1` 的密码为明文 `123456`
- MD5("123456") = `e10adc3949ba59abbe56e057f20f883e`
- 验证时比较 `e10adc3949ba59abbe56e057f20f883e` != `123456` → 失败

## Desired End State

用户(yonghu)表密码处理统一：
1. 密码在存储前使用MD5加密
2. 登录验证使用MD5加密比较
3. 修改密码功能使用MD5加密
4. 重置密码功能使用MD5加密

### 验证方式
- 用户 a1 可以使用密码 123456 正常登录
- 新添加的用户可以正常登录
- 密码修改功能正常工作
- 密码重置功能正常工作

## What We're NOT Doing

- **本次不修改商家(shangjia)和管理员(users)** - 留待后续阶段
- 不修改现有的密码加密算法（继续使用MD5）
- 不修改数据库表结构
- 不修改前端代码
- 不升级到更安全的加密算法（如BCrypt）

## Implementation Approach

```
┌─────────────────────────────────────────────────────────────────┐
│ Phase 1: 修复 YonghuController.java                              │
│   - 修改 save 方法 (第150行)                                      │
│   - 修改 add 方法 (第507行)                                       │
├─────────────────────────────────────────────────────────────────┤
│ Phase 2: 升级 yonghu 表现有密码                                   │
│   - 访问 /yonghu/upgradePasswords 接口                            │
├─────────────────────────────────────────────────────────────────┤
│ 手动测试                                                          │
│   - 用户 a1 使用密码 123456 登录                                  │
│   - 新用户注册/登录                                               │
│   - 修改密码/重置密码                                             │
├─────────────────────────────────────────────────────────────────┤
│ Phase 3: (测试通过后) 修复 shangjia 和 users 表                   │
│   - 等待用户确认测试通过后再执行                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: 修复 YonghuController.java

### 修改 save 方法 (第150行)
**File**: `server/src/main/java/com/controller/YonghuController.java`

```java
// 修改前
yonghu.setPassword("123456");

// 修改后
yonghu.setPassword(DigestUtils.md5Hex("123456"));
```

### 修改 add 方法 (第507行)
**File**: `server/src/main/java/com/controller/YonghuController.java`

```java
// 修改前
yonghu.setPassword("123456");

// 修改后
yonghu.setPassword(DigestUtils.md5Hex("123456"));
```

### Success Criteria - Phase 1:

#### Automated Verification:
- [ ] 代码编译成功: `cd server && mvn clean compile`
- [ ] 无编译错误

#### Manual Verification:
- [ ] 重启后端服务成功

---

## Phase 2: 升级 yonghu 表现有密码

### 使用已有升级接口

后端已经提供了密码升级接口 `YonghuController.upgradePasswords()` (第517-536行)。

**操作步骤**:
1. 确保后端服务正在运行
2. 访问URL: `http://localhost:8080/zhinengxiaochengxsc/yonghu/upgradePasswords`
3. 验证返回成功消息

### Success Criteria - Phase 2:

#### Automated Verification:
- [ ] 升级接口返回成功

#### Manual Verification:
- [ ] **用户 a1 使用密码 123456 可以成功登录** ← 关键测试
- [ ] 错误密码登录被拒绝

**Implementation Note**: 测试通过后，建议删除 `/upgradePasswords` 接口或添加权限保护。

---

## 手动测试步骤

完成 Phase 1 和 Phase 2 后，请进行以下手动测试：

### 1. 用户登录测试
- [ ] 账号: a1, 密码: 123456 → 应**成功登录**
- [ ] 账号: a1, 密码: wrong → 应提示密码错误

### 2. 新用户注册测试
- [ ] 注册新用户后，用注册密码登录验证

### 3. 密码修改测试
- [ ] 修改密码后，用新密码登录验证

### 4. 密码重置测试
- [ ] 重置密码后，用默认密码123456登录验证

### 5. 后台添加用户测试
- [ ] 通过管理后台添加新用户后，用默认密码123456登录验证

### 测试结果确认

**请在此确认测试结果：**
- [ ] 所有测试通过 → 告诉我，继续 Phase 3
- [ ] 有问题 → 描述具体问题

---

## Phase 3: 修复 shangjia 和 users 表 (等待用户确认)

**仅当 Phase 1 + Phase 2 测试通过后才执行此阶段**

### ShangjiaController.java 需要修改的位置
- save 方法 (第151行)
- login 方法 (第304行)
- add 方法 (第486行)
- updatePassword 方法 (第363, 369行)
- resetPassword 方法 (第349行)
- resetPass 方法 (第384行)

### UsersController.java 需要修改的位置
- login 方法 (第48行) - 需添加 import DigestUtils
- updatePassword 方法 (第91, 97行)
- resetPass 方法 (第112行)

### 需要添加的升级接口
- ShangjiaController: `/shangjia/upgradePasswords`
- UsersController: `/users/upgradePasswords`

---

## Performance Considerations

- MD5加密计算成本极低，对性能无明显影响
- 密码升级接口一次性执行，建议在低峰期运行

## Migration Notes

1. **数据备份**: 执行密码升级前，建议备份数据库
2. **停机时间**: 代码更新需要短暂重启服务
3. **回滚方案**: 如需回滚，需将数据库密码还原为明文

## Security Considerations

1. **升级接口安全**: `/upgradePasswords` 接口使用 `@IgnoreAuth` 注解，无需认证即可访问
   - 建议：测试完成后删除此接口

2. **MD5安全性**: MD5已被证明不够安全，建议后续升级到BCrypt
   - 本次修复不包含此升级

## References

- 问题报告: 用户 a1 密码 123456 无法登录小程序
- 相关文件:
  - `server/src/main/java/com/controller/YonghuController.java`
  - `uni-mall/pages/login/login.vue`
- 数据库文件: `db_mall.sql`
