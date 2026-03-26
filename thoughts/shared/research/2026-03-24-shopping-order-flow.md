---
date: 2026-03-24T00:00:00+08:00
researcher: Claude Code
git_commit: 8304e0e29cba0c11d660d8f356881cbb8aeb6c92
branch: master
repository: https://github.com/hozin25/ShoppingApp.git
topic: "用户从挑选商品到使用购物车下单支付，商家发货，用户收货写评价这个流程是如何实现的"
tags: [research, codebase, shopping-flow, order, cart, payment]
status: complete
last_updated: 2026-03-24
last_updated_by: Claude Code
---

# Research: 购物流程完整实现分析

**Date**: 2026-03-24
**Researcher**: Claude Code
**Git Commit**: 8304e0e29cba0c11d660d8f356881cbb8aeb6c92
**Branch**: master
**Repository**: https://github.com/hozin25/ShoppingApp.git

## Research Question

用户从挑选商品到使用购物车下单支付，商家发货，用户收货写评价这个流程是如何实现的？

## Summary

本购物应用采用前后端分离架构，完整实现了从商品浏览、购物车管理、订单创建支付、商家发货到用户收货评价的完整电商流程。前端使用 uni-app 框架开发的移动端应用，后端使用 Spring Boot + MyBatis-Plus 提供RESTful API，数据存储在MySQL数据库中。订单状态通过状态机模式管理，支持余额支付和积分支付两种方式，实现了库存扣减、资金流转、物流跟踪等核心电商功能。

## Detailed Findings

### 一、商品浏览和挑选

#### 前端实现

**商品列表页面** ([`uni-mall/pages/shangpin/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/list.vue))

- 使用 mescroll-uni 组件实现下拉刷新和上拉加载更多
- 支持商品名称搜索和类型筛选
- 展示商品图片、名称、价格信息

**商品详情页面** ([`uni-mall/pages/shangpin/detail.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/detail.vue))

- 展示轮播图、价格、库存、商品介绍
- 提供两个操作按钮："加入购物车"和"立即购买"
- 查看商品评价列表

