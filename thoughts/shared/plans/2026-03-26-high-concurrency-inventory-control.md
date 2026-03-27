# 高并发库存控制实施计划

## Overview

实施 `Redis预扣减 + RabbitMQ消息队列` 方案来防止商品超卖，支持高并发场景（QPS > 10000）。该方案通过Redis快速预扣减库存拦截大部分请求，使用消息队列削峰填谷异步处理订单，最终通过数据库锁保证数据一致性。

## Current State Analysis

### 当前实现存在的并发问题

**文件**: `server/src/main/java/com/controller/ShangpinOrderController.java:431-528`

```java
// 当前实现 - 存在超卖风险
for (int i = 0; i < shangpins.size(); i++) {
    ShangpinEntity shangpinEntity = shangpinService.selectById(shangpinId);

    // 问题1: 检查和更新不是原子操作
    if(shangpinEntity.getShangpinKucunNumber() < buyNumber){
        return R.error(shangpinEntity.getShangpinName()+"的库存不足");
    }
    // 问题2: 中间有时间窗口，其他请求可能也通过检查
    shangpinEntity.setShangpinKucunNumber(shangpinEntity.getShangpinKucunNumber() - buyNumber);
}

// 问题3: 批量更新可能在事务外互相覆盖
shangpinService.updateBatchById(shangpinList);
```

**问题分析**：
1. **竞态条件**：检查和更新之间存在时间窗口
2. **无锁机制**：没有乐观锁或悲观锁保护
3. **批量更新风险**：`updateBatchById` 生成多条独立UPDATE语句
4. **事务边界不清**：Controller层没有事务控制

### 当前技术栈

- Spring Boot 2.2.2
- MyBatis-Plus 2.3
- MySQL (InnoDB)
- **无Redis配置**
- **无消息队列配置**

## Desired End State

### 架构设计

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              高并发库存控制架构                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

用户请求
   ↓
┌───────────────────────────────────────────────────────────────────────────────────┐
│ 第一层: 参数校验 (Controller)                                                      │
│ - 验证收货地址                                                                      │
│ - 验证商品存在                                                                      │
│ - 快速失败                                                                         │
└───────────────────────────────────────────────────────────────────────────────────┘
   ↓
┌───────────────────────────────────────────────────────────────────────────────────┐
│ 第二层: Redis预扣减 (核心防护)                                                       │
│ - Lua脚本原子操作                                                                  │
│ - 拦截80%+的请求                                                                   │
└───────────────────────────────────────────────────────────────────────────────────┘
   ↓ (预扣减成功)
┌───────────────────────────────────────────────────────────────────────────────────┐
│ 第三层: 发送消息到队列                                                              │
│ - 异步下单                                                                         │
│ - 立即返回"下单成功，请等待处理"                                                     |
│ - 削峰填谷                                                                         │
└───────────────────────────────────────────────────────────────────────────────────┘
   ↓
┌───────────────────────────────────────────────────────────────────────────────────┐
│ 第四层: 消息队列消费者 (后台处理)                                                     │
│ - 从队列获取订单消息                                                                │
│ - 分布式锁保护                                                                      │
│ - 真实的库存扣减                                                                    │
│ - 订单创建                                                                         │
└───────────────────────────────────────────────────────────────────────────────────┘
   ↓
┌───────────────────────────────────────────────────────────────────────────────────┐
│ 第五层: 数据库 (最终一致)                                                           │
│ - 悲观锁更新                                                                       │
│ - 事务保证                                                                         │
│ - 失败自动回滚Redis                                                                 │
└───────────────────────────────────────────────────────────────────────────────────┘
```

### 核心流程

**成功场景**：
```
1. 用户下单 → Redis预扣减成功 → 发送消息到队列 → 返回"下单成功"
2. 消费者获取消息 → 获取分布式锁 → 扣减数据库库存 → 创建订单 → 释放锁
3. 返回"订单处理完成"通知用户
```

**失败场景**：
```
1. Redis库存不足 → 直接返回"库存不足"，不进入队列
2. 数据库扣减失败 → 发送失败消息 → 回滚Redis → 通知用户退款
3. 消费失败 → 消息进入死信队列 → 人工处理
```

## What We're NOT Doing

- ❌ 不修改数据库表结构（不加version字段）
- ❌ 不实现复杂的分布式事务（使用最终一致性）
- ❌ 不实现订单优先级功能（简化实现，保证核心功能）
- ❌ 不实现库存预留/释放机制（简化为直接扣减）

## Implementation Approach

采用**分阶段实施**策略，每个阶段可独立验证：
1. **Phase 1**: Redis基础设施搭建
2. **Phase 2**: Redis库存预扣减实现
3. **Phase 3**: RabbitMQ消息队列集成
4. **Phase 4**: 订单消费者实现
5. **Phase 5**: 异常处理和回滚机制
6. **Phase 6**: 前端适配和测试

---

## Phase 1: Redis基础设施搭建

### Overview
添加Redis依赖、配置和基础工具类，为后续预扣减功能提供支持。

### Changes Required:

#### 1.1 添加Maven依赖

**File**: `server/pom.xml`

在 `<dependencies>` 节点添加：

```xml
<!-- Redis依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- Redisson分布式锁 -->
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson-spring-boot-starter</artifactId>
    <version>3.24.3</version>
