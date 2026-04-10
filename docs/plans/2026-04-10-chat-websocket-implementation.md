# Chat聊天功能WebSocket改造实施计划

## Overview

将现有的HTTP轮询聊天功能改造为WebSocket实时通信，采用内嵌式WebSocket服务器，保留HTTP API作为降级方案。

**当前状态**：移动端3秒轮询、管理后台5秒轮询
**目标状态**：WebSocket实时推送，HTTP API作为降级备用

## Current State Analysis

### 现有架构
```
┌─────────────┐     HTTP轮询(3s)      ┌──────────────┐
│  移动端     │ ─────────────────────> │              │
│  (uni-app)  │ <───────────────────── │  Spring Boot │
└─────────────┘      返回消息列表       │   后端服务器   │
                                     │              │
┌─────────────┐     HTTP轮询(5s)      │              │
│  管理后台   │ ─────────────────────> │              │
│  (Vue.js)   │ <───────────────────── │              │
└─────────────┘      返回消息列表       └──────────────┘
```

### 关键文件位置
| 组件 | 文件路径 |
|------|---------|
| 后端Controller | `server/src/main/java/com/controller/ChatController.java` |
| 后端Token服务 | `server/src/main/java/com/service/impl/TokenServiceImpl.java` |
| 认证拦截器 | `server/src/main/java/com/interceptor/AuthorizationInterceptor.java` |
| 管理后台列表 | `client/src/views/modules/chat/list.vue` |
| 管理后台回复 | `client/src/views/modules/chat/add-or-update.vue` |
| 移动端聊天 | `uni-mall/pages/chat/list.vue` |

### 约束条件
- Token认证机制：自定义数据库存储，请求头传递
- Spring Boot版本：2.2.2
- 前端无WebSocket库依赖
- 移动端支持uni.connectSocket原生API

## Desired End State

### 目标架构
```
┌─────────────┐     WebSocket连接      ┌──────────────────────────┐
│  移动端     │ <═══════════════════════> │                          │
│  (uni-app)  │     实时双向通信          │                          │
└─────────────┘                          │                          │
                                         │   Spring Boot           │
┌─────────────┐     WebSocket连接      │   + WebSocket Server     │
│  管理后台   │ <═══════════════════════> │   (内嵌式, 端口8080)      │
│  (Vue.js)   │     实时双向通信          │                          │
└─────────────┘                          │                          │
                                         │   - /zhinengxiaochengxsc/ws│
                                         │   - Token握手认证          │
                                         │   - 消息路由分发           │
                                         └──────────────────────────┘

降级方案：WebSocket连接失败时自动回退到HTTP轮询
```

### 核心功能
1. 用户上线建立WebSocket连接
2. 连接时通过Token验证身份
3. 管理员回复消息后，实时推送给在线用户
4. 用户发送消息后，实时通知管理员
5. 连接断开时自动重连
6. WebSocket不可用时降级到HTTP轮询

## What We're NOT Doing

- ❌ 不修改现有的HTTP API接口
- ❌ 不修改数据库表结构
- ❌ 不实现消息已读/未读状态
- ❌ 不实现独立的WebSocket服务器
- ❌ 不使用第三方WebSocket框架（如Socket.IO）

## Implementation Approach

### 技术选型

| 组件 | 技术方案 |
|------|---------|
| 后端 | Spring WebSocket + STOMP协议 |
| 前端(Vue) | 原生WebSocket API 或 sockjs-client + stompjs |
| 移动端 | uni.connectSocket 原生API |

### 消息协议设计

```json
// WebSocket消息格式
{
  "type": "MESSAGE",  // 消息类型: MESSAGE(聊天消息), NOTIFICATION(通知), HEARTBEAT(心跳)
  "action": "SEND",   // 动作: SEND(发送), REPLY(回复)
  "from": "yonghu",   // 发送者角色
  "fromId": 1,        // 发送者ID
  "to": "admin",      // 接收者角色
  "toId": null,       // 接收者ID
  "content": "你好",  // 消息内容
  "timestamp": "2026-04-10T15:00:00"
}
```

