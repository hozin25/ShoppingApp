---
date: 2026-04-10T14:45:22+08:00
researcher: fjc
git_commit: c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51
branch: master
repository: hozin25/ShoppingApp
topic: "用户和商家聊天功能实现研究"
tags: [research, codebase, chat, customer-service, uni-app, vue, spring-boot]
status: complete
last_updated: 2026-04-10
last_updated_by: fjc
originSessionId: db5fde8f-5ce3-47af-aef7-2bc10747e6d9
---
# Research: 用户和商家聊天功能实现研究

**Date**: 2026-04-10T14:45:22+08:00
**Researcher**: fjc
**Git Commit**: c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51
**Branch**: master
**Repository**: hozin25/ShoppingApp

## Research Question

研究用户和商家聊天功能的实现

## Summary

聊天功能是一个在线客服系统，实现了用户(yonghu)与管理员之间的消息沟通。系统包含三个主要实现：
1. **后端API** (Spring Boot) - 提供消息存储、查询、状态管理
2. **管理后台** (Vue.js) - 管理员查看和回复用户消息
3. **移动端** (uni-app) - 用户发送消息和查看回复

系统采用轮询机制实时更新消息，使用MySQL存储聊天记录，通过字典表管理消息类型和状态。

## Detailed Findings

### 数据库结构