</dependency>

<!-- Jedis连接池 -->
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
</dependency>

<!-- RabbitMQ依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

#### 1.2 添加Redis配置

**File**: `server/src/main/resources/application.yml`

在 `spring` 节点下添加：

```yaml
  # Redis配置
  redis:
    host: 127.0.0.1
    port: 6379
    password:
    database: 0
    timeout: 3000ms
    jedis:
      pool:
        max-active: 8
        max-wait: -1ms
        max-idle: 8
        min-idle: 0

  # RabbitMQ配置
  rabbitmq:
    host: 127.0.0.1
    port: 5672
    username: guest
    password: guest
    virtual-host: /
    listener:
      simple:
        acknowledge-mode: manual
        concurrency: 10
        max-concurrency: 50
        prefetch: 1
```

#### 1.3 创建Redis配置类

**File**: `server/src/main/java/com/config/RedisConfig.java` (新建)

```java
package com.config;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);

        Jackson2JsonRedisSerializer serializer = new Jackson2JsonRedisSerializer(Object.class);

        ObjectMapper mapper = new ObjectMapper();
        mapper.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        mapper.activateDefaultTyping(LaissezFaireSubTypeValidator.instance,
                ObjectMapper.DefaultTyping.NON_FINAL);

        serializer.setObjectMapper(mapper);

        StringRedisSerializer stringSerializer = new StringRedisSerializer();
        template.setKeySerializer(stringSerializer);
        template.setHashKeySerializer(stringSerializer);
        template.setValueSerializer(serializer);
        template.setHashValueSerializer(serializer);

        template.afterPropertiesSet();
        return template;
    }
}
```

#### 1.4 创建Redisson配置类

**File**: `server/src/main/java/com/config/RedissonConfig.java` (新建)

```java
package com.config;

import org.redisson.Redisson;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RedissonConfig {

    @Value("${spring.redis.host:127.0.0.1}")
    private String host;

    @Value("${spring.redis.port:6379}")
    private String port;

    @Value("${spring.redis.password:}")
    private String password;

    @Value("${spring.redis.database:0}")
    private int database;

    @Bean
    public RedissonClient redissonClient() {
        Config config = new Config();
        String address = "redis://" + host + ":" + port;

        config.useSingleServer()
                .setAddress(address)
                .setDatabase(database)
                .setConnectionPoolSize(64)
                .setConnectionMinimumIdleSize(10)
                .setIdleConnectionTimeout(10000)
                .setConnectTimeout(10000)
                .setTimeout(3000)
                .setRetryAttempts(3)
                .setRetryInterval(1500);

        if (password != null && !password.isEmpty()) {
            config.useSingleServer().setPassword(password);
        }

        return Redisson.create(config);
    }
}
```

#### 1.5 创建库存Redis Key常量类

**File**: `server/src/main/java/com/constants/RedisKeyConstants.java` (新建)

```java
package com.constants;

public class RedisKeyConstants {

    /**
     * 库存缓存Key前缀
     */
    public static final String INVENTORY_CACHE_PREFIX = "inventory:cache:";

    /**
     * 库存锁Key前缀
     */
    public static final String INVENTORY_LOCK_PREFIX = "inventory:lock:";

    /**
     * 获取库存缓存Key
     */
    public static String getInventoryCacheKey(Integer productId) {
        return INVENTORY_CACHE_PREFIX + productId;
    }

    /**
     * 获取库存锁Key
     */
    public static String getInventoryLockKey(Integer productId) {
        return INVENTORY_LOCK_PREFIX + productId;
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 项目编译成功: `cd server && mvn clean compile`
- [ ] Redis连接测试通过: 启动项目后无Redis连接异常
- [ ] Redisson客户端初始化成功: 检查日志无错误

#### Manual Verification:
- [ ] 安装并启动Redis服务
- [ ] 使用Redis-cli连接测试
- [ ] 检查Spring Boot启动日志确认Redis连接成功

**Implementation Note**: 完成此阶段后，确保Redis服务正常运行，然后进行下一阶段。

---

## Phase 2: Redis库存预扣减实现

### Overview
实现Redis库存的初始化、查询和原子性预扣减功能，使用Lua脚本保证操作的原子性。

### Changes Required:

#### 2.1 创建库存服务接口

**File**: `server/src/main/java/com/service/InventoryService.java` (新建)

```java
package com.service;