### 认证流程

```
1. 客户端发起WebSocket握手请求
   ws://host:8080/zhinengxiaochengxsc/ws?token=xxxxxxxx

2. 握手拦截器验证Token
   - 调用TokenService.getTokenEntity(token)
   - 验证失败返回401，断开连接

3. 验证成功后建立连接
   - 将用户信息存入WebSocket会话
   - 订阅个人消息队列: /user/{userId}/queue/messages
```

## Phase 1: 后端WebSocket服务器搭建

### Overview
在Spring Boot后端集成WebSocket服务器，实现连接管理、消息路由和推送功能。

### Changes Required:

#### 1. 添加Maven依赖

**File**: `server/pom.xml`

**Changes**: 添加WebSocket相关依赖

```xml
<!-- WebSocket支持 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>
<!-- 消息队列支持 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-messaging</artifactId>
</dependency>
```

#### 2. WebSocket配置类

**File**: `server/src/main/java/com/config/WebSocketConfig.java` (新建)

**Changes**: 创建WebSocket配置

```java
package com.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // 注册WebSocket端点，允许跨域
        registry.addEndpoint("/zhinengxiaochengxsc/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS();  // 支持SockJS降级
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // 启用简单消息代理
        registry.enableSimpleBroker("/topic", "/queue");
        // 设置应用目的地前缀
        registry.setApplicationDestinationPrefixes("/app");
    }
}
```

#### 3. WebSocket握手拦截器

**File**: `server/src/main/java/com/interceptor/WebSocketHandshakeInterceptor.java` (新建)

**Changes**: 创建握手拦截器验证Token

```java
package com.interceptor;

import com.service.TokenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

public class WebSocketHandshakeInterceptor implements HandshakeInterceptor {

    @Autowired
    private TokenService tokenService;

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {
        if (request instanceof ServletServerHttpRequest) {
            ServletServerHttpRequest servletRequest = (ServletServerHttpRequest) request;
            String token = servletRequest.getServletRequest().getParameter("token");

            if (token != null) {
                // 验证Token
                var tokenEntity = tokenService.getTokenEntity(token);
                if (tokenEntity != null) {
                    // 将用户信息存入WebSocket会话
                    attributes.put("userId", tokenEntity.getUserid());
                    attributes.put("role", tokenEntity.getRole());
                    attributes.put("tableName", tokenEntity.getTablename());
                    attributes.put("username", tokenEntity.getUsername());
                    return true;
                }
            }
        }
        return false;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                               WebSocketHandler wsHandler, Exception exception) {
    }
}
```

#### 4. WebSocket消息控制器

**File**: `server/src/main/java/com/controller/WebSocketChatController.java` (新建)

**Changes**: 创建WebSocket消息处理控制器