**Chat表定义** ([`server/db_mall.sql:75-86`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/server/db_mall.sql#L75-L86))

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | int(11) | 主键，自增 |
| `yonghu_id` | int(11) | 提问用户ID，关联yonghu表 |
| `chat_issue` | varchar(200) | 用户问题内容 |
| `issue_time` | timestamp | 问题提交时间 |
| `chat_reply` | varchar(200) | 管理员回复内容 |
| `reply_time` | timestamp | 回复时间 |
| `zhuangtai_types` | int(255) | 状态码（1=未回复，2=已回复） |
| `chat_types` | int(11) | 数据类型（1=问题，2=回复） |
| `insert_time` | timestamp | 记录创建时间 |

**关联表**:
- `yonghu` - 用户表，通过`yonghu_id`关联
- `dictionary` - 字典表，存储状态和类型的显示值

### 后端实现 (Spring Boot)

#### 1. Entity层 - [`ChatEntity.java`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/server/src/main/java/com/entity/ChatEntity.java)

- 使用MyBatis-Plus的`@TableName("chat")`映射表
- 主键`id`配置为自增
- `insertTime`字段配置`FieldFill.INSERT`自动填充

#### 2. Dao层 - [`ChatDao.java`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f2b37d16ef6fba4ee0ea5b51/server/src/main/java/com/dao/ChatDao.java) / [`ChatDao.xml`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/server/src/main/java/com/dao/mapping/ChatDao.xml)

- 继承`BaseMapper<ChatEntity>`获得CRUD方法
- `selectListView`方法实现分页查询，LEFT JOIN关联yonghu表获取用户信息

#### 3. Service层 - [`ChatService.java`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/server/src/main/java/com/service/ChatService.java) / [`ChatServiceImpl.java`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/server/src/main/java/com/impl/ChatServiceImpl.java)

- `queryPage`方法处理分页查询请求

#### 4. Controller层 - [`ChatController.java`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/server/src/main/java/com/controller/ChatController.java)

**管理员后台端点**:
- `POST /chat/page` - 分页获取消息列表（带角色过滤）
- `GET /chat/info/{id}` - 获取单条消息详情
- `POST /chat/save` - 保存新消息
- `PUT /chat/update` - 更新消息
- `DELETE /chat/delete` - 删除消息

**移动端公开端点** (`@IgnoreAuth`):
- `GET /chat/list` - 获取消息列表
- `GET /chat/detail/{id}` - 获取消息详情
- `POST /chat/add` - 添加新消息

**关键逻辑**:
- 角色过滤：根据session中的role自动添加yonghuId或shangjiaId过滤条件
- 字典转换：将zhuangtaiTypes和chatTypes转换为显示文本
- 重复检查：保存前检查是否存在相同记录

### 管理后台实现 (Vue.js)

#### 路由配置 - [`client/src/router/router-static.js`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/client/src/router/router-static.js)

- `/chat` - 在线客服消息列表
- `/dictionaryChat` - 聊天数据类型字典管理

#### 消息列表组件 - [`client/src/views/modules/chat/list.vue`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f2b37d16ef6fba4ee0ea5b51/client/src/views/modules/chat/list.vue)

**功能**:
- 5秒轮询自动刷新未回复消息（zhuangtaiTypes=1, chatTypes=1）
- 表格显示消息内容、时间、状态
- 点击"回复"按钮打开回复界面

**关键代码**:
```javascript
// 轮询机制 (第77-82行)
created() {
    this.inter = setInterval(() => this.getDataList(), 5000)
}
```

#### 回复界面组件 - [`client/src/views/modules/chat/add-or-update.vue`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/client/src/views/modules/chat/add-or-update.vue)

**功能**:
- 获取指定用户的所有聊天记录
- 以聊天气泡形式展示对话历史
- 提交回复时：
  1. 保存回复消息（chatTypes=2）
  2. 更新原消息状态为已回复（zhuangtaiTypes=2）

**关键代码**:
```javascript
// 发送回复 (第82-116行)
onSubmit() {
    // 保存回复消息
    this.$http({
        url: 'chat/save',
        method: 'post',
        data: {
            yonghuId: this.id,
            chatReply: this.ruleForm.chatReply,
            replyTime: this.getCurDateTime(),
            chatTypes: 2
        }
    }).then(() => {
        // 更新原消息状态
        this.$http({
            url: 'chat/update',
            method: 'post',
            data: {
                ...this.chatDate,
                zhuangtaiTypes: 2
            }
        })
    })
}
```

### 移动端实现 (uni-app)

#### 路由配置 - [`uni-mall/pages.json`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/uni-mall/pages.json)

- `pages/chat/list` - 在线客服展示
- `pages/chat/list2` - 我的在线客服
- `pages/chat/add-or-update` - 在线客服添加/修改
- `pages/chat/detail` - 在线客服详情

#### 聊天页面 - [`uni-mall/pages/chat/list.vue`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/uni-mall/pages/chat/list.vue)

**功能**:
- 3秒轮询获取新消息
- 左侧显示用户消息（绿色），右侧显示客服回复（默认色）
- 底部输入框发送新消息

**关键代码**:
```javascript
// 轮询机制 (第44-50行)
onLoad() {
    this.inter = setInterval(() => this.init(), 3000)
}

// 发送消息 (第58-67行)
onSendTap() {
    this.$api.save('chat', {
        chatIssue: this.chatIssue,
        zhuangtaiTypes: 1,
        chatTypes: 1,
        issueTime: this.$utils.getCurDateTime()
    }).then(() => {
        this.chatIssue = ''
        this.init()
    })
}
```

#### API层 - [`uni-mall/api/index.js`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/uni-mall/api/index.js)

**相关方法**:
- `page('chat', data)` - 分页获取消息
- `save('chat', data)` - 保存新消息
- `info('chat', id)` - 获取消息详情
- `update('chat', data)` - 更新消息

**基础URL** ([`uni-mall/api/base.js`](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/uni-mall/api/base.js)):
- 开发: `http://localhost:8080/zhinengxiaochengxsc/`
- 生产: `http://47.83.117.201:8080/zhinengxiaochengxsc/`

## Code References

### 后端文件
- `server/src/main/java/com/entity/ChatEntity.java` - 聊天实体类
- `server/src/main/java/com/dao/ChatDao.java` - 数据访问接口
- `server/src/main/java/com/dao/mapping/ChatDao.xml` - MyBatis SQL映射
- `server/src/main/java/com/service/ChatService.java` - 业务逻辑接口
- `server/src/main/java/com/impl/ChatServiceImpl.java` - 业务逻辑实现
- `server/src/main/java/com/controller/ChatController.java` - REST控制器
- `server/src/main/java/com/entity/ChatView.java` - 视图对象（含用户信息）
- `server/src/main/java/com/entity/ChatVO.java` - 移动端VO对象
- `server/src/main/java/com/entity/ChatModel.java` - 请求参数模型
- `server/db_mall.sql:75-86` - Chat表SQL定义

### 管理后台文件
- `client/src/views/modules/chat/list.vue` - 消息列表页面
- `client/src/views/modules/chat/add-or-update.vue` - 回复界面
- `client/src/views/modules/dictionaryChat/list.vue` - 字典管理列表
- `client/src/views/modules/dictionaryChat/add-or-update.vue` - 字典编辑
- `client/src/router/router-static.js:170-172` - 聊天路由配置

### 移动端文件
- `uni-mall/pages/chat/list.vue` - 聊天页面
- `uni-mall/pages/chat/list2.vue` - 备用聊天页面
- `uni-mall/pages/chat/detail.vue` - 聊天详情页
- `uni-mall/pages/chat/add-or-update.vue` - 添加/修改页面
- `uni-mall/pages.json:101-127` - 聊天页面路由配置
- `uni-mall/api/base.js` - API基础配置
- `uni-mall/api/http.js` - HTTP客户端
- `uni-mall/api/index.js` - API方法定义

## Architecture Documentation

### 数据模型

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   yonghu    │         │    chat     │         │   users     │
│  (用户表)    │         │  (聊天记录)  │         │  (管理员)    │
├─────────────┤         ├─────────────┤         ├─────────────┤
│ id (PK)     │◄────────│ yonghu_id   │         │ id          │
│ username    │         │ chat_issue  │         │ username    │
│ yonghu_name │         │ chat_reply  │(隐式引用)│             │
└─────────────┘         │ zhuangtai_  │         └─────────────┘
                        │ types       │
                        │ chat_types  │
                        └─────────────┘
                               ▲
                               │
                        ┌──────┴──────┐
                        │ dictionary  │
                        │ (字典表)     │
                        ├─────────────┤
                        │ code=1: 未回复│
                        │ code=2: 已回复│
                        │ code=1: 问题  │
                        │ code=2: 回复  │
                        └─────────────┘
```

### 消息流转

**用户发送消息流程**:
```
用户端(uni-app)                后端(Spring Boot)              管理后台(Vue)
     │                              │                           │
     │  1. 输入消息                   │                           │
     │  2. 点击发送                   │                           │
     ├─────────────────────────────>│                           │
     │  POST /chat/add              │                           │
     │  {chatIssue, chatTypes:1}    │                           │
     │                              │                           │
     │                              │  3. 保存到chat表           │
     │                              │  {zhuangtaiTypes:1}        │
     │                              │                           │
     │  4. 返回成功                  │                           │
     │<─────────────────────────────┤                           │
     │                              │                           │
     │  5. 轮询刷新 (3秒)             │                           │
     ├─────────────────────────────>│                           │
     │  GET /chat/list              │                           │
     │<─────────────────────────────┤                           │
     │                              │                           │
     │                              │  6. 轮询刷新 (5秒)           │
     │                              ├──────────────────────────>│
     │                              │  GET /chat/page           │
     │                              │  ?zhuangtaiTypes=1        │
     │                              │<──────────────────────────┤
     │                              │                           │
     │                              │                           │  7. 显示新消息
     │                              │                           │  8. 点击"回复"
     │                              │  9. 打开回复界面            │
     │                              │<──────────────────────────┤
     │                              │                           │
     │                              │  10. 获取聊天历史            │
     │                              │<──────────────────────────┤
     │                              │  GET /chat/page?yonghuId= │
     │                              │──────────────────────────>│
     │                              │  返回历史记录               │
     │                              │                           │
     │                              │  11. 输入并提交回复          │
     │                              │<──────────────────────────┤
     │                              │  POST /chat/save          │
     │                              │  {chatReply, chatTypes:2} │
     │                              │  POST /chat/update        │
     │                              │  {zhuangtaiTypes:2}       │
     │                              │                           │
     │  12. 轮询获取回复              │                           │
     ├─────────────────────────────>│                           │
     │  GET /chat/list              │                           │
     │<─────────────────────────────┤                           │
     │  13. 显示客服回复              │                           │
```

### 轮询机制

| 端 | 间隔 | API调用 | 筛选条件 |
|---|------|---------|---------|
| 移动端 | 3秒 | `GET /chat/list` | 按yonghuId筛选 |
| 管理后台 | 5秒 | `GET /chat/page` | zhuangtaiTypes=1, chatTypes=1 |

## Related Research

- [2026-03-23-token-verification-mechanism.md](https://github.com/hozin25/ShoppingApp/blob/c514a09c55c7b2f1f2b37d16ef6fba4ee0ea5b51/memory/thoughts/shared/research/2026-03-23-token-verification-mechanism.md) - Token验证机制研究

## Open Questions

无