**搜索功能实现** ([`list.vue:313-337`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/list.vue#L313-L337))

```javascript
async search() {
    this.mescroll.num = 1;
    let params = {
        page: 1,
        limit: this.mescroll.size,
        shangpinDelete: 1,      // 只查询未删除的商品
        shangxiaTypes: 1,       // 只查询已上架的商品
        shangpinName: this.searchForm.shangpinName
    };
    let res = await this.$api.list('shangpin', params);
    this.list = res.data.list;
}
```

**类型筛选实现** ([`list.vue:198-210`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/list.vue#L198-L210))

- 查询字典表获取商品类型列表：`dicCode: 'shangpin_types'`
- 在列表开头插入"全部"选项
- 用户点击类型后重置列表并重新加载

#### 后端实现

**商品控制器** ([`server/src/main/java/com/controller/ShangpinController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinController.java))

- `GET /shangpin/list` ([`line 362`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinController.java#L362)) - 分页查询商品列表
- `GET /shangpin/detail/{id}` ([`line 380`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinController.java#L380)) - 查询商品详情（同时增加点击量）

**详情查询实现** ([`ShangpinController.java:380-406`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinController.java#L380-L406))

```java
@RequestMapping("/detail/{id}")
public R detail(@PathVariable("id") Long id, HttpServletRequest request) {
    ShangpinEntity shangpin = shangpinService.selectById(id);
    if(shangpin != null) {
        // 点击数量加1
        shangpin.setShangpinClicknum(shangpin.getShangpinClicknum() + 1);
        shangpinService.updateById(shangpin);

        // entity转view
        ShangpinView view = new ShangpinView();
        BeanUtils.copyProperties(shangpin, view);

        // 级联查询商家信息
        ShangjiaEntity shangjia = shangjiaService.selectById(shangpin.getShangjiaId());
        if(shangjia != null) {
            BeanUtils.copyProperties(shangjia, view, new String[]{"id", "createDate"});
            view.setShangjiaId(shangjia.getId());
        }

        // 字典表数据转换
        dictionaryService.dictionaryConvert(view, request);
        return R.ok().put("data", view);
    }
}
```

#### 数据库表结构

**shangpin 表关键字段** ([`ShangpinEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinEntity.java))

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| shangjia_id | Integer | 商家ID |
| shangpin_name | String | 商品名称 |
| shangpin_uuid_number | String | 商品编号 |
| shangpin_photo | String | 商品照片（逗号分隔） |
| shangpin_types | Integer | 商品类型（字典表代码） |
| shangpin_kucun_number | Integer | 商品库存 |
| shangpin_old_money | Double | 商品原价 |
| shangpin_new_money | Double | 现价 |
| shangpin_clicknum | Integer | 商品热度/点击量 |
| shangpin_content | String | 商品介绍（HTML内容） |
| shangxia_types | Integer | 是否上架（1上架，2下架） |
| shangpin_delete | Integer | 逻辑删除（1正常，2已删除） |

---

### 二、购物车功能

#### 前端实现

**加入购物车** ([`uni-mall/pages/shangpin/detail.vue:312-328`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/detail.vue#L312-L328))

```javascript
async onCartTap() {
    // 先查询该商品是否已在购物车中
    let cartRes = await this.$api.page('cart', {
        page: 1,
        limit: 9999,
        shangpinId: this.shangpinId
    })

    // 如果已存在，提示用户
    if(cartRes.data.list.length > 0){
        this.$utils.msg('商品已添加到购物车');
        return
    }

    // 调用后端API添加到购物车
    await this.$api.save('cart', {
        shangpinId: this.detail.id,
        buyNumber: 1,  // 默认数量为1
        yonghuId: this.user.id,
    });
    this.$utils.msg('添加到购物车成功')
}
```

**购物车列表页面** ([`uni-mall/pages/cart/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/cart/list.vue))

- 展示购物车商品列表
- 支持修改数量（+/-按钮）
- 支持勾选商品进行结算
- 数量减为0时自动删除

**修改数量实现** ([`list.vue:191-248`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/cart/list.vue#L191-L248))

- 减数量：数量减为0时触发删除
- 加数量：最大数量限制为100
- 实时更新总金额和总数量

#### 后端实现

**购物车控制器** ([`server/src/main/java/com/controller/CartController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/CartController.java))

- `POST /cart/save` ([`line 144`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/CartController.java#L144)) - 添加到购物车（检查重复）
- `POST /cart/update` ([`line 175`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/CartController.java#L175)) - 更新购物车商品数量
- `POST /cart/delete` ([`line 196`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/CartController.java#L196)) - 删除购物车商品
- `GET /cart/list` ([`line 266`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/CartController.java#L266)) - 查询购物车列表

**添加到购物车实现** ([`CartController.java:144-170`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/CartController.java#L144-L170))

```java
@RequestMapping("/save")
public R save(@RequestBody CartEntity cart, HttpServletRequest request){
    // 从会话中获取用户角色和ID
    String role = String.valueOf(request.getSession().getAttribute("role"));
    if("用户".equals(role))
        cart.setYonghuId(Integer.valueOf(String.valueOf(request.getSession().getAttribute("userId"))));

    // 构建查询条件，检查是否已存在相同的购物车记录
    Wrapper<CartEntity> queryWrapper = new EntityWrapper<CartEntity>()
        .eq("yonghu_id", cart.getYonghuId())
        .eq("shangpin_id", cart.getShangpinId())
        .eq("buy_number", cart.getBuyNumber());

    CartEntity cartEntity = cartService.selectOne(queryWrapper);

    // 如果不存在则插入，存在则返回错误
    if(cartEntity == null){
        cart.setCreateTime(new Date());
        cart.setInsertTime(new Date());
        cartService.insert(cart);
        return R.ok();
    }else {
        return R.error(511,"商品已添加到购物车");
    }
}
```

#### 数据库表结构

**cart 表** ([`db_mall.sql:58-67`](https://github.com/hozin25/ShoppingApp/blob/master/db_mall.sql#L58-L67))

```sql
CREATE TABLE `cart` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `yonghu_id` int(11) DEFAULT NULL COMMENT '所属用户',
  `shangpin_id` int(11) DEFAULT NULL COMMENT '商品',
  `buy_number` int(11) DEFAULT NULL COMMENT '购买数量',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '添加时间',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
)
```

---

### 三、订单创建和支付

#### 前端流程

**步骤1: 购物车点击"立即下单"** ([`uni-mall/pages/cart/list.vue:296`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/cart/list.vue#L296))

```javascript
async createorder() {
    let orderGoods = []
    for (let i = 0; i < this.cart.length; i++) {
        if (this.cart[i].id > 0) {  // id>0表示已勾选
            orderGoods.push(this.cart[i])
        }
    }
    // 存储到缓存并跳转
    uni.setStorageSync('orderGoods', orderGoods)
    this.$utils.jump('../shangpinOrder/confirm')
}
```

**步骤2: 商品详情页直接购买** ([`detail.vue:330-340`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/detail.vue#L330-L340))

```javascript
async onSubmit() {
    // 构建单个商品的订单数据
    let orderGoods = [{
        shangpinId: this.detail.id,
        shangpinName: this.detail.shangpinName,
        shangpinPhoto: this.swiperList[0],
        buyNumber: 1,
        shangpinNewMoney: this.detail.shangpinNewMoney
    }]
    uni.setStorageSync('orderGoods', orderGoods)
    this.$utils.jump('../shangpinOrder/confirm')
}
```

**步骤3: 订单确认页** ([`uni-mall/pages/shangpinOrder/confirm.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue))

- 从缓存读取 `orderGoods` ([`line 76`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue#L76))
- 计算订单总价格
- 获取用户信息和会员折扣 ([`line 86-121`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue#L86-L121))
- 选择或设置收货地址

**提交订单** ([`confirm.vue:124-151`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue#L124-L151))

```javascript
async onSubmitTap() {
    // 验证收货地址
    if(_this.addresszhi == null){
        return _this.$utils.msg('请选择收货地址');
    }

    // 构建订单数据
    let data = {
        addressId: _this.addresszhi.id,
        shangpins: JSON.stringify(_this.orderGoods),
        yonghuId: _this.user.id,
        shangpinOrderPaymentTypes: 1  // 1=余额，2=积分
    }

    // 调用后端API
    await _this.$api.requestConditionDataGet('shangpinOrder','order',null,data)
    // 成功后跳转到订单列表
    _this.$utils.jump('../shangpinOrder/list')
}
```

#### 后端处理流程

**订单创建入口** ([`ShangpinOrderController.java:431-528`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java#L431-L528))

```java
@RequestMapping("/order")
public R order(String params, HttpServletRequest request){
    // 生成唯一订单号
    String shangpinOrderUuidNumber = String.valueOf(new Date().getTime());

    // 获取当前用户ID
    Integer userId = (Integer) request.getSession().getAttribute("userId");

    // 解析参数
    Map<String, Object> map = JSON.parseObject(params, Map.class);
    Integer addressId = (Integer) map.get("addressId");
    Integer shangpinOrderPaymentTypes = (Integer) map.get("shangpinOrderPaymentTypes");
    String shangpins = (String) map.get("shangpins");

    // 解析商品列表
    JSONArray jsonArray = JSON.parseArray(shangpins);

    // 准备处理容器
    List<ShangpinOrderEntity> shangpinOrderList = new ArrayList<>();
    ArrayList<ShangjiaEntity> shangjiaList = new ArrayList<>();
    List<ShangpinEntity> shangpinList = new ArrayList<>();
    List<Integer> cartIds = new ArrayList<>();
    BigDecimal zhekou = new BigDecimal(1.0);

    // 遍历处理每个商品
    for (int i = 0; i < jsonArray.size(); i++){
        Map<String, Object> map1 = (Map<String, Object>) jsonArray.get(i);
        Integer shangpinId = Integer.valueOf(String.valueOf(map1.get("shangpinId")));
        Integer buyNumber = Integer.valueOf(String.valueOf(map1.get("buyNumber")));

        // 查询商品实体
        ShangpinEntity shangpinEntity = shangpinService.selectById(shangpinId);

        // 检查库存是否充足
        if(shangpinEntity.getShangpinKucunNumber() < buyNumber){
            return R.error(shangpinEntity.getShangpinName()+"的库存不足");
        }

        // 扣减库存
        shangpinEntity.setShangpinKucunNumber(shangpinEntity.getShangpinKucunNumber() - buyNumber);

        // 创建订单实体
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

        // 余额支付处理
        if(shangpinOrderPaymentTypes == 1){
            // 计算订单金额（应用折扣）
            Double money = new BigDecimal(shangpinEntity.getShangpinNewMoney())
                .multiply(new BigDecimal(buyNumber))
                .multiply(zhekou)
                .doubleValue();

            // 验证用户余额
            if(yonghuEntity.getNewMoney() - money < 0){
                return R.error("余额不足,请充值！！！");
            }

            // 扣减用户余额
            yonghuEntity.setNewMoney(yonghuEntity.getNewMoney() - money);
            shangpinOrderEntity.setShangpinOrderTruePrice(money);

            // 增加商家余额
            shangjiaEntity.setNewMoney(shangjiaEntity.getNewMoney() + money);
        }

        // 收集处理结果
        shangpinOrderList.add(shangpinOrderEntity);
        shangjiaList.add(shangjiaEntity);
        shangpinList.add(shangpinEntity);
    }

    // 批量保存数据
    shangpinOrderService.insertBatch(shangpinOrderList);
    shangjiaService.updateBatchById(shangjiaList);
    shangpinService.updateBatchById(shangpinList);
    yonghuService.updateById(yonghuEntity);

    // 删除购物车记录
    if(cartIds.size() > 0){
        cartService.deleteBatchIds(cartIds);
    }

    return R.ok();
}
```

#### 数据库表结构

**shangpin_order 表** ([`ShangpinOrderEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinOrderEntity.java))

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键 |
| shangpin_order_uuid_number | String | 订单号（时间戳） |
| address_id | Integer | 收货地址ID |
| shangpin_id | Integer | 商品ID |
| yonghu_id | Integer | 用户ID |
| buy_number | Integer | 购买数量 |
| shangpin_order_true_price | Double | 实付价格 |
| shangpin_order_courier_name | String | 快递公司 |
| shangpin_order_courier_number | String | 快递单号 |
| shangpin_order_types | Integer | 订单类型（状态） |
| shangpin_order_payment_types | Integer | 支付类型（1=余额，2=积分） |
| insert_time | Date | 订单创建时间 |

---

### 四、订单状态管理

#### 订单状态定义

| 状态码 | 名称 | 说明 |
|--------|------|------|
| 101 | 已支付 | 订单创建完成 |
| 102 | 已退款 | 用户申请退款 |
| 103 | 已发货 | 商家已发货 |
| 104 | 已收货 | 用户确认收货 |
| 105 | 已评价 | 用户完成评价 |

#### 状态流转图

```
已支付(101) → [商家发货] → 已发货(103) → [用户收货] → 已收货(104) → [用户评价] → 已评价(105)
     ↓
[用户退款]
     ↓
已退款(102)
```

#### 订单列表展示 ([`uni-mall/pages/shangpinOrder/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue))

- 使用 mescroll-uni 组件实现下拉刷新和上拉加载
- 根据订单状态显示不同颜色的标签
- 根据状态显示不同的操作按钮：
  - 已支付(101)：显示"退款"按钮（用户），显示"发货"按钮（商家）
  - 已发货(103)：显示"收货"按钮（用户）
  - 已收货(104)：显示"评价"按钮（用户）

---

### 五、商家发货

#### 前端实现 ([`list.vue:51-55, 74-98, 284-322`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue#L51-L98))

商家订单列表中，状态为"已支付"的订单显示"发货"按钮：

```vue
<view v-if="item.shangpinOrderTypes==101 && item.ShangpinyonghuId == user.id">
    <view @tap="openDeliver(item.id)" class="round cu-btn lines-grey mid margin-right-sm">发货</view>
</view>
```

点击后弹出模态框，输入：
- 快递公司名称
- 快递单号

**发货方法实现** ([`list.vue:284-322`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue#L284-L322))

```javascript
async deliver(id) {
    // 验证输入
    if(this.shangpinOrderCourierName == null || this.shangpinOrderCourierName == ""){
        return this.$utils.msg('快递公司不能为空');
    }
    if(this.shangpinOrderCourierNumber == null || this.shangpinOrderCourierNumber == ""){
        return this.$utils.msg('订单快递单号不能为空');
    }

    // 构建请求数据
    let value = [
        {key:'id', val:id},
        {key: 'shangpinOrderCourierName', val: this.shangpinOrderCourierName},
        {key: 'shangpinOrderCourierNumber', val: this.shangpinOrderCourierNumber}
    ]

    // 调用API
    await this.$api.requestCondition("shangpinOrder", "deliver", value);

    // 关闭模态框并刷新
    this.$refs.deliver.close();
    this.mescroll.resetUpScroll();
}
```

#### 后端API ([`ShangpinOrderController.java:620-630`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java#L620-L630))

```java
@RequestMapping("/deliver")
public R deliver(Integer id, String shangpinOrderCourierNumber, String shangpinOrderCourierName, HttpServletRequest request){
    logger.debug("refund:,,Controller:{},,ids:{}",this.getClass().getName(),id.toString());
    ShangpinOrderEntity shangpinOrderEntity = shangpinOrderService.selectById(id);
    shangpinOrderEntity.setShangpinOrderTypes(103); // 设置订单状态为已发货
    shangpinOrderEntity.setShangpinOrderCourierNumber(shangpinOrderCourierNumber);
    shangpinOrderEntity.setShangpinOrderCourierName(shangpinOrderCourierName);
    shangpinOrderService.updateById(shangpinOrderEntity);
    return R.ok();
}
```

---

### 六、用户收货

#### 前端实现 ([`list.vue:48-50, 252-271`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue#L48-L50))

状态为"已发货"(103)的订单显示"收货"按钮，点击后弹出确认对话框。

```javascript
async receiving(id) {
    uni.showModal({
        title: '提示',
        content: '是否确认要收货？',
        success: async (res) => {
            if (res.confirm) {
                let value = [{key:'id', val:id}]
                await this.$api.requestCondition("shangpinOrder", "receiving", value)
                this.$utils.msg('操作成功')
                this.mescroll.resetUpScroll()
            }
        }
    })
}
```

#### 后端API ([`ShangpinOrderController.java:636-643`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java#L636-L643))

```java
@RequestMapping("/receiving")
public R receiving(Integer id, HttpServletRequest request){
    logger.debug("refund:,,Controller:{},,ids:{}",this.getClass().getName(),id.toString());
    ShangpinOrderEntity shangpinOrderEntity = shangpinOrderService.selectById(id);
    shangpinOrderEntity.setShangpinOrderTypes(104); // 设置订单状态为收货
    shangpinOrderService.updateById(shangpinOrderEntity);
    return R.ok();
}
```

---

### 七、商品评价

#### 前端实现 ([`list.vue:45-47, 59-73, 222-246`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue#L45-L73))

状态为"已收货"(104)的订单显示"评价"按钮，点击后弹出评价输入框。

**评价弹窗UI** ([`list.vue:59-73`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue#L59-L73))

```vue
<uni-popup ref="popup" type="dialog">
    <uni-popup-dialog type="dialog" title="评论" :duration="200"
        :before-close="true" @close="close" @confirm="onFinishTap">
        <view class="popup-content">
            <input type="text" v-model="shangpinCommentbackText" placeholder="请输入评价内容"/>
        </view>
    </uni-popup-dialog>
</uni-popup>
```

**提交评价** ([`list.vue:227-246`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue#L227-L246))

```javascript
async onFinishTap() {
    if(!this.shangpinCommentbackText){
        return this.$utils.msg('请填写评价内容');
    }

    let value = [
        {key:'id', val:this.shangpinId},
        {key:'commentbackText', val:this.shangpinCommentbackText}
    ]

    await this.$api.requestCondition("shangpinOrder", "commentback", value)
    this.$utils.msg('评价成功')
    this.$refs.popup.close()
    this.mescroll.resetUpScroll()
}
```

#### 后端API ([`ShangpinOrderController.java:591-615`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java#L591-L615))

```java
@RequestMapping("/commentback")
public R commentback(Integer id, String commentbackText, Integer shangpinCommentbackPingfenNumber, HttpServletRequest request){
    logger.debug("commentback方法:,,Controller:{},,id:{}",this.getClass().getName(),id);
    ShangpinOrderEntity shangpinOrder = shangpinOrderService.selectById(id);
    if(shangpinOrder == null)
        return R.error(511,"查不到该订单");
    Integer shangpinId = shangpinOrder.getShangpinId();
    if(shangpinId == null)
        return R.error(511,"查不到该商品");

    // 创建评价记录
    ShangpinCommentbackEntity shangpinCommentbackEntity = new ShangpinCommentbackEntity();
    shangpinCommentbackEntity.setId(id);
    shangpinCommentbackEntity.setShangpinId(shangpinId);
    shangpinCommentbackEntity.setYonghuId((Integer) request.getSession().getAttribute("userId"));
    shangpinCommentbackEntity.setShangpinCommentbackText(commentbackText);
    shangpinCommentbackEntity.setInsertTime(new Date());
    shangpinCommentbackEntity.setReplyText(null);
    shangpinCommentbackEntity.setUpdateTime(null);
    shangpinCommentbackEntity.setCreateTime(new Date());
    shangpinCommentbackService.insert(shangpinCommentbackEntity);

    // 更新订单状态为已评价
    shangpinOrder.setShangpinOrderTypes(105);
    shangpinOrderService.updateById(shangpinOrder);
    return R.ok();
}
```

#### 评价表结构

**shangpin_commentback 表** ([`ShangpinCommentbackEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinCommentbackEntity.java))

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 主键（使用订单ID） |
| shangpin_id | Integer | 商品ID |
| yonghu_id | Integer | 用户ID |
| shangpin_commentback_text | String | 评价内容 |
| insert_time | Date | 评价时间 |
| reply_text | String | 回复内容 |
| update_time | Date | 回复时间 |
| create_time | Date | 创建时间 |

---

## Code References

### 前端核心文件

| 文件路径 | 功能描述 |
|----------|----------|
| [`uni-mall/pages/shangpin/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/list.vue) | 商品列表页（搜索、筛选、分页） |
| [`uni-mall/pages/shangpin/detail.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpin/detail.vue) | 商品详情页（加入购物车、立即购买） |
| [`uni-mall/pages/cart/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/cart/list.vue) | 购物车页面（数量修改、结算） |
| [`uni-mall/pages/shangpinOrder/confirm.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/confirm.vue) | 订单确认页（地址选择、支付提交） |
| [`uni-mall/pages/shangpinOrder/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/shangpinOrder/list.vue) | 订单列表（发货、收货、评价） |
| [`uni-mall/pages/address/list.vue`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/pages/address/list.vue) | 收货地址管理 |
| [`uni-mall/api/index.js`](https://github.com/hozin25/ShoppingApp/blob/master/uni-mall/api/index.js) | API封装（统一请求方法） |

### 后端核心文件

| 文件路径 | 功能描述 |
|----------|----------|
| [`server/src/main/java/com/controller/ShangpinController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinController.java) | 商品API控制器 |
| [`server/src/main/java/com/controller/CartController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/CartController.java) | 购物车API控制器 |
| [`server/src/main/java/com/controller/ShangpinOrderController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinOrderController.java) | 订单API控制器 |
| [`server/src/main/java/com/controller/ShangpinCommentbackController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/ShangpinCommentbackController.java) | 评价API控制器 |
| [`server/src/main/java/com/controller/AddressController.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/controller/AddressController.java) | 地址API控制器 |
| [`server/src/main/java/com/entity/ShangpinEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinEntity.java) | 商品实体类 |
| [`server/src/main/java/com/entity/CartEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/CartEntity.java) | 购物车实体类 |
| [`server/src/main/java/com/entity/ShangpinOrderEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinOrderEntity.java) | 订单实体类 |
| [`server/src/main/java/com/entity/ShangpinCommentbackEntity.java`](https://github.com/hozin25/ShoppingApp/blob/master/server/src/main/java/com/entity/ShangpinCommentbackEntity.java) | 评价实体类 |

---

## Architecture Documentation

### 技术栈

**前端（uni-mall）**
- uni-app 框架（基于 Vue.js 2）
- ColorUI CSS 框架
- mescroll-uni（分页组件）
- uni-ui 组件库

**后端（server）**
- Spring Boot 2.2.2
- MyBatis-Plus 2.3
- Apache Shiro 1.3.2（认证授权）
- FastJSON 1.2.8（JSON序列化）

**数据库**
- MySQL
- 表：shangpin、cart、shangpin_order、shangpin_commentback、address、yonghu、shangjia

### 设计模式

**1. 前后端分离模式**
- 前端通过 uni.request 调用后端 RESTful API
- 使用 Token（存储在 localStorage）进行身份认证
- 统一的响应格式：`{code, message, data}`

**2. 状态机模式**
- 订单状态通过 `shangpin_order_types` 字段管理
- 状态转换通过专门的接口处理（refund、deliver、receiving、commentback）
- 每个状态对应不同的操作权限

**3. 批量处理模式**
- 后端使用列表收集多个实体后批量操作
- 减少数据库交互次数，提高性能
- 例如：订单创建时的批量插入和更新

**4. 缓存传递模式**
- 使用 `uni.setStorageSync` 和 `uni.getStorageSync` 在页面间传递数据
- `orderGoods` 缓存存储商品列表
- `address` 缓存存储选中的地址

**5. 分页加载模式**
- 前端使用 mescroll-uni 组件实现下拉刷新和上拉加载
- 后端使用 MyBatis-Plus 的分页插件
- 前端合并数据：`this.list = this.list.concat(res.data.list)`

**6. 字典表模式**
- 系统枚举值统一存储在 dictionary 表
- 后端 `dictionaryService.dictionaryConvert` 将代码转换为名称
- 支持动态配置，无需修改代码

### API 接口规范

**通用接口格式**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /{table}/page | 后台分页查询 |
| GET | /{table}/list | 前台列表查询 |
| GET | /{table}/info/{id} | 查询详情 |
| POST | /{table}/save | 新增记录 |
| PUT | /{table}/update | 更新记录 |
| DELETE | /{table}/delete | 删除记录 |

**订单专用接口**

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /shangpinOrder/order | 创建订单 |
| POST | /shangpinOrder/refund | 申请退款 |
| POST | /shangpinOrder/deliver | 商家发货 |
| POST | /shangpinOrder/receiving | 用户收货 |
| POST | /shangpinOrder/commentback | 用户评价 |

---

## 完整数据流图

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              购物流程完整数据流                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

用户操作              前端页面                      后端API                  数据库
───────────────────────────────────────────────────────────────────────────────────
浏览商品
   ↓
shangpin/list.vue  →  GET /shangpin/list  →  查询shangpin表  →  返回商品列表
   ↓                      ↓                         ↓
展示商品列表          分页查询                  MyBatis-Plus

加入购物车
   ↓
shangpin/detail.vue →  POST /cart/save    →  检查重复          cart表
(点击购物车)              ↓                      ↓
                    插入购物车记录          插入cart记录

查看购物车
   ↓
cart/list.vue      →  GET /cart/list      →  查询cart表       →  返回购物车
   ↓                      ↓                         ↓
展示购物车商品          关联查询               JOIN yonghu/shangpin

修改数量
   ↓
cart/list.vue      →  POST /cart/update   →  更新buy_number   cart表
(+/-按钮)               ↓                      ↓
                    更新成功               UPDATE cart

删除商品
   ↓
cart/list.vue      →  POST /cart/delete   →  删除记录          cart表
(数量为0)               ↓                      ↓
                    删除成功               DELETE FROM cart

下单
   ↓
cart/list.vue      →  收集选中的商品         →                  →
(立即下单)              ↓
                    uni.setStorageSync
                    ('orderGoods')
                        ↓
                    跳转订单确认页
                        ↓
shangpinOrder/     →  读取orderGoods缓存      →
confirm.vue            ↓
                    获取用户信息和地址    GET /yonghu/info   yonghu表
                    计算会员折扣和总价       ↓
                        ↓                  查询huiyuandengji字典
                    选择收货地址        GET /address/list    address表
                        ↓
                    点击确认支付            →
                        ↓
                    POST /shangpinOrder/order
                        ↓
                               ┌─────────────────────────────────┐
                               │         后端订单处理              │
                               └─────────────────────────────────┘
                                         ↓
                    ┌────────────────────────────────────────────┐
                    │  1. 解析商品列表 (JSON → List<Map>)         │
                    │  2. 遍历每个商品:                            │
                    │     - 查询商品和商家信息                     │
                    │     - 验证库存是否充足                       │
                    │     - 扣减库存                              │
                    │     - 计算金额 (应用折扣)                    │
                    │     - 验证用户余额                           │
                    │     - 扣减用户余额                          │
                    │     - 增加商家余额                          │
                    │  3. 批量保存:                               │
                    │     - 创建订单记录 (状态=101已支付)          │
                    │     - 更新商品库存                          │
                    │     - 更新用户余额                          │
                    │     - 更新商家余额                          │
                    │     - 删除购物车记录                        │
                    └────────────────────────────────────────────┘
                                         ↓
                    shangpin_order表 (订单记录)
                    yonghu表 (余额-)
                    shangjia表 (余额+)
                    shangpin表 (库存-)
                    cart表 (删除已购商品)
                                         ↓
                    返回成功 → 跳转订单列表页

查看订单
   ↓
shangpinOrder/     →  GET /shangpinOrder/ →  查询shangpin_order →  返回订单列表
list.vue          list/page              表
   ↓                      ↓                         ↓
展示订单状态          角色过滤                WHERE yonghuId=?
和操作按钮            (用户/商家)              ORDER BY insertTime DESC

商家发货
   ↓
shangpinOrder/     →  POST /shangpinOrder/ →  更新订单状态      shangpin_order
list.vue          deliver                    ↓                 表
(商家发货)              ↓                 UPDATE SET types=103
                    更新物流信息              courier_name
                    courier_number

用户收货
   ↓
shangpinOrder/     →  POST /shangpinOrder/ →  更新订单状态      shangpin_order
list.vue          receiving                  ↓                 表
(确认收货)              ↓                 UPDATE SET types=104
                    显示确认对话框

用户评价
   ↓
shangpinOrder/     →  POST /shangpinOrder/ →  插入评价记录      shangpin_commentback
list.vue          commentback                ↓                 表
(评价商品)              ↓                 INSERT INTO         ↓
                    更新订单状态         UPDATE types=105    shangpin_order
                                                       表

───────────────────────────────────────────────────────────────────────────────────
                              订单状态流转总结
───────────────────────────────────────────────────────────────────────────────────

    已支付(101)         已退款(102)         已发货(103)         已收货(104)         已评价(105)
    ──────────         ──────────         ──────────         ──────────         ──────────
    订单创建完成        用户申请退款        商家已发货          用户确认收货        用户完成评价
    库存已扣减          余额已退还          物流信息已记录      可进行评价          流程结束
    用户余额-           商品库存恢复        等待用户收货        等待用户评价
    商家余额+           订单已关闭          可进行收货          可进行评价
    购物车已清空

    操作权限:
    - 用户: 退款         - 无              - 收货               - 评价             - 无
    - 商家: 发货        - 无              - 无                 - 无              - 无
```

---

## Historical Context (from thoughts/)

暂无相关历史文档。这是首次对完整购物流程进行的系统性研究。

---

## Related Research

- [2025-03-22-carousel-banner-implementation.md](https://github.com/hozin25/ShoppingApp/blob/master/thoughts/shared/research/2025-03-22-carousel-banner-implementation.md) - 轮播图实现研究
- [2025-03-22-file-upload-location-issue.md](https://github.com/hozin25/ShoppingApp/blob/master/thoughts/shared/research/2025-03-22-file-upload-location-issue.md) - 文件上传位置问题研究
- [2026-03-23-token-verification-mechanism.md](https://github.com/hozin25/ShoppingApp/blob/master/thoughts/shared/research/2026-03-23-token-verification-mechanism.md) - Token验证机制研究

---

## Open Questions

暂无未解决的问题。整个购物流程的实现已完整梳理。