```java
package com.controller;

import com.entity.ChatEntity;
import com.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Controller
public class WebSocketChatController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private ChatService chatService;

    /**
     * 用户发送消息
     */
    @MessageMapping("/chat/send")
    public void handleUserMessage(Map<String, Object> message) {
        Integer userId = (Integer) message.get("fromId");
        String content = (String) message.get("content");

        // 保存消息到数据库
        ChatEntity chat = new ChatEntity();
        chat.setYonghuId(userId);
        chat.setChatIssue(content);
        chat.setIssueTime(new Date());
        chat.setZhuangtaiTypes(1);  // 未回复
        chat.setChatTypes(1);        // 问题类型
        chatService.insert(chat);

        // 通知所有在线管理员
        Map<String, Object> notification = new HashMap<>();
        notification.put("type", "MESSAGE");
        notification.put("action", "SEND");
        notification.put("from", "yonghu");
        notification.put("fromId", userId);
        notification.put("content", content);
        notification.put("timestamp", new Date());

        messagingTemplate.convertAndSend("/topic/admin/chat", notification);
    }

    /**
     * 管理员回复消息
     */
    @MessageMapping("/chat/reply")
    public void handleAdminReply(Map<String, Object> message) {
        Integer userId = (Integer) message.get("toId");
        String content = (String) message.get("content");
        Integer originalChatId = (Integer) message.get("originalChatId");

        // 保存回复到数据库
        ChatEntity reply = new ChatEntity();
        reply.setYonghuId(userId);
        reply.setChatReply(content);
        reply.setReplyTime(new Date());
        reply.setChatTypes(2);        // 回复类型
        chatService.insert(reply);

        // 更新原问题状态为已回复
        if (originalChatId != null) {
            ChatEntity original = chatService.selectById(originalChatId);
            if (original != null) {
                original.setZhuangtaiTypes(2);  // 已回复
                chatService.updateById(original);
            }
        }

        // 推送给指定用户
        Map<String, Object> notification = new HashMap<>();
        notification.put("type", "MESSAGE");
        notification.put("action", "REPLY");
        notification.put("from", "admin");
        notification.put("content", content);
        notification.put("timestamp", new Date());

        messagingTemplate.convertAndSend("/queue/user-" + userId + "/chat", notification);
    }

    /**
     * 心跳检测
     */
    @MessageMapping("/heartbeat")
    public void handleHeartbeat(Map<String, Object> message) {
        String role = (String) message.get("role");
        Integer userId = (Integer) message.get("userId");

        // 更新用户在线状态（可选：可扩展在线状态管理）
        Map<String, Object> pong = new HashMap<>();
        pong.put("type", "HEARTBEAT");
        pong.put("timestamp", new Date());

        if ("admin".equals(role)) {
            messagingTemplate.convertAndSend("/queue/admin-" + userId + "/heartbeat", pong);
        } else {
            messagingTemplate.convertAndSend("/queue/user-" + userId + "/heartbeat", pong);
        }
    }
}
```

#### 5. 更新配置类注册拦截器

**File**: `server/src/main/java/com/config/WebSocketConfig.java`

**Changes**: 修改配置，注册握手拦截器

```java
@Override
public void registerStompEndpoints(StompEndpointRegistry registry) {
    registry.addEndpoint("/zhinengxiaochengxsc/ws")
            .setAllowedOriginPatterns("*")
            .addInterceptors(new WebSocketHandshakeInterceptor())
            .withSockJS();
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Maven依赖安装成功: `cd server && mvn clean install`
- [ ] 编译无错误: `cd server && mvn compile`
- [ ] 服务启动成功: `cd server && mvn spring-boot:run`
- [ ] WebSocket端点可访问: `ws://localhost:8080/zhinengxiaochengxsc/ws`

#### Manual Verification:
- [ ] 使用WebSocket客户端工具（如Postman）能连接到WebSocket端点
- [ ] 传递有效token能成功建立连接
- [ ] 传递无效token返回401并断开连接
- [ ] 浏览器控制台无WebSocket相关错误

---

## Phase 2: 管理后台WebSocket客户端实现

### Overview
在Vue管理后台中集成WebSocket客户端，实现实时接收用户消息和发送回复。

### Changes Required:

#### 1. 安装WebSocket客户端库

**File**: `client/package.json`

**Changes**: 添加依赖

```json
{
  "dependencies": {
    "sockjs-client": "^1.6.1",
    "stompjs": "^2.3.3"
  }
}
```

执行安装: `cd client && npm install`

#### 2. 创建WebSocket服务

**File**: `client/src/utils/websocket.js` (新建)

**Changes**: 创建WebSocket连接管理服务