import java.util.Map;

public interface InventoryService {

    /**
     * 初始化库存到Redis
     */
    boolean initInventoryToRedis(Integer productId, Integer quantity);

    /**
     * 批量初始化库存到Redis
     */
    int batchInitInventoryToRedis(Map<Integer, Integer> inventoryMap);

    /**
     * 预扣减库存（原子操作）
     */
    boolean deductInventory(Integer productId, Integer quantity);

    /**
     * 回滚库存（预扣减失败时恢复）
     */
    boolean rollbackInventory(Integer productId, Integer quantity);

    /**
     * 获取Redis中的库存数量
     */
    Integer getInventoryFromRedis(Integer productId);

    /**
     * 从数据库同步库存到Redis
     */
    boolean syncInventoryFromDb(Integer productId);
}
```

#### 2.2 创建库存服务实现类

**File**: `server/src/main/java/com/service/impl/InventoryServiceImpl.java` (新建)

```java
package com.service.impl;

import com.baomidou.mybatisplus.mapper.EntityWrapper;
import com.constants.RedisKeyConstants;
import com.entity.ShangpinEntity;
import com.service.InventoryService;
import com.service.ShangpinService;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
public class InventoryServiceImpl implements InventoryService {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired
    private RedissonClient redissonClient;

    @Autowired
    private ShangpinService shangpinService;

    /**
     * Lua脚本：预扣减库存（原子操作）
     */
    private static final String DEDUCT_INVENTORY_SCRIPT =
            "local stock = redis.call('get', KEYS[1]) " +
            "if stock == false then " +
            "    return -1 " +
            "end " +
            "if tonumber(stock) >= tonumber(ARGV[1]) then " +
            "    redis.call('decrby', KEYS[1], ARGV[1]) " +
            "    return 1 " +
            "else " +
            "    return 0 " +
            "end";

    /**
     * Lua脚本：回滚库存
     */
    private static final String ROLLBACK_INVENTORY_SCRIPT =
            "local key = KEYS[1] " +
            "local exists = redis.call('exists', key) " +
            "if exists == 1 then " +
            "    redis.call('incrby', key, ARGV[1]) " +
            "    return 1 " +
            "else " +
            "    return 0 " +
            "end";

