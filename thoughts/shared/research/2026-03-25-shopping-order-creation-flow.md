---
date: 2026-03-25T14:30:00+08:00
researcher: Claude Code
git_commit: 179c3d28444f214c1e758af52c5dfc3837795c03
branch: master
repository: https://github.com/hozin25/ShoppingApp.git
topic: "用户购物商品下单后的一系列流程实现，如查询库存，提交订单，成功或者失败创建订单等操作"
tags: [research, codebase, order-creation, inventory, payment]
status: complete
last_updated: 2026-03-25
last_updated_by: Claude Code
---

# Research: 购物下单完整流程实现分析

**Date**: 2026-03-25 14:30:00
**Researcher**: Claude Code
**Git Commit**: 179c3d28444f214c1e758af52c5dfc3837795c03
**Branch**: master
**Repository**: https://github.com/hozin25/ShoppingApp.git

## Research Question

用户购物商品下单后的一系列流程是如何实现的？包括：查询库存、提交订单、成功或失败创建订单等操作。

## Summary

本购物应用的下单流程采用前后端分离架构，完整的订单创建流程涉及前端数据收集（订单确认页）、后端业务处理（Spring Boot Controller）、数据库事务操作（MyBatis-Plus）等多个环节。核心流程包括：**库存查询与验证** → **订单数据收集** → **余额验证与扣减** → **订单创建** → **库存扣减** → **商家入账** → **购物车清空**。

系统使用 `@Transactional` 注解保证事务原子性，当任何操作失败时所有数据库操作会回滚。失败场景包括库存不足、余额不足、地址未选择等，错误信息通过标准化的 `R` 响应对象返回给前端，由HTTP拦截器统一展示为Toast提示。

## Detailed Findings

---

### 一、库存查询机制

#### 1.1 库存字段定义