```javascript
import SockJS from 'sockjs-client'
import Stomp from 'stompjs'
import { Message } from 'element-ui'
import storage from './storage'

class WebSocketService {
  constructor() {
    this.client = null
    this.connected = false
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 5
    this.reconnectDelay = 3000
    this.subscriptions = {}
    this.messageHandlers = []
  }

  // 连接WebSocket
  connect() {
    const token = storage.get('Token')
    if (!token) {
      console.warn('No token found, skip WebSocket connection')
      return
    }

    // 使用SockJS（支持降级到HTTP）
    const socket = new SockJS(`http://localhost:8080/zhinengxiaochengxsc/ws?token=${token}`)
    this.client = Stomp.over(socket)

    // 关闭调试日志
    this.client.debug = () => {}

    // 连接成功回调
    this.client.connect({}, () => {
      this.connected = true
      this.reconnectAttempts = 0
      console.log('WebSocket connected successfully')

      // 订阅管理员消息频道
      this.subscribeToAdminMessages()

      // 启动心跳
      this.startHeartbeat()
    }, (error) => {
      console.error('WebSocket connection error:', error)
      this.connected = false
      this.handleReconnect()
    })
  }

  // 订阅管理员消息频道
  subscribeToAdminMessages() {
    if (!this.connected) return

    // 取消之前的订阅
    if (this.subscriptions.admin) {
      this.subscriptions.admin.unsubscribe()
    }

    // 订阅管理员聊天消息
    this.subscriptions.admin = this.client.subscribe('/topic/admin/chat', (message) => {
      const data = JSON.parse(message.body)
      console.log('Received chat message:', data)

      // 通知所有注册的消息处理器
      this.messageHandlers.forEach(handler => handler(data))

      // 显示通知
      if (data.action === 'SEND') {
        Message({
          type: 'info',
          message: `收到用户 ${data.fromId} 的新消息`,
          duration: 3000
        })
      }
    })
  }

  // 发送回复消息
  sendReply(toId, content, originalChatId) {
    if (!this.connected) {
      Message.error('WebSocket未连接，请稍后重试')
      return
    }

    const message = {
      toId: toId,
      content: content,
      originalChatId: originalChatId
    }

    this.client.send('/app/chat/reply', {}, JSON.stringify(message))
  }

  // 启动心跳
  startHeartbeat() {
    this.heartbeatInterval = setInterval(() => {
      if (this.connected) {
        this.client.send('/app/heartbeat', {}, JSON.stringify({
          type: 'HEARTBEAT',
          timestamp: new Date().toISOString()
        }))
      }
    }, 30000) // 每30秒发送一次心跳
  }

  // 处理重连
  handleReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      console.log(`Attempting to reconnect... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`)

      setTimeout(() => {
        this.connect()
      }, this.reconnectDelay)
    } else {
      Message.warning('WebSocket连接失败，已切换到HTTP轮询模式')
      // 通知父组件切换到降级模式
      window.dispatchEvent(new CustomEvent('websocket-failed'))
    }
  }

  // 注册消息处理器
  onMessage(handler) {
    this.messageHandlers.push(handler)
  }

  // 移除消息处理器
  offMessage(handler) {
    const index = this.messageHandlers.indexOf(handler)
    if (index > -1) {
      this.messageHandlers.splice(index, 1)
    }
  }

  // 断开连接
  disconnect() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
    }
    if (this.client && this.connected) {
      this.client.disconnect()
    }
    this.connected = false
  }
}

// 导出单例
const wsService = new WebSocketService()
export default wsService
```

#### 3. 修改消息列表页面

**File**: `client/src/views/modules/chat/list.vue`

**Changes**: 集成WebSocket，保留HTTP降级

```javascript
// 在script部分添加
import websocket from '@/utils/websocket'