    @Override
    public boolean initInventoryToRedis(Integer productId, Integer quantity) {
        String key = RedisKeyConstants.getInventoryCacheKey(productId);
        try {
            redisTemplate.opsForValue().set(key, quantity, 24, TimeUnit.HOURS);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public int batchInitInventoryToRedis(Map<Integer, Integer> inventoryMap) {
        int successCount = 0;
        for (Map.Entry<Integer, Integer> entry : inventoryMap.entrySet()) {
            if (initInventoryToRedis(entry.getKey(), entry.getValue())) {
                successCount++;
            }
        }
        return successCount;
    }

    @Override
    public boolean deductInventory(Integer productId, Integer quantity) {
        String key = RedisKeyConstants.getInventoryCacheKey(productId);

        DefaultRedisScript<Long> script = new DefaultRedisScript<>();
        script.setScriptText(DEDUCT_INVENTORY_SCRIPT);
        script.setResultType(Long.class);

        Long result = redisTemplate.execute(
                script,
                Collections.singletonList(key),
                String.valueOf(quantity)
        );

        if (result == null) {
            return false;
        }

        if (result == -1L) {
            syncInventoryFromDb(productId);
            result = redisTemplate.execute(
                    script,
                    Collections.singletonList(key),
                    String.valueOf(quantity)
            );
        }

        return result != null && result == 1L;
    }

    @Override
    public boolean rollbackInventory(Integer productId, Integer quantity) {
        String key = RedisKeyConstants.getInventoryCacheKey(productId);

        DefaultRedisScript<Long> script = new DefaultRedisScript<>();
        script.setScriptText(ROLLBACK_INVENTORY_SCRIPT);
        script.setResultType(Long.class);

        Long result = redisTemplate.execute(
                script,
                Collections.singletonList(key),
                String.valueOf(quantity)
        );

        return result != null && result == 1L;
    }

    @Override
    public Integer getInventoryFromRedis(Integer productId) {
        String key = RedisKeyConstants.getInventoryCacheKey(productId);
        Object value = redisTemplate.opsForValue().get(key);
        if (value == null) {
            return null;
        }
        return Integer.valueOf(value.toString());
    }

    @Override
    public boolean syncInventoryFromDb(Integer productId) {
        String lockKey = RedisKeyConstants.getInventoryLockKey(productId);
        RLock lock = redissonClient.getLock(lockKey);

        try {
            boolean locked = lock.tryLock(3, 10, TimeUnit.SECONDS);
            if (!locked) {
                return false;
            }

            ShangpinEntity shangpin = shangpinService.selectById(productId);
            if (shangpin == null) {
                return false;
            }

            String cacheKey = RedisKeyConstants.getInventoryCacheKey(productId);
            redisTemplate.opsForValue().set(
                    cacheKey,
                    shangpin.getShangpinKucunNumber(),
                    24,
                    TimeUnit.HOURS
            );

            return true;

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        } finally {
            if (lock.isHeldByCurrentThread()) {
                lock.unlock();
            }
        }
    }
}
```

#### 2.3 创建库存同步接口

**File**: `server/src/main/java/com/controller/InventoryController.java` (新建)

```java
package com.controller;

import com.baomidou.mybatisplus.mapper.EntityWrapper;
import com.entity.ShangpinEntity;
import com.service.InventoryService;
import com.service.ShangpinService;
import com.utils.R;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/inventory")
public class InventoryController {

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private ShangpinService shangpinService;

    @RequestMapping("/sync/{productId}")
    public R syncInventory(@PathVariable Integer productId) {
        boolean success = inventoryService.syncInventoryFromDb(productId);
        return success ? R.ok() : R.error("同步失败");
    }

    @RequestMapping("/syncAll")
    public R syncAllInventory() {
        List<ShangpinEntity> list = shangpinService.selectList(
                new EntityWrapper<ShangpinEntity>().eq("shangxia_types", 1)
        );

        Map<Integer, Integer> inventoryMap = new HashMap<>();
        for (ShangpinEntity shangpin : list) {
            inventoryMap.put(shangpin.getId(), shangpin.getShangpinKucunNumber());
        }

        int count = inventoryService.batchInitInventoryToRedis(inventoryMap);
        return R.ok().put("count", count);
    }

    @RequestMapping("/get/{productId}")
    public R getInventory(@PathVariable Integer productId) {
        Integer quantity = inventoryService.getInventoryFromRedis(productId);
        return R.ok().put("quantity", quantity);
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 编译成功: `cd server && mvn clean compile`
- [ ] 单元测试通过: 测试库存预扣减和回滚逻辑

#### Manual Verification:
- [ ] 启动项目，调用 `/inventory/syncAll` 同步库存
- [ ] 调用 `/inventory/get/{productId}` 验证Redis中库存正确
- [ ] 模拟并发扣减，验证Lua脚本的原子性

**Implementation Note**: 完成此阶段后，Redis库存预扣减功能已实现，可以进行压力测试。

---

## Phase 3: RabbitMQ消息队列集成

### Overview
配置RabbitMQ连接、交换机、队列和死信队列，为异步下单提供消息基础设施。

### Changes Required:

#### 3.1 创建RabbitMQ配置类

**File**: `server/src/main/java/com/config/RabbitMQConfig.java` (新建)

```java
package com.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String ORDER_EXCHANGE = "order.exchange";
    public static final String ORDER_QUEUE = "order.queue";
    public static final String ORDER_ROUTING_KEY = "order.create";

    public static final String DLX_EXCHANGE = "order.dlx.exchange";
    public static final String DLX_QUEUE = "order.dlx.queue";
    public static final String DLX_ROUTING_KEY = "order.dlx";

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(messageConverter());
        return template;
    }

    @Bean
    public Queue orderQueue() {
        return QueueBuilder.durable(ORDER_QUEUE)
                .withArgument("x-max-length", 10000)
                .withArgument("x-dead-letter-exchange", DLX_EXCHANGE)
                .withArgument("x-dead-letter-routing-key", DLX_ROUTING_KEY)
                .build();
    }

    @Bean
    public DirectExchange orderExchange() {
        return new DirectExchange(ORDER_EXCHANGE, true, false);
    }

    @Bean
    public Binding orderBinding(@Qualifier("orderQueue") Queue queue,
                               @Qualifier("orderExchange") DirectExchange exchange) {
        return BindingBuilder.bind(queue).to(exchange).with(ORDER_ROUTING_KEY);
    }

    @Bean
    public Queue dlxQueue() {
        return QueueBuilder.durable(DLX_QUEUE).build();
    }

    @Bean
    public DirectExchange dlxExchange() {
        return new DirectExchange(DLX_EXCHANGE, true, false);
    }

    @Bean
    public Binding dlxBinding(@Qualifier("dlxQueue") Queue queue,
                             @Qualifier("dlxExchange") DirectExchange exchange) {
        return BindingBuilder.bind(queue).to(exchange).with(DLX_ROUTING_KEY);
    }
}
```

#### 3.2 创建订单消息实体类

**File**: `server/src/main/java/com/entity/OrderMessage.java` (新建)

```java
package com.entity;

import java.io.Serializable;
import java.util.Date;

public class OrderMessage implements Serializable {

    private static final long serialVersionUID = 1L;

    private String orderUuid;
    private Integer yonghuId;
    private Integer addressId;
    private Integer shangpinId;
    private String shangpinName;
    private Integer buyNumber;
    private Double shangpinNewMoney;
    private Double shangpinOrderTruePrice;
    private Integer shangpinOrderPaymentTypes;
    private Date createTime;
    private Integer shangjiaId;
    private Integer retryCount = 0;

    // Getters and Setters
    public String getOrderUuid() { return orderUuid; }
    public void setOrderUuid(String orderUuid) { this.orderUuid = orderUuid; }

    public Integer getYonghuId() { return yonghuId; }
    public void setYonghuId(Integer yonghuId) { this.yonghuId = yonghuId; }

    public Integer getAddressId() { return addressId; }
    public void setAddressId(Integer addressId) { this.addressId = addressId; }

    public Integer getShangpinId() { return shangpinId; }
    public void setShangpinId(Integer shangpinId) { this.shangpinId = shangpinId; }

    public String getShangpinName() { return shangpinName; }
    public void setShangpinName(String shangpinName) { this.shangpinName = shangpinName; }

    public Integer getBuyNumber() { return buyNumber; }
    public void setBuyNumber(Integer buyNumber) { this.buyNumber = buyNumber; }

    public Double getShangpinNewMoney() { return shangpinNewMoney; }
    public void setShangpinNewMoney(Double shangpinNewMoney) { this.shangpinNewMoney = shangpinNewMoney; }

    public Double getShangpinOrderTruePrice() { return shangpinOrderTruePrice; }
    public void setShangpinOrderTruePrice(Double shangpinOrderTruePrice) { this.shangpinOrderTruePrice = shangpinOrderTruePrice; }

    public Integer getShangpinOrderPaymentTypes() { return shangpinOrderPaymentTypes; }
    public void setShangpinOrderPaymentTypes(Integer shangpinOrderPaymentTypes) { this.shangpinOrderPaymentTypes = shangpinOrderPaymentTypes; }

    public Date getCreateTime() { return createTime; }
    public void setCreateTime(Date createTime) { this.createTime = createTime; }

    public Integer getShangjiaId() { return shangjiaId; }
    public void setShangjiaId(Integer shangjiaId) { this.shangjiaId = shangjiaId; }

    public Integer getRetryCount() { return retryCount; }
    public void setRetryCount(Integer retryCount) { this.retryCount = retryCount; }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 编译成功: `cd server && mvn clean compile`
- [ ] RabbitMQ连接测试: 启动项目检查RabbitMQ连接日志

#### Manual Verification:
- [ ] 安装并启动RabbitMQ服务
- [ ] 访问RabbitMQ管理界面 (http://localhost:15672)
- [ ] 检查队列和交换机是否创建成功

**Implementation Note**: 完成此阶段后，RabbitMQ基础设施已搭建完成，可以发送和接收消息。

---

## Phase 4: 订单消费者实现

### Overview
实现消息队列的消费者，后台异步处理订单，使用分布式锁保证并发安全。

### Changes Required:

#### 4.1 创建订单消费者

**File**: `server/src/main/java/com/consumer/OrderConsumer.java` (新建)

```java
package com.consumer;

import com.config.RabbitMQConfig;
import com.entity.OrderMessage;
import com.entity.ShangpinEntity;
import com.entity.ShangpinOrderEntity;
import com.entity.YonghuEntity;
import com.service.InventoryService;
import com.service.ShangpinOrderService;
import com.service.ShangpinService;
import com.service.YonghuService;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.support.AmqpHeaders;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Component;
import com.rabbitmq.client.Channel;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.Date;
import java.util.concurrent.TimeUnit;

@Component
public class OrderConsumer {

    private static final Logger logger = LoggerFactory.getLogger(OrderConsumer.class);
    private static final int MAX_RETRY = 3;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private ShangpinService shangpinService;

    @Autowired
    private ShangpinOrderService shangpinOrderService;

    @Autowired
    private YonghuService yonghuService;

    @Autowired
    private RedissonClient redissonClient;

    @RabbitListener(queues = RabbitMQConfig.ORDER_QUEUE)
    public void processOrder(OrderMessage message,
                            Channel channel,
                            @Header(AmqpHeaders.DELIVERY_TAG) long deliveryTag) {
        try {
            logger.info("开始处理订单: {}", message.getOrderUuid());

            String lockKey = "order:process:" + message.getShangpinId();
            RLock lock = redissonClient.getLock(lockKey);

            boolean locked = false;
            try {
                locked = lock.tryLock(10, 30, TimeUnit.SECONDS);

                if (!locked) {
                    logger.warn("获取锁失败，订单稍后重试: {}", message.getOrderUuid());
                    channel.basicNack(deliveryTag, false, true);
                    return;
                }

                boolean success = processOrderInternal(message);

                if (success) {
                    channel.basicAck(deliveryTag, false);
                    logger.info("订单处理成功: {}", message.getOrderUuid());
                } else {
                    if (message.getRetryCount() >= MAX_RETRY) {
                        channel.basicNack(deliveryTag, false, false);
                        logger.error("订单处理失败，超过最大重试次数: {}", message.getOrderUuid());
                    } else {
                        message.setRetryCount(message.getRetryCount() + 1);
                        channel.basicNack(deliveryTag, false, true);
                        logger.warn("订单处理失败，稍后重试: {}, 重试次数: {}",
                                message.getOrderUuid(), message.getRetryCount());
                    }
                }

            } finally {
                if (locked && lock.isHeldByCurrentThread()) {
                    lock.unlock();
                }
            }

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.error("订单处理被中断: {}", message.getOrderUuid());
            try {
                channel.basicNack(deliveryTag, false, false);
            } catch (IOException ex) {
                logger.error("消息确认失败", ex);
            }
        } catch (Exception e) {
            logger.error("订单处理异常: {}", message.getOrderUuid(), e);
            try {
                inventoryService.rollbackInventory(message.getShangpinId(), message.getBuyNumber());
                channel.basicNack(deliveryTag, false, false);
            } catch (IOException ex) {
                logger.error("回滚库存失败", ex);
            }
        }
    }

    private boolean processOrderInternal(OrderMessage message) {
        try {
            // 1. 查询商品
            ShangpinEntity shangpin = shangpinService.selectById(message.getShangpinId());
            if (shangpin == null) {
                logger.error("商品不存在: {}", message.getShangpinId());
                return false;
            }

            // 2. 验证数据库库存
            if (shangpin.getShangpinKucunNumber() < message.getBuyNumber()) {
                logger.warn("数据库库存不足: 商品ID={}, 需要数量={}, 当前库存={}",
                        message.getShangpinId(), message.getBuyNumber(), shangpin.getShangpinKucunNumber());
                inventoryService.rollbackInventory(message.getShangpinId(), message.getBuyNumber());
                return false;
            }

            // 3. 扣减数据库库存
            shangpin.setShangpinKucunNumber(shangpin.getShangpinKucunNumber() - message.getBuyNumber());
            boolean updateSuccess = shangpinService.updateById(shangpin);

            if (!updateSuccess) {
                logger.error("更新库存失败: {}", message.getShangpinId());
                inventoryService.rollbackInventory(message.getShangpinId(), message.getBuyNumber());
                return false;
            }

            // 4. 增加商家余额
            YonghuEntity yonghu = yonghuService.selectById(message.getYonghuId());
            yonghu.setNewMoney(yonghu.getNewMoney() - message.getShangpinOrderTruePrice());
            yonghuService.updateById(yonghu);

            // 5. 创建订单记录
            ShangpinOrderEntity order = new ShangpinOrderEntity();
            order.setShangpinOrderUuidNumber(message.getOrderUuid());
            order.setAddressId(message.getAddressId());
            order.setShangpinId(message.getShangpinId());
            order.setYonghuId(message.getYonghuId());
            order.setBuyNumber(message.getBuyNumber());
            order.setShangpinOrderTypes(101);
            order.setShangpinOrderPaymentTypes(message.getShangpinOrderPaymentTypes());
            order.setShangpinOrderTruePrice(message.getShangpinOrderTruePrice());
            order.setInsertTime(new Date());
            order.setCreateTime(new Date());

            boolean insertSuccess = shangpinOrderService.insert(order);

            if (!insertSuccess) {
                logger.error("创建订单失败: {}", message.getOrderUuid());
                // 回滚库存和余额
                shangpin.setShangpinKucunNumber(shangpin.getShangpinKucunNumber() + message.getBuyNumber());
                shangpinService.updateById(shangpin);
                yonghu.setNewMoney(yonghu.getNewMoney() + message.getShangpinOrderTruePrice());
                yonghuService.updateById(yonghu);
                inventoryService.rollbackInventory(message.getShangpinId(), message.getBuyNumber());
                return false;
            }

            logger.info("订单创建成功: {}", message.getOrderUuid());
            return true;

        } catch (Exception e) {
            logger.error("处理订单内部异常: {}", message.getOrderUuid(), e);
            inventoryService.rollbackInventory(message.getShangpinId(), message.getBuyNumber());
            return false;
        }
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 编译成功: `cd server && mvn clean compile`
- [ ] 消息监听器启动成功

#### Manual Verification:
- [ ] 发送测试消息到队列
- [ ] 观察消费者日志输出
- [ ] 验证订单创建成功
- [ ] 验证库存扣减正确

**Implementation Note**: 完成此阶段后，订单异步处理功能已实现。

---

## Phase 5: 异常处理和回滚机制

### Overview
实现订单失败时的回滚机制，包括Redis库存回滚、死信队列处理等。

### Changes Required:

#### 5.1 创建死信队列消费者

**File**: `server/src/main/java/com/consumer/DeadLetterQueueConsumer.java` (新建)

```java
package com.consumer;

import com.config.RabbitMQConfig;
import com.entity.OrderMessage;
import com.service.InventoryService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.support.AmqpHeaders;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Component;
import com.rabbitmq.client.Channel;

import java.io.IOException;

@Component
public class DeadLetterQueueConsumer {

    private static final Logger logger = LoggerFactory.getLogger(DeadLetterQueueConsumer.class);

    @Autowired
    private InventoryService inventoryService;

    @RabbitListener(queues = RabbitMQConfig.DLX_QUEUE)
    public void processFailedOrder(OrderMessage message,
                                   Channel channel,
                                   @Header(AmqpHeaders.DELIVERY_TAG) long deliveryTag) {
        try {
            logger.error("处理失败的订单: {}, 重试次数: {}",
                    message.getOrderUuid(), message.getRetryCount());

            // 回滚Redis库存
            boolean rollbackSuccess = inventoryService.rollbackInventory(
                    message.getShangpinId(),
                    message.getBuyNumber()
            );

            if (rollbackSuccess) {
                logger.info("库存回滚成功: 商品ID={}, 数量={}",
                        message.getShangpinId(), message.getBuyNumber());
            } else {
                logger.warn("库存回滚失败: 商品ID={}, 数量={}",
                        message.getShangpinId(), message.getBuyNumber());
            }

            channel.basicAck(deliveryTag, false);

        } catch (Exception e) {
            logger.error("处理死信队列消息异常", e);
            try {
                channel.basicNack(deliveryTag, false, false);
            } catch (IOException ex) {
                logger.error("消息确认失败", ex);
            }
        }
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 编译成功: `cd server && mvn clean compile`

#### Manual Verification:
- [ ] 模拟订单失败场景
- [ ] 验证Redis库存回滚成功
- [ ] 验证死信队列消息处理

**Implementation Note**: 完成此阶段后，异常处理和回滚机制已实现。

---

## Phase 6: 前端适配和测试

### Overview
修改前端下单流程，适配新的异步下单模式，并添加异步下单接口。

### Changes Required:

#### 6.1 添加异步下单接口

**File**: `server/src/main/java/com/controller/ShangpinOrderController.java` (修改)

在类中添加新的依赖注入和方法：

```java
@Autowired
private InventoryService inventoryService;

@Autowired
private RabbitTemplate rabbitTemplate;

/**
 * 异步下单接口（高并发场景）
 */
@RequestMapping("/asyncOrder")
public R asyncOrder(@RequestParam Map<String, Object> params, HttpServletRequest request) {
    try {
        String orderUuid = String.valueOf(new Date().getTime());
        Integer userId = (Integer) request.getSession().getAttribute("userId");

        Integer addressId = Integer.valueOf(String.valueOf(params.get("addressId")));
        Integer shangpinOrderPaymentTypes = Integer.valueOf(String.valueOf(params.get("shangpinOrderPaymentTypes")));
        String data = String.valueOf(params.get("shangpins"));

        JSONArray jsonArray = JSON.parseArray(data);
        List<Map> shangpins = JSON.parseObject(jsonArray.toString(), List.class);

        for (Map<String, Object> map : shangpins) {
            Integer shangpinId = Integer.valueOf(String.valueOf(map.get("shangpinId")));
            Integer buyNumber = Integer.valueOf(String.valueOf(map.get("buyNumber")));

            // 1. Redis预扣减库存
            boolean deductSuccess = inventoryService.deductInventory(shangpinId, buyNumber);
            if (!deductSuccess) {
                return R.error("库存不足");
            }

            // 2. 查询商品信息
            ShangpinEntity shangpin = shangpinService.selectById(shangpinId);

            // 3. 计算金额
            Double money = new BigDecimal(shangpin.getShangpinNewMoney())
                    .multiply(new BigDecimal(buyNumber))
                    .doubleValue();

            // 4. 扣减用户余额
            YonghuEntity yonghu = yonghuService.selectById(userId);
            if (yonghu.getNewMoney() < money) {
                inventoryService.rollbackInventory(shangpinId, buyNumber);
                return R.error("余额不足,请充值！！！");
            }

            yonghu.setNewMoney(yonghu.getNewMoney() - money);
            yonghuService.updateById(yonghu);

            // 5. 构建订单消息
            OrderMessage message = new OrderMessage();
            message.setOrderUuid(orderUuid);
            message.setYonghuId(userId);
            message.setAddressId(addressId);
            message.setShangpinId(shangpinId);
            message.setShangpinName(shangpin.getShangpinName());
            message.setBuyNumber(buyNumber);
            message.setShangpinNewMoney(shangpin.getShangpinNewMoney());
            message.setShangpinOrderTruePrice(money);
            message.setShangpinOrderPaymentTypes(shangpinOrderPaymentTypes);
            message.setCreateTime(new Date());
            message.setShangjiaId(shangpin.getShangjiaId());

            // 6. 发送消息到队列
            rabbitTemplate.convertAndSend(
                    RabbitMQConfig.ORDER_EXCHANGE,
                    RabbitMQConfig.ORDER_ROUTING_KEY,
                    message
            );
        }

        return R.ok().put("orderUuid", orderUuid);

    } catch (Exception e) {
        logger.error("异步下单失败", e);
        return R.error("下单失败，请重试");
    }
}
```

#### 6.2 修改前端订单确认页

**File**: `uni-mall/pages/shangpinOrder/confirm.vue` (修改)

修改提交方法：

```javascript
async onSubmitTap() {
    // ... 原有验证逻辑 ...

    uni.showLoading({
        title: '正在提交订单...',
        mask: true
    });

    try {
        let data = {
            addressId: this.addresszhi.id,
            shangpins: JSON.stringify(this.orderGoods),
            yonghuId: this.user.id,
            shangpinOrderPaymentTypes: this.shangpinOrderPaymentTypes
        }

        // 调用新的异步下单接口
        await this.$api.requestConditionDataGet('shangpinOrder', 'asyncOrder', null, data);

        uni.hideLoading();

        // 显示成功提示
        uni.showModal({
            title: '下单成功',
            content: '订单正在处理中，请稍后在订单列表中查看',
            showCancel: false,
            success: () => {
                this.$utils.jump('../shangpinOrder/list');
            }
        });

    } catch (error) {
        uni.hideLoading();
        this.$utils.msg(error.message || '下单失败，请重试');
    }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 编译成功: `cd server && mvn clean package`
- [ ] 前端编译成功: `cd uni-mall && npm run build`

#### Manual Verification:
- [ ] 安装并启动Redis服务
- [ ] 安装并启动RabbitMQ服务
- [ ] 同步库存到Redis: 调用 `/inventory/syncAll`
- [ ] 完整下单流程测试
- [ ] 模拟并发下单测试

**Implementation Note**: 完成此阶段后，整个高并发库存控制方案已实施完毕。

---

## Testing Strategy

### 压力测试方案

**使用JMeter进行并发测试**:

```
测试场景：
- 商品库存：100件
- 并发用户：1000个
- 每个用户购买1件

预期结果：
- 成功订单：100个
- 失败请求：900个（库存不足）
- 最终库存：0件
- 无超卖现象
```

### 手动测试步骤

1. **环境准备**
   - 启动MySQL数据库
   - 启动Redis服务
   - 启动RabbitMQ服务
   - 启动后端服务
   - 启动前端服务

2. **库存同步**
   - 调用 `GET /inventory/syncAll` 同步所有商品库存到Redis

3. **正常下单测试**
   - 浏览商品详情页
   - 点击"立即购买"
   - 选择收货地址
   - 确认支付
   - 验证订单创建成功
   - 验证库存扣减正确

4. **并发下单测试**
   - 使用JMeter模拟100个并发用户
   - 同时下单同一商品（库存10件）
   - 验证只有10个订单成功
   - 验证库存变为0

## Performance Considerations

### 性能指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 单机QPS | > 10000 | Redis预扣减能力 |
| 响应时间 | < 100ms | 下单接口响应时间 |
| 消息处理速度 | > 5000/s | 消费者处理速度 |
| 库存回滚时间 | < 10ms | Redis操作时间 |

## Migration Notes

### 环境依赖

**Redis安装（Windows）**:
```bash
# 下载Redis for Windows
# https://github.com/tporadowski/redis/releases
# 启动: redis-server.exe
```

**RabbitMQ安装（Windows）**:
```bash
# 安装Erlang后下载RabbitMQ
# https://www.rabbitmq.com/download.html
# 启动: rabbitmq-server.bat
```

### 平滑过渡方案

**灰度发布**：
1. 阶段1：部署新代码，保留旧接口
2. 阶段2：少量流量切换到新接口
3. 阶段3：逐步扩大新接口流量
4. 阶段4：全量切换
5. 阶段5：下线旧接口

## References

- 相关研究: `thoughts/shared/research/2026-03-25-shopping-order-creation-flow.md`
- 原订单接口: `server/src/main/java/com/controller/ShangpinOrderController.java:431-528`
- Redis文档: https://redis.io/docs/
- RabbitMQ文档: https://www.rabbitmq.com/docs/
- Redisson文档: https://redisson.org