**实体类定义** ([`server/src/main/java/com/entity/ShangpinEntity.java:102-107`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinEntity.java#L102-L107))

```java
/**
 * 商品库存
 */
@ColumnInfo(comment="商品库存",type="int(11)")
@TableField(value = "shangpin_kucun_number")
private Integer shangpinKucunNumber;
```

**数据库字段** ([`db_mall.sql:270`](https://github.com/hozin25/ShoppingApp/blob/master/db_mall.sql#L270))

```sql
`shangpin_kucun_number` int(11) DEFAULT NULL COMMENT '商品库存',
```

#### 1.2 前端库存展示

**商品详情页展示** ([`uni-mall/pages/shangpin/detail.vue:80-88`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/detail.vue#L80-L88))

```vue
<view class="xiangqing">
    <view class="shangpinxiangqing">
        <view class="box">商品库存：</view>
        <view class="app">{{detail.shangpinKucunNumber}}</view>
    </view>
</view>
```

库存数据来源于后端 `/shangpin/detail/{id}` 接口返回的商品详情。

---

### 二、订单创建前端流程

#### 2.1 数据收集入口

**订单确认页** ([`uni-mall/pages/shangpinOrder/confirm.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue))

**页面加载数据准备** (第76-84行)

```javascript
// 从本地存储读取商品列表
this.orderGoods = uni.getStorageSync('orderGoods');

// 计算订单总价
for (let i = 0; i < this.orderGoods.length; i++) {
    this.maxNewMouey = this.maxNewMouey +
        parseFloat(this.orderGoods[i].shangpinNewMoney) * this.orderGoods[i].buyNumber
}

// 清除本地存储
uni.removeStorageSync("orderGoods");
```

**商品列表来源：**
- 从商品详情页"立即购买"：单个商品构建为列表
- 从购物车页"立即下单"：多个选中商品

**获取用户信息** (第89-91行)

```javascript
// 获取当前登录用户
this.user = uni.getStorageSync('appUser');
```

**获取会员折扣** (第94-102行)

```javascript
// 查询会员等级字典获取折扣率
this.$api.page('dictionary', {
    page: 1,
    limit: 100,
    dicCode: 'huiyuandengji_types'
}).then(res => {
    // 从用户会员等级找到对应的折扣率（beizhu字段）
    // zhekou = 折扣率，如0.9表示9折
});
```

**获取收货地址** (第105-120行)

```javascript
// 优先使用从地址选择页面传来的地址
if (uni.getStorageSync('address')) {
    this.addresszhi = uni.getStorageSync('address');
} else {
    // 否则查询用户的默认地址（isdefaultTypes: 2）
    this.$api.page('address', {
        page: 1,
        limit: 100,
        yonghuId: this.user.id,
        isdefaultTypes: 2
    }).then(res => {
        if (res.data.list.length > 0) {
            this.addresszhi = res.data.list[0];
        }
    });
}
```

#### 2.2 订单提交

**提交方法** ([`confirm.vue:124-151`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue#L124-L151))

```javascript
async onSubmitTap() {
    // 1. 验证收货地址
    if(this.addresszhi == null){
        return this.$utils.msg('请选择收货地址');
    }

    // 2. 显示确认对话框
    uni.showModal({
        title: '提示',
        content: '是否确认支付',
        success: async (res) => {
            if (res.confirm) {
                // 3. 构建订单数据
                let data = {
                    addressId: this.addresszhi.id,
                    shangpins: JSON.stringify(this.orderGoods),
                    yonghuId: this.user.id,
                    shangpinOrderPaymentTypes: this.shangpinOrderPaymentTypes
                }

                // 4. 调用后端API
                await this.$api.requestConditionDataGet('shangpinOrder', 'order', null, data);

                // 5. 跳转到订单列表
                this.$utils.jump('../shangpinOrder/list');
            }
        }
    });
}
```

---

### 三、后端订单创建流程

#### 3.1 接口入口

**订单创建接口** ([`server/src/main/java/com/controller/ShangpinOrderController.java:431-528`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java#L431-L528))

```java
@RequestMapping("/order")
public R order(@RequestParam Map<String, Object> params, HttpServletRequest request) {
    // ... 订单创建逻辑
}
```

#### 3.2 订单号生成

**生成规则** (第434行)

```java
String shangpinOrderUuidNumber = String.valueOf(new Date().getTime());
```

- 使用当前时间戳的毫秒数作为订单号
- 同一订单的多个商品共享同一订单号

#### 3.3 参数解析

**请求参数解析** (第437-444行)

```java
// 获取当前登录用户ID
Integer userId = (Integer) request.getSession().getAttribute("userId");

// 解析请求参数
Integer addressId = Integer.valueOf(String.valueOf(params.get("addressId")));
Integer shangpinOrderPaymentTypes = Integer.valueOf(String.valueOf(params.get("shangpinOrderPaymentTypes")));
String data = String.valueOf(params.get("shangpins"));

// 解析商品列表JSON
JSONArray jsonArray = JSON.parseArray(data);
List<Map> shangpins = JSON.parseObject(jsonArray.toString(), List.class);
```

**参数结构：**
| 参数 | 类型 | 说明 |
|------|------|------|
| `addressId` | Integer | 收货地址ID |
| `shangpins` | JSON String | 商品列表，包含商品ID、名称、价格、数量等 |
| `yonghuId` | Integer | 用户ID |
| `shangpinOrderPaymentTypes` | Integer | 支付类型（1=余额，2=积分） |

#### 3.4 数据准备

**初始化处理容器** (第446-458行)

```java
// 获取用户实体（用于余额验证和扣减）
YonghuEntity yonghuEntity = yonghuService.selectById(userId);

// 创建批量处理的列表
List<ShangpinOrderEntity> shangpinOrderList = new ArrayList<>();
ArrayList<ShangjiaEntity> shangjiaList = new ArrayList<>();
List<ShangpinEntity> shangpinList = new ArrayList<>();
List<Integer> cartIds = new ArrayList<>();

// 初始化折扣率（固定为1.0，即无折扣）
BigDecimal zhekou = new BigDecimal(1.0);
```

#### 3.5 循环处理每个商品

**核心处理逻辑** (第461-518行)

```java
for (int i = 0; i < shangpins.size(); i++) {
    Map<String, Object> map = shangpins.get(i);
    Integer shangpinId = Integer.valueOf(String.valueOf(map.get("shangpinId")));
    Integer buyNumber = Integer.valueOf(String.valueOf(map.get("buyNumber")));

    // 1. 查询商品实体
    ShangpinEntity shangpinEntity = shangpinService.selectById(shangpinId);

    // 2. 收集购物车ID（用于后续删除）
    if (map.get("cartId") != null) {
        cartIds.add(Integer.valueOf(String.valueOf(map.get("cartId"))));
    }

    // 3. 查询商家信息
    Integer shangjiaId = shangpinEntity.getShangjiaId();
    ShangjiaEntity shangjiaEntity = shangjiaService.selectById(shangjiaId);

    // ===== 库存验证与扣减 =====
    if (shangpinEntity.getShangpinKucunNumber() < buyNumber) {
        return R.error(shangpinEntity.getShangpinName() + "的库存不足");
    }
    // 内存中扣减库存
    shangpinEntity.setShangpinKucunNumber(shangpinEntity.getShangpinKucunNumber() - buyNumber);

    // ===== 创建订单实体 =====
    ShangpinOrderEntity shangpinOrderEntity = new ShangpinOrderEntity();
    shangpinOrderEntity.setShangpinOrderUuidNumber(shangpinOrderUuidNumber);
    shangpinOrderEntity.setAddressId(addressId);
    shangpinOrderEntity.setShangpinId(shangpinId);
    shangpinOrderEntity.setYonghuId(userId);
    shangpinOrderEntity.setBuyNumber(buyNumber);
    shangpinOrderEntity.setShangpinOrderTypes(101);  // 已支付
    shangpinOrderEntity.setShangpinOrderPaymentTypes(shangpinOrderPaymentTypes);
    shangpinOrderEntity.setInsertTime(new Date());
    shangpinOrderEntity.setCreateTime(new Date());

    // ===== 支付处理（余额支付） =====
    if (shangpinOrderPaymentTypes == 1) {
        // 计算订单金额
        Double money = new BigDecimal(shangpinEntity.getShangpinNewMoney())
            .multiply(new BigDecimal(buyNumber))
            .multiply(zhekou)
            .doubleValue();

        // 验证用户余额
        if (yonghuEntity.getNewMoney() - money < 0) {
            return R.error("余额不足,请充值！！！");
        }

        // 扣减用户余额
        yonghuEntity.setNewMoney(yonghuEntity.getNewMoney() - money);

        // 设置订单实付价格
        shangpinOrderEntity.setShangpinOrderTruePrice(money);

        // 增加商家余额
        shangjiaEntity.setNewMoney(shangjiaEntity.getNewMoney() + money);
    }

    // 添加到批量处理列表
    shangpinOrderList.add(shangpinOrderEntity);
    shangjiaList.add(shangjiaEntity);
    shangpinList.add(shangpinEntity);
}
```

#### 3.6 批量保存操作

**数据库操作** (第520-525行)

```java
// 1. 批量插入订单
shangpinOrderService.insertBatch(shangpinOrderList);

// 2. 批量更新商家余额
shangjiaService.updateBatchById(shangjiaList);

// 3. 批量更新商品库存（执行实际的库存扣减）
shangpinService.updateBatchById(shangpinList);

// 4. 更新用户余额
yonghuService.updateById(yonghuEntity);

// 5. 删除购物车中的商品
if (cartIds != null && cartIds.size() > 0) {
    cartService.deleteBatchIds(cartIds);
}

return R.ok();
```

**操作顺序说明：**
1. 先插入订单记录
2. 再更新商家余额
3. 然后更新商品库存
4. 最后更新用户余额和清空购物车

---

### 四、事务处理机制

#### 4.1 事务配置

**Service层事务** ([`server/src/main/java/com/service/impl/ShangpinOrderServiceImpl.java:30`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/service/impl/ShangpinOrderServiceImpl.java#L30))

```java
@Transactional
public class ShangpinOrderServiceImpl extends ServiceImpl<ShangpinOrderDao, ShangpinOrderEntity>
    implements ShangpinOrderService {
```

- 类级别的 `@Transactional` 注解
- 所有public方法都在事务中执行
- 包括 `insertBatch()` 和 `updateById()` 等方法

#### 4.2 事务回滚规则

**自动回滚场景：**
- 任何运行时异常（RuntimeException）触发回滚
- 数据库约束违反触发回滚
- SQL异常触发回滚

**不会触发事务的操作：**
- 验证失败时直接返回错误（如库存不足、余额不足）
- 此时方法提前返回，未执行任何数据库操作

**回滚范围：**
- 订单插入记录
- 商家余额更新
- 商品库存更新
- 用户余额更新
- 购物车删除

---

### 五、失败处理机制

#### 5.1 库存不足

**验证位置** ([`ShangpinOrderController.java:474-477`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java#L474-L477))

```java
if (shangpinEntity.getShangpinKucunNumber() < buyNumber) {
    return R.error(shangpinEntity.getShangpinName() + "的库存不足");
}
```

**处理流程：**
```
用户提交订单
    ↓
后端循环验证每个商品的库存
    ↓
发现库存不足
    ↓
返回 R.error("商品名的库存不足")
    ↓
HTTP拦截器检测到 code != 0
    ↓
显示Toast提示："XXX的库存不足"
    ↓
购物车记录保留，用户可修改后重试
```

#### 5.2 余额不足

**验证位置** (第501-503行)

```java
if (yonghuEntity.getNewMoney() - money < 0) {
    return R.error("余额不足,请充值！！！");
}
```

**处理流程：**
```
用户提交订单
    ↓
验证库存通过
    ↓
计算订单总金额
    ↓
验证用户余额
    ↓
余额不足
    ↓
返回 R.error("余额不足,请充值！！！")
    ↓
前端显示Toast提示
    ↓
购物车记录保留
```

#### 5.3 地址未选择

**前端验证** ([`confirm.vue:132-136`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue#L132-L136))

```javascript
if (this.addresszhi == null) {
    return this.$utils.msg('请选择收货地址');
}
```

- 前端拦截，不会发送请求到后端
- 显示Toast："请选择收货地址"

#### 5.4 HTTP错误拦截

**拦截器实现** ([`uni-mall/api/http.js:52-75`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/api/http.js#L52-L75))

```javascript
if (statusCode === 200) {
    var rs = response.data;
    if (rs.code === 0) {
        // 成功：返回数据
        resolve(response.data);
    } else if (rs.code == 401) {
        // 401：跳转登录页
        uni.navigateTo({ url: '../login/login' });
    } else {
        // 其他错误：显示错误消息
        uni.showToast({
            title: rs.msg,
            icon: 'none',
            duration: 2000
        });
    }
} else {
    // HTTP错误
    uni.showToast({
        title: "接口执行异常",
        icon: 'none',
        duration: 2000
    });
    reject(response);
}
```

**错误码说明：**
| 错误码 | 含义 | 处理方式 |
|--------|------|----------|
| 0 | 成功 | 返回数据 |
| 401 | 未登录/Token过期 | 跳转登录页 |
| 511 | 业务错误 | 显示错误消息 |
| 其他 | 系统错误 | 显示"接口执行异常" |

---

### 六、支付和余额流转

#### 6.1 支付类型

**字典表定义** ([`db_mall.sql:146`](https://github.com/hozin25/ShoppingApp/blob/master/db_mall.sql#L146))

| 值 | 名称 | 实现状态 |
|----|------|----------|
| 1 | 余额支付 | ✅ 已实现 |
| 2 | 积分支付 | ❌ 前端有选项，后端未实现 |

#### 6.2 实付价格计算

**计算公式** (第499行)

```java
Double money = new BigDecimal(shangpinEntity.getShangpinNewMoney())
    .multiply(new BigDecimal(buyNumber))
    .multiply(zhekou)
    .doubleValue();
```

**计算步骤：**
1. 获取商品现价：`shangpinNewMoney`
2. 乘以购买数量：`buyNumber`
3. 乘以折扣率：`zhekou`（当前固定为1.0）
4. 转换为Double类型

**示例：**
- 商品价格：99.00元
- 购买数量：2
- 折扣率：1.0（无折扣）
- 实付金额：99.00 × 2 × 1.0 = 198.00元

#### 6.3 余额流转

**用户余额扣减** (第506行)

```java
yonghuEntity.setNewMoney(yonghuEntity.getNewMoney() - money);
```

**商家余额增加** (第512行)

```java
shangjiaEntity.setNewMoney(shangjiaEntity.getNewMoney() + money);
```

**流转示意图：**

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   用户账户   │  金额   │   平台      │  金额   │   商家账户   │
│  yonghu表   │  ---->  │  (订单)     │  ---->  │  shangjia表  │
└─────────────┘         └─────────────┘         └─────────────┘
  余额 - money            订单实付价格            余额 + money
```

#### 6.4 余额更新时机

**数据库更新顺序：**
1. 批量插入订单（`insertBatch`）
2. 批量更新商家余额（`updateBatchById`）
3. 批量更新商品库存（`updateBatchById`）
4. 更新用户余额（`updateById`）

所有操作在同一事务中，保证原子性。

---

## Code References

### 核心前端文件

| 文件路径 | 功能描述 |
|----------|----------|
| [`uni-mall/pages/shangpinOrder/confirm.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue) | 订单确认页（数据收集、提交） |
| [`uni-mall/pages/shangpin/detail.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/detail.vue) | 商品详情页（立即购买） |
| [`uni-mall/pages/cart/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/cart/list.vue) | 购物车页（立即下单） |
| [`uni-mall/api/http.js`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/api/http.js) | HTTP拦截器（错误处理） |

### 核心后端文件

| 文件路径 | 功能描述 |
|----------|----------|
| [`server/src/main/java/com/controller/ShangpinOrderController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java) | 订单控制器（订单创建接口） |
| [`server/src/main/java/com/entity/ShangpinOrderEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinOrderEntity.java) | 订单实体类 |
| [`server/src/main/java/com/entity/ShangpinEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinEntity.java) | 商品实体类（库存字段） |
| [`server/src/main/java/com/entity/YonghuEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/YonghuEntity.java) | 用户实体类（余额字段） |
| [`server/src/main/java/com/service/impl/ShangpinOrderServiceImpl.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/service/impl/ShangpinOrderServiceImpl.java) | 订单服务（事务管理） |

### 关键方法位置

| 方法 | 位置 | 功能 |
|------|------|------|
| `onSubmitTap()` | `confirm.vue:124-151` | 前端订单提交 |
| `/order` | `ShangpinOrderController.java:431-528` | 后端订单创建 |
| 库存验证 | `ShangpinOrderController.java:474-477` | 检查库存是否充足 |
| 余额验证 | `ShangpinOrderController.java:501-503` | 检查余额是否充足 |
| 批量保存 | `ShangpinOrderController.java:520-525` | 批量数据库操作 |
| HTTP拦截 | `http.js:52-75` | 统一错误处理 |

---

## Architecture Documentation

### 数据流转图

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              下单完整流程数据流                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

前端                          后端API                    数据库
───────────────────────────────────────────────────────────────────────────────────
订单确认页
   ↓
收集数据:
   - 商品列表 (orderGoods)
   - 收货地址 (addresszhi)
   - 支付类型
   ↓
验证地址
   ↓
显示确认对话框
   ↓
构建请求数据
   ↓
POST /shangpinOrder/order
   ↓
                              接收请求
                                 ↓
                              生成订单号
                                 ↓
                              解析参数
                              ┌────────────────────────────────────┐
                              │     循环处理每个商品                  │
                              │                                     │
                              │  1. 查询商品实体                     │
                              │  2. 查询商家实体                     │
                              │  3. 验证库存: kucun >= buyNumber     │
                              │     失败 → 返回错误                   │
                              │  4. 扣减库存 (内存)                  │
                              │  5. 创建订单实体                     │
                              │  6. 计算金额 (price × num × zhekou)   │
                              │  7. 验证余额: balance >= money       │
                              │     失败 → 返回错误                   │
                              │  8. 扣减用户余额                     │
                              │  9. 增加商家余额                     │
                              │  10. 添加到批量列表                   │
                              └────────────────────────────────────┘
                                 ↓
                              批量数据库操作 (事务):
                              ┌────────────────────────────────────┐
                              │  1. insertBatch(订单列表)            │
                              │  2. updateBatchById(商家列表)        │
                              │  3. updateBatchById(商品列表)        │
                              │  4. updateById(用户)                │
                              │  5. deleteBatchIds(购物车)           │
                              └────────────────────────────────────┘
                                 ↓
                              返回 R.ok()
                                 ↓
跳转订单列表页
```

### 订单创建关键步骤

| 步骤 | 操作 | 涉及字段/表 | 说明 |
|------|------|-------------|------|
| 1 | 生成订单号 | `shangpin_order_uuid_number` | 时间戳 |
| 2 | 验证库存 | `shangpin_kucun_number` | 商品库存表 |
| 3 | 扣减库存 | `shangpin_kucun_number` | 商品库存表 |
| 4 | 验证余额 | `new_money` | 用户表 |
| 5 | 扣减余额 | `new_money` | 用户表 |
| 6 | 增加商家余额 | `new_money` | 商家表 |
| 7 | 创建订单 | `shangpin_order` | 订单表 |
| 8 | 清空购物车 | `cart` | 购物车表 |

### 错误处理流程

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              错误处理流程                                         │
└─────────────────────────────────────────────────────────────────────────────────┘

前端验证                          后端验证                    HTTP拦截器
───────────────────────────────────────────────────────────────────────────────────
地址是否选择?
   ↓ NO
显示"请选择收货地址"
   ↓ YES
发送请求
   ↓
                              库存是否充足?
                                 ↓ NO
                              返回 "XXX的库存不足"
                                 ↓
                              余额是否充足?
                                 ↓ NO
                              返回 "余额不足,请充值!!!"
                                 ↓
                              其他验证
                                 ↓
                              返回 R.ok()
   ↓
接收响应
   ↓
code == 401?
   ↓ YES
跳转登录页
   ↓ NO
code == 0?
   ↓ YES
继续操作
   ↓ NO
显示错误消息 Toast (rs.msg)
```

---

## 完整流程示例

### 成功场景

**用户操作：**
1. 在商品详情页点击"立即购买"或从购物车点击"立即下单"
2. 进入订单确认页，选择收货地址
3. 点击"确认支付"按钮
4. 系统验证通过，订单创建成功
5. 跳转到订单列表页

**系统处理：**
```
1. 前端收集商品数据和收货地址
2. 调用 POST /shangpinOrder/order
3. 后端生成订单号：1711345600000
4. 遍历商品列表，验证库存充足
5. 验证用户余额充足
6. 批量执行数据库操作（事务中）：
   - 插入订单记录
   - 更新商品库存
   - 扣减用户余额
   - 增加商家余额
   - 删除购物车记录
7. 返回成功响应
8. 前端跳转到订单列表
```

### 失败场景 - 库存不足

**用户操作：**
1. 选择商品加入购物车
2. 提交订单
3. 系统提示"XXX的库存不足"
4. 购物车记录保留，可修改后重试

**系统处理：**
```
1. 前端收集商品数据和收货地址
2. 调用 POST /shangpinOrder/order
3. 后端遍历商品列表
4. 发现库存不足（kucunNumber < buyNumber）
5. 立即返回错误 R.error("XXX的库存不足")
6. 不执行任何数据库操作
7. HTTP拦截器显示错误Toast
8. 购物车记录不变
```

### 失败场景 - 余额不足

**用户操作：**
1. 选择商品，订单总金额200元
2. 用户余额只有100元
3. 提交订单
4. 系统提示"余额不足,请充值！！！"
5. 购物车记录保留

**系统处理：**
```
1. 前端收集商品数据和收货地址
2. 调用 POST /shangpinOrder/order
3. 后端遍历商品列表，库存验证通过
4. 计算订单总金额200元
5. 验证用户余额：100 - 200 < 0
6. 返回错误 R.error("余额不足,请充值!!!")
7. 不执行任何数据库操作
8. HTTP拦截器显示错误Toast
```

---

## Historical Context (from thoughts/)

相关研究文档：

- [2026-03-24-shopping-order-flow.md](https://github.com/hozin25/ShoppingApp/blob/master/thoughts/shared/research/2026-03-24-shopping-order-flow.md) - 购物流程完整实现分析，涵盖了从商品浏览到评价的完整流程

本研究是在之前研究基础上，专门针对**下单后的流程实现**进行更深入的分析。

---

## Related Research

- [2026-03-23-token-verification-mechanism.md](https://github.com/hozin25/ShoppingApp/blob/master/thoughts/shared/research/2026-03-23-token-verification-mechanism.md) - Token验证机制研究
- [2026-03-24-shopping-order-flow.md](https://github.com/hozin25/ShoppingApp/blob/master/thoughts/shared/research/2026-03-24-shopping-order-flow.md) - 完整购物流程研究

---

## Open Questions

1. **并发库存控制**：当前实现在高并发场景下可能存在超卖风险，因为库存检查和扣减之间没有加锁机制

2. **积分支付实现**：前端有积分支付选项，但后端 `/order` 接口中未实现积分支付的完整逻辑

3. **会员折扣应用**：前端获取了会员等级折扣率，但后端订单创建时折扣率固定为1.0，未实际应用折扣

4. **分布式事务**：当前使用本地事务，如果未来需要分库分表或微服务架构，需要考虑分布式事务方案