export default {
  data() {
    return {
      // ...原有data
      useWebSocket: true,  // WebSocket开关
      wsConnected: false
    }
  },

  created() {
    // 尝试连接WebSocket
    this.initWebSocket()

    // 监听WebSocket失败事件，降级到HTTP轮询
    window.addEventListener('websocket-failed', () => {
      this.useWebSocket = false
      this.initHttpPolling()
    })
  },

  destroyed() {
    // 清理WebSocket连接
    if (this.useWebSocket) {
      websocket.disconnect()
    }
    window.removeEventListener('websocket-failed', this.initHttpPolling)
    if (this.inter) {
      clearInterval(this.inter)
    }
  },

  methods: {
    // 初始化WebSocket
    initWebSocket() {
      try {
        websocket.connect()
        this.wsConnected = websocket.connected

        // 注册消息处理器
        websocket.onMessage((data) => {
          if (data.action === 'SEND') {
            // 新消息到达，刷新列表
            this.getDataList()
          }
        })
      } catch (error) {
        console.error('WebSocket initialization failed:', error)
        this.initHttpPolling()
      }
    },

    // HTTP轮询降级方案
    initHttpPolling() {
      console.log('Switching to HTTP polling mode')
      this.inter = setInterval(() => this.getDataList(), 5000)
    },

    // 原有的getDataList方法保持不变
    getDataList() {
      // ...原有代码
    }
  }
}
```

#### 4. 修改回复页面

**File**: `client/src/views/modules/chat/add-or-update.vue`

**Changes**: 使用WebSocket发送回复

```javascript
import websocket from '@/utils/websocket'

export default {
  methods: {
    // 发送回复
    onSubmit() {
      const { chatReply } = this.ruleForm
      if (!chatReply) {
        this.$message.error('请输入回复内容')
        return
      }

      // 优先使用WebSocket发送
      if (websocket.connected) {
        websocket.sendReply(this.id, chatReply, this.chatDate.id)
        this.$message.success('回复发送成功')

        // 清空输入
        this.ruleForm.chatReply = ''

        // 刷新列表
        this.getList()
      } else {
        // 降级到HTTP请求
        this.sendReplyViaHttp()
      }
    },

    // HTTP降级发送
    sendReplyViaHttp() {
      // ...原有的HTTP发送逻辑
    }
  },

  destroyed() {
    if (this.inter) {
      clearInterval(this.inter)
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 依赖安装成功: `cd client && npm install`
- [ ] 编译无错误: `cd client && npm run build`
- [ ] 开发服务器启动成功: `cd client && npm run serve`

#### Manual Verification:
- [ ] 打开管理后台，浏览器控制台显示WebSocket连接成功
- [ ] 用户发送消息后，管理后台实时收到通知
- [ ] 管理员回复消息后，用户端实时收到回复
- [ ] 断开网络后，自动降级到HTTP轮询模式
- [ ] 恢复网络后，尝试重新连接WebSocket

---

## Phase 3: 移动端WebSocket客户端实现

### Overview
在uni-app移动端集成WebSocket，使用原生API实现实时通信。

### Changes Required:

#### 1. 创建WebSocket工具类

**File**: `uni-mall/utils/websocket.js` (新建)

**Changes**: 创建WebSocket连接管理工具

```javascript
class WebSocketService {
  constructor() {
    this.socket = null
    this.connected = false
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 5
    this.reconnectDelay = 3000
    this.heartbeatInterval = null
    this.messageHandlers = []
  }

  // 连接WebSocket
  connect() {
    const token = uni.getStorageSync('token')
    if (!token) {
      console.warn('No token found')
      return
    }

    // uni-app原生WebSocket API
    this.socket = uni.connectSocket({
      url: `ws://localhost:8080/zhinengxiaochengxsc/ws?token=${token}`,
      header: {
        'content-type': 'application/json'
      }
    })

    // 监听连接打开
    this.socket.onOpen(() => {
      this.connected = true
      this.reconnectAttempts = 0
      console.log('WebSocket connected')

      // 启动心跳
      this.startHeartbeat()
    })

    // 监听连接错误
    this.socket.onError((error) => {
      console.error('WebSocket error:', error)
      this.connected = false
      this.handleReconnect()
    })

    // 监听连接关闭
    this.socket.onClose(() => {
      console.log('WebSocket closed')
      this.connected = false
    })

    // 监听服务器消息
    this.socket.onMessage((message) => {
      try {
        const data = JSON.parse(message.data)
        console.log('Received message:', data)

        // 通知所有处理器
        this.messageHandlers.forEach(handler => handler(data))
      } catch (e) {
        console.error('Failed to parse message:', e)
      }
    })
  }

  // 发送消息
  send(message) {
    if (this.connected && this.socket) {
      this.socket.send({
        data: JSON.stringify(message)
      })
    }
  }

  // 发送聊天消息
  sendChatMessage(content) {
    const message = {
      type: 'MESSAGE',
      action: 'SEND',
      fromId: uni.getStorageSync('userId'),
      content: content,
      timestamp: new Date().toISOString()
    }
    this.send(message)
  }

  // 启动心跳
  startHeartbeat() {
    this.heartbeatInterval = setInterval(() => {
      if (this.connected) {
        this.send({
          type: 'HEARTBEAT',
          timestamp: new Date().toISOString()
        })
      }
    }, 30000)
  }

  // 处理重连
  handleReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      setTimeout(() => {
        this.connect()
      }, this.reconnectDelay)
    } else {
      // 触发降级事件
      uni.$emit('websocket-failed')
    }
  }

  // 注册消息处理器
  onMessage(handler) {
    this.messageHandlers.push(handler)
  }

  // 移除消息处理器
  offMessage(handler) {
    const index = this.messageHandlers.indexOf(handler)
    if (index > -1) {
      this.messageHandlers.splice(index, 1)
    }
  }

  // 断开连接
  close() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
    }
    if (this.socket) {
      this.socket.close()
    }
    this.connected = false
  }
}

