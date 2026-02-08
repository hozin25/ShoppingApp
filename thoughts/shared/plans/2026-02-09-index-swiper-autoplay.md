# 小程序首页轮播图自动播放功能实现计划

## 概述

为 uni-mall 小程序首页的轮播图启用自动播放功能，并将切换间隔从 5000ms 调整为 3000ms（3秒）。

## 当前状态分析

### 现有实现
- **文件**: `uni-mall/pages/index/index.vue`
- **轮播图组件**: 使用 uni-app 原生 `<swiper>` 组件
- **自动播放配置**: 已绑定 `:autoplay='autoplaySwiper'` 属性（第8行）
- **当前状态**: `autoplaySwiper` 变量值为 `false`，自动播放被禁用
- **切换间隔**: `intervalSwiper` 变量默认值为 `5000ms`（5秒）
- **循环模式**: 已启用 `:circular='true'`，支持循环滑动
- **指示器**: 已启用，显示当前轮播位置

### 关键代码位置

**数据定义** (`index.vue:129-130`):
```javascript
autoplaySwiper: false ? true : false,
intervalSwiper: false ? $template2.front.base.swiper.autoplay.delay : 5000,
```

**模板绑定** (`index.vue:8`):
```vue
:autoplay='autoplaySwiper'
:interval='intervalSwiper'
```

## 期望状态

修改后，小程序首页的轮播图将：
1. 自动播放，每 3 秒切换一次
2. 保持循环滑动功能
3. 继续显示指示点
4. 用户手动滑动时不会中断自动播放

## 我们不做的内容

- 不修改商品详情页 (`pages/shangpin/detail.vue`) 的轮播图
- 不修改商家详情页 (`pages/shangjia/detail.vue`) 的轮播图
- 不修改轮播图的其他属性（如动画时长、指示器样式等）
- 不添加轮播图的点击跳转功能

## 实施方案

### 修改策略

将 `autoplaySwiper` 变量的值从 `false` 改为 `true`，同时将 `intervalSwiper` 的默认值从 `5000` 改为 `3000`。

### 修改详情

#### 修改 1: 启用自动播放

**文件**: `uni-mall/pages/index/index.vue`
**位置**: 第 129 行
**修改内容**:
```javascript
// 修改前
autoplaySwiper: false ? true : false,

// 修改后
autoplaySwiper: true,
```

#### 修改 2: 调整切换间隔

**文件**: `uni-mall/pages/index/index.vue`
**位置**: 第 130 行
**修改内容**:
```javascript
// 修改前
intervalSwiper: false ? $template2.front.base.swiper.autoplay.delay : 5000,

// 修改后
intervalSwiper: 3000,
```

### 代码简化说明

原代码使用了三元表达式 `false ? ... : ...`，这种写法会导致：
- 条件永远为 `false`，因此总是取冒号后的值
- `autoplaySwiper` 始终为 `false`
- `intervalSwiper` 始终为 `5000`

修改后直接赋值，代码更清晰易懂。

## 测试策略

### 自动验证
- [ ] 文件修改无语法错误
- [ ] 小程序能够正常编译构建

### 手动验证步骤

#### 开发环境测试
1. 启动小程序开发服务器（HBuilderX 或 CLI）
2. 在微信开发者工具中预览首页
3. 验证以下功能：
   - [ ] 轮播图自动播放，每 3 秒切换一次
   - [ ] 指示点随轮播自动更新
   - [ ] 滑动到最后一张后自动回到第一张（循环）
   - [ ] 用户手动滑动后，自动播放继续执行
   - [ ] 轮播图图片正常显示

#### 真机测试
1. 在微信小程序真机预览
2. 验证自动播放功能在真机上正常运行
3. 确认切换间隔符合预期（3秒）

## 性能考虑

- 轮播图切换间隔缩短至 3 秒，会增加图片加载频率
- 图片已缓存，影响可忽略
- 自动播放不会占用额外资源，由 uni-app 原生组件处理

## 参考信息

- **uni-app swiper 文档**: https://uniapp.dcloud.net.cn/component/swiper.html
- **swiper autoplay 属性**: 是否自动切换
- **swiper interval 属性**: 自动切换时间间隔
- **swiper circular 属性**: 是否采用衔接滑动

## 关键文件

- `uni-mall/pages/index/index.vue:129-130` - 需要修改的数据定义
- `uni-mall/pages/index/index.vue:6-21` - 轮播图模板代码