// 导出单例
const ws = new WebSocketService()
export default ws
```

#### 2. 修改聊天页面

**File**: `uni-mall/pages/chat/list.vue`

**Changes**: 集成WebSocket发送和接收

```javascript
import ws from '@/utils/websocket'

export default {
  data() {
    return {
      // ...原有data
      useWebSocket: true
    }
  },

  onLoad() {
    // 尝试连接WebSocket
    this.initWebSocket()

    // 监听降级事件
    uni.$on('websocket-failed', () => {
      this.useWebSocket = false
      this.initHttpPolling()
    })
  },

  onUnload() {
    // 清理WebSocket
    if (this.useWebSocket) {
      ws.close()
    }
    uni.$off('websocket-failed', this.initHttpPolling)
    if (this.inter) {
      clearInterval(this.inter)
    }
  },

  methods: {
    // 初始化WebSocket
    initWebSocket() {
      try {
        ws.connect()

        // 注册消息处理器
        ws.onMessage((data) => {
          if (data.type === 'MESSAGE' && data.action === 'REPLY') {
            // 收到回复，刷新列表
            this.init()
          }
        })
      } catch (error) {
        console.error('WebSocket init failed:', error)
        this.initHttpPolling()
      }
    },

    // 发送消息
    onSendTap() {
      if (!this.chatIssue) {
        this.$utils.msg('请输入消息内容')
        return
      }

      // 优先使用WebSocket发送
      if (ws.connected && this.useWebSocket) {
        ws.sendChatMessage(this.chatIssue)
        this.chatIssue = ''

        // 刷新列表
        setTimeout(() => this.init(), 500)
      } else {
        // 降级到HTTP
        this.sendViaHttp()
      }
    },

    // HTTP降级发送
    sendViaHttp() {
      this.$api.save('chat', {
        chatIssue: this.chatIssue,
        zhuangtaiTypes: 1,
        chatTypes: 1,
        issueTime: this.$utils.getCurDateTime()
      }).then(() => {
        this.chatIssue = ''
        this.init()
      })
    },

    // HTTP轮询降级
    initHttpPolling() {
      this.inter = setInterval(() => this.init(), 3000)
    },

    // 原有的init方法保持不变
    init() {
      // ...原有代码
    }
  }
}
```

#### 3. 修改API基础URL配置

**File**: `uni-mall/api/base.js`

**Changes**: 添加WebSocket URL配置

```javascript
// 原有HTTP配置
const BASE_URL = process.env.NODE_ENV === 'development'
  ? 'http://localhost:8080/zhinengxiaochengxsc/'
  : 'http://47.83.117.201:8080/zhinengxiaochengxsc/'

// 新增WebSocket URL配置
const WS_URL = process.env.NODE_ENV === 'development'
  ? 'ws://localhost:8080/zhinengxiaochengxsc/ws'
  : 'ws://47.83.117.201:8080/zhinengxiaochengxsc/ws'

export default {
  BASE_URL,
  WS_URL
}
```

### Success Criteria:

#### Automated Verification:
- [ ] HBuilderX编译无错误
- [ ] 微信开发者工具编译无错误

#### Manual Verification:
- [ ] 在微信小程序中打开聊天页面
- [ ] 控制台显示WebSocket连接成功
- [ ] 发送消息后，管理后台实时收到
- [ ] 收到回复后，页面实时刷新显示
- [ ] 断网后自动降级到HTTP轮询

---

## Testing Strategy

### 单元测试

#### 后端测试
- WebSocket握手拦截器测试
- Token验证逻辑测试
- 消息路由测试
- 消息推送测试

#### 前端测试
- WebSocket连接建立测试
- 消息发送接收测试
- 降级逻辑测试

### 集成测试场景

1. **用户发送消息流程**
   - 用户上线建立WebSocket连接
   - 用户发送消息
   - 管理后台实时收到通知
   - 管理后台消息列表自动刷新

2. **管理员回复流程**
   - 管理员打开回复界面
   - 发送回复消息
   - 用户端实时收到回复
   - 用户聊天界面自动刷新

3. **降级场景测试**
   - WebSocket服务关闭
   - 客户端自动切换到HTTP轮询
   - 消息仍能正常收发

4. **并发测试**
   - 多个用户同时在线
   - 同时发送多条消息
   - 验证消息不丢失

### 手动测试步骤

1. **启动后端服务**
   ```bash
   cd server && mvn spring-boot:run
   ```

2. **启动管理后台**
   ```bash
   cd client && npm run serve
   ```

3. **启动移动端**
   - 使用HBuilderX运行到微信开发者工具

4. **测试聊天功能**
   - 用户端登录并发送消息
   - 检查管理后台是否实时收到
   - 管理员回复消息
   - 检查用户端是否实时收到

## Performance Considerations

### 服务器端
- WebSocket连接数限制：配置适当的线程池大小
- 消息队列：考虑使用Redis Pub/Sub替代简单消息代理（高并发场景）
- 心跳间隔：30秒平衡实时性和资源消耗

### 客户端
- 重连延迟：3秒 exponential backoff
- 消息缓冲：离线期间的消息通过HTTP获取
- 内存管理：及时清理断开的连接

## Migration Notes

### 兼容性保证
- 保留所有现有HTTP API
- 客户端优先使用WebSocket，失败时降级
- 数据库结构不变

### 部署步骤
1. 停止现有服务
2. 更新后端jar包（包含WebSocket依赖）
3. 更新前端代码
4. 重启服务

### 回滚方案
- 如果WebSocket有问题，可以通过配置禁用
- 客户端自动降级到HTTP轮询

## References

- 相关研究: `docs/research/2026-04-10-chat-functionality-implementation.md`
- Spring WebSocket文档: https://docs.spring.io/spring-framework/reference/web/websocket.html
- uni-app WebSocket API: https://uniapp.dcloud.net.cn/api/websocket.html
