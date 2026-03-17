# Tesla 风格首页 UI 改造计划

## Overview

将小程序首页从当前的绿色主题改造为特斯拉风格的极简现代 UI，使用特斯拉品牌色彩（红色、蓝色、白色），采用浅色模式，保留所有现有功能模块。

## Current State Analysis

### 当前首页设计 (`uni-mall/pages/index/index.vue`)

| 区域 | 当前样式 | 问题分析 |
|------|---------|---------|
| **导航栏** | 绿色 (#71A842) | 与特斯拉风格不符 |
| **轮播图** | 300rpx 高度，圆角 20rpx | 圆角过大，缺乏极简感 |
| **菜单网格** | 21% 宽度，彩色背景 | 过于花哨，需要简化 |
| **公告列表** | 绿色圆点指示器 | 需要更新为特斯拉风格 |
| **商品/商家展示** | 圆形图片 (180rpx) | 不符合特斯拉卡片式布局 |
| **整体背景** | #F8F8F8 | 可保持浅色，但需调整 |

### 当前主题色 (`utils/theme.css`)

```css
--publicMainColor: #71A842;  /* 绿色 */
--publicSubColor: #54C0CC;   /* 青色 */
```

### 当前导航配置 (`pages.json`)

- 导航栏背景色: `#71A842`
- TabBar 背景色: `#54C0CC`
- 导航栏文字: 白色

## Desired End State

### Tesla 风格设计规范

**颜色体系（浅色模式）：**

| 用途 | 颜色值 | 说明 |
|------|--------|------|
| 主色调 | `#E82127` | Tesla Red - 用于主要操作、强调 |
| 次要色 | `#3E6AE1` | Tesla Blue - 用于次要操作、链接 |
| 背景色 | `#FFFFFF` | 纯白背景 |
| 表面色 | `#F9FAFB` | 卡片/模块背景 |
| 文字主色 | `#171A20` | 深灰/黑色文字 |
| 文字次要色 | `#6B7280` | 中灰文字 |
| 边框色 | `#E5E7EB` | 细线边框 |
| 分隔线 | `#F3F4F6` | 卡片间隔 |
| 阴影 | `0 1px 3px rgba(0,0,0,0.08)` | 极简阴影 |

**设计原则：**

1. **极简主义** - 去除多余装饰，突出内容
2. **卡片式布局** - Bento 风格模块化卡片
3. **小圆角** - 使用 12-16rpx 圆角（当前 20rpx 过大）
4. **细边框** - 1rpx 细线分隔
5. **大间距** - 增加留白，提升呼吸感
6. **清晰层次** - 通过阴影和边框区分层级

### 目标视觉效果

```
┌─────────────────────────────────────────────────────────────────┐
│  【导航栏】白色背景 + Tesla Red 标题 + 黑色文字                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 【轮播图】全宽 + 极小圆角 (12rpx) + 细微阴影               │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 【菜单网格】浅灰背景 + 白色卡片 + 细线分隔                  │  │
│  │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                         │  │
│  │ │ 图标 │ │ 图标 │ │ 图标 │ │ 图标 │   Tesla Red 图标     │  │
│  │ └─────┘ └─────┘ └─────┘ └─────┘                         │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 【公告信息】简洁卡片布局 + 左侧红色细线指示器              │  │
│  │ ◆ 公告标题 1                                              │  │
│  │ ◆ 公告标题 2                                              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 【商品展示】大图卡片 + 去除圆形图片                        │  │
│  │ ┌─────────┐ ┌─────────┐ ┌─────────┐                      │  │
│  │ │  商品   │ │  商品   │ │  商品   │   方形卡片布局        │  │
│  │ │  图片   │ │  图片   │ │  图片   │                      │  │
│  │ └─────────┘ └─────────┘ └─────────┘                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  【商家展示】同商品展示风格                                       │
└─────────────────────────────────────────────────────────────────┘
```

## What We're NOT Doing

- **不修改深色模式** - 本次仅实现浅色模式
- **不修改导航逻辑** - 保持所有页面跳转功能不变
- **不修改数据接口** - 后端 API 调用保持不变
- **不修改其他页面** - 本次仅改造首页 (`pages/index/index.vue`)
- **不修改功能** - 所有现有功能保持不变，只改变视觉样式

## Implementation Approach

采用渐进式改造策略，分 5 个阶段完成：

```
Phase 1: 主题色系统更新
    ↓
Phase 2: 导航栏和 TabBar 更新
    ↓
Phase 3: 轮播图组件改造
    ↓
Phase 4: 菜单网格和内容区域重设计
    ↓
Phase 5: 微动效添加
```

---

## Phase 1: 主题色系统更新

### Overview
创建 Tesla 风格的主题色变量，更新全局样式。

### Changes Required:

#### 1. 更新 `uni-mall/utils/theme.css`

**File**: `uni-mall/utils/theme.css`

```css
/* 修改前
page {
	--publicMainColor: #71A842;
	--publicSubColor:  #54C0CC;
}
*/

/* 修改后 */
page {
	/* Tesla 风格主题色 */
	--publicMainColor: #E82127;  /* Tesla Red - 主色调 */
	--publicSubColor: #3E6AE1;   /* Tesla Blue - 次要色 */

	/* Tesla 风格扩展颜色 */
	--tesla-bg-primary: #FFFFFF;      /* 主背景色 */
	--tesla-bg-secondary: #F9FAFB;    /* 次背景色 */
	--tesla-text-primary: #171A20;    /* 主文字色 */
	--tesla-text-secondary: #6B7280;  /* 次要文字色 */
	--tesla-border: #E5E7EB;          /* 边框色 */
	--tesla-divider: #F3F4F6;         /* 分隔线色 */
	--tesla-card-shadow: 0 1px 3px rgba(0, 0, 0, 0.08); /* 卡片阴影 */
}
```

### Success Criteria:

#### Automated Verification:
- [ ] 文件语法正确
- [ ] CSS 变量定义有效

#### Manual Verification:
- [ ] 打开任意页面，确认 CSS 变量加载正确

---

## Phase 2: 导航栏和 TabBar 更新

### Overview
更新 `pages.json` 中的导航栏和 TabBar 配置，采用特斯拉风格。

### Changes Required:

#### 1. 更新 `uni-mall/pages.json`

**File**: `uni-mall/pages.json`

**首页导航栏配置 (第 344-350 行):**
```json
// 修改前
{
	"path": "pages/index/index",
	"style": {
		"navigationBarBackgroundColor": "#71A842",
		"navigationBarTextStyle": "white",
		"navigationBarTitleText": "智能小程序商城首页"
	}
}

// 修改后
{
	"path": "pages/index/index",
	"style": {
		"navigationBarBackgroundColor": "#FFFFFF",
		"navigationBarTextStyle": "black",
		"navigationBarTitleText": "智能小程序商城",
		"navigationBarTitleColor": "#171A20"
	}
}
```

**TabBar 配置 (第 358-394 行):**
```json
// 修改前
"tabBar": {
	"color": "#FFFFFF",
	"selectedColor": "#fff",
	"borderStyle": "black",
	"backgroundColor": "#54C0CC",
	"list": [...]
}

// 修改后
"tabBar": {
	"color": "#6B7280",
	"selectedColor": "#E82127",
	"borderStyle": "white",
	"backgroundColor": "#FFFFFF",
	"list": [...]
}
```

### Success Criteria:

#### Manual Verification:
- [ ] 首页导航栏变为白色背景，黑色文字
- [ ] TabBar 变为白色背景，未选中为灰色，选中为 Tesla Red

---

## Phase 3: 轮播图组件改造

### Overview
将轮播图改造为特斯拉风格的全宽卡片设计，减少圆角，添加微妙阴影。

### Changes Required:

#### 1. 更新 `uni-mall/pages/index/index.vue` 轮播图样式

**File**: `uni-mall/pages/index/index.vue`

**Template 部分 (第 4-23 行):**
```vue
<!-- 修改前 -->
<view class="header">
    <view class="headerb">
        <swiper :style='{"padding":"0","boxShadow":"0 2rpx 12rpx rgba(0,0,0,0)","margin":"0 3% 20rpx","borderColor":"rgba(0,0,0,0)","backgroundColor":"rgba(255, 255, 255, 0)","borderRadius":"0","borderWidth":"0","width":"94%","borderStyle":"solid","height":"300rpx"}'
                class="swiper" :indicator-dots='".swiper-pagination"==null?false:true'
                :autoplay='autoplaySwiper' :circular='true'
                indicator-color='rgba(0, 0, 0, .3)' :duration='1000' :interval='intervalSwiper'
                :vertical='"horizontal"=="horizontal"?false:true'>
            <swiper-item
                    :style='{"padding":"0","boxShadow":"0 2rpx 12rpx rgba(0,0,0,0)","margin":"0","borderColor":"rgba(0,0,0,0)","backgroundColor":"rgba(255,255,255,1)","borderRadius":"20rpx","borderWidth":"0","width":"100%","borderStyle":"solid","height":"300rpx"}'
                    v-for="(swiper,index) in swiperList" :key="index" @tap="onSwiperTap(swiper)">
                <image :style='{"padding":"0","boxShadow":"0 2rpx 12rpx rgba(0,0,0,0)","margin":"0","borderColor":"rgba(0,0,0,0)","backgroundColor":"rgba(255,255,255,1)","borderRadius":"20rpx","borderWidth":"0","width":"100%","borderStyle":"solid","height":"300rpx"}'
                       mode="aspectFill" :src="baseUrl+swiper.img"></image>
            </swiper-item>
        </swiper>
    </view>
</view>

<!-- 修改后 -->
<view class="tesla-header">
    <view class="tesla-headerb">
        <swiper class="tesla-swiper"
                :indicator-dots="swiperList.length > 1"
                :autoplay="autoplaySwiper"
                :circular="true"
                indicator-color="rgba(0, 0, 0, 0.2)"
                indicator-active-color="#E82127"
                :duration="600"
                :interval="intervalSwiper">
            <swiper-item v-for="(swiper,index) in swiperList" :key="index" @tap="onSwiperTap(swiper)">
                <image class="tesla-swiper-image" mode="aspectFill" :src="baseUrl+swiper.img"></image>
            </swiper-item>
        </swiper>
    </view>
</view>
```

**Style 部分 (新增样式):**
```css
/* Tesla 风格轮播图样式 */
.tesla-header {
    background: var(--tesla-bg-primary);
    padding: 24rpx 24rpx 0;
}

.tesla-headerb {
    width: 100%;
}

.tesla-swiper {
    width: 100%;
    height: 360rpx;
    border-radius: 12rpx;
    overflow: hidden;
    box-shadow: var(--tesla-card-shadow);
}

.tesla-swiper-image {
    width: 100%;
    height: 100%;
    border-radius: 12rpx;
}

/* 覆盖默认指示器样式 */
.tesla-swiper /deep/ .uni-swiper-dot {
    width: 8rpx;
    height: 8rpx;
    border-radius: 50%;
}

.tesla-swiper /deep/ .uni-swiper-dot-active {
    width: 24rpx;
    border-radius: 4rpx;
}
```

### Success Criteria:

#### Manual Verification:
- [ ] 轮播图全宽显示，左右边距 24rpx
- [ ] 圆角从 20rpx 改为 12rpx
- [ ] 指示器激活状态为 Tesla Red (#E82127)
- [ ] 添加微妙阴影效果

---

## Phase 4: 菜单网格和内容区域重设计

### Overview
将菜单网格改造为 Bento 卡片风格，重新设计公告列表、商品展示和商家展示区域。

### Changes Required:

#### 1. 更新菜单网格样式

**File**: `uni-mall/pages/index/index.vue`

**Template 部分 (第 25-45 行):**
```vue
<!-- 修改前 -->
<view v-if="true" class="menu" style="display: flex;flex-wrap: wrap;justify-content: space-around"
      :style='{"padding":"0 8rpx","boxShadow":"0 2rpx 12rpx rgba(0,0,0,0)","margin":"0","borderColor":"rgba(0,0,0,0)","backgroundColor":"rgba(255,255,255,1)","borderRadius":"0","borderWidth":"0","width":"100%","borderStyle":"solid","height":"auto"}'>
    <!-- menu items... -->
</view>

<!-- 修改后 -->
<view class="tesla-menu-grid">
    <block v-for="item in menuList" v-bind:key="item.roleName">
        <block v-if="(role==item.roleName||table==item.tableName) && index<=4 && index>0" v-bind:key="index" v-for=" (menu,index) in item.backMenu">
            <block v-bind:key="sort" v-for=" (child,sort) in menu.child">
                <block v-for=" (button,sort2) in child.buttons">
                    <view class="tesla-menu-item" v-if="button=='查看'" @tap="onPageTap2('../'+child.tableName+'/list')">
                        <view class="tesla-menu-icon" :class="child.appFrontIcon"></view>
                        <view class="tesla-menu-label">{{child.menu.split("列表")[0]}}</view>
                    </view>
                </block>
            </block>
        </block>
    </block>
</view>
```

#### 2. 更新公告列表样式

**Template 部分 (第 48-71 行):**
```vue
<!-- 修改前 -->
<view class="listBox news">
    <view class="title"...>公告信息展示...</view>
    <view class="news-box3"...>...</view>
</view>

<!-- 修改后 -->
<view class="tesla-section tesla-news-section">
    <view class="tesla-section-header">
        <view class="tesla-section-title">公告信息</view>
        <view class="tesla-section-more" @tap="onPageTap('news')">查看更多</view>
    </view>
    <view class="tesla-news-list">
        <view class="tesla-news-item" v-for="(item,index) in newsList" :key="index"
              @tap="onDetailTap('news',item.id)">
            <view class="tesla-news-indicator"></view>
            <view class="tesla-news-title">{{item.newsName}}</view>
            <view class="tesla-news-arrow cuIcon-right"></view>
        </view>
    </view>
</view>
```

#### 3. 更新商品展示样式

**Template 部分 (第 72-91 行):**
```vue
<!-- 修改前 -->
<view class="listBox recommend">
    <view class="title"...>商品展示...</view>
    <view v-if='2 == 2' class="uni-product-list"...>...</view>
</view>

<!-- 修改后 -->
<view class="tesla-section tesla-product-section">
    <view class="tesla-section-header">
        <view class="tesla-section-title">商品推荐</view>
        <view class="tesla-section-more" @tap="onPageTap('shangpin')">查看更多</view>
    </view>
    <view class="tesla-product-list">
        <view class="tesla-product-card" v-for="(product,index) in shangpinList" :key="index"
              @tap="onDetailTap('shangpin',product.id)">
            <view class="tesla-product-image-wrapper">
                <image class="tesla-product-image" mode="aspectFill" :src="baseUrl+product.shangpinPhoto"></image>
            </view>
            <view class="tesla-product-name">{{product.shangpinName}}</view>
        </view>
    </view>
</view>
```

#### 4. 更新商家展示样式（同商品展示）

**Template 部分 (第 92-111 行):**
```vue
<!-- 修改后 -->
<view class="tesla-section tesla-merchant-section">
    <view class="tesla-section-header">
        <view class="tesla-section-title">推荐商家</view>
        <view class="tesla-section-more" @tap="onPageTap('shangjia')">查看更多</view>
    </view>
    <view class="tesla-merchant-list">
        <view class="tesla-merchant-card" v-for="(product,index) in shangjiaList" :key="index"
              @tap="onDetailTap('shangjia',product.id)">
            <view class="tesla-merchant-image-wrapper">
                <image class="tesla-merchant-image" mode="aspectFill" :src="baseUrl+product.shangjiaPhoto"></image>
            </view>
            <view class="tesla-merchant-name">{{product.shangjiaName}}</view>
        </view>
    </view>
</view>
```

#### 5. 新增样式

**Style 部分 (新增到 `<style>` 标签):**
```css
/* ========== Tesla 风格全局样式 ========== */
page {
    background: var(--tesla-bg-primary);
}

.uni-padding-wrap {
    padding: 0;
}

/* ========== Tesla 风格菜单网格 ========== */
.tesla-menu-grid {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-start;
    padding: 32rpx 24rpx;
    background: var(--tesla-bg-secondary);
    gap: 16rpx;
}

.tesla-menu-item {
    width: calc((100% - 48rpx) / 4);
    aspect-ratio: 1;
    background: var(--tesla-bg-primary);
    border-radius: 16rpx;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    box-shadow: var(--tesla-card-shadow);
    transition: all 0.3s ease;
}

.tesla-menu-icon {
    font-size: 56rpx;
    color: var(--publicMainColor);
    line-height: 1;
    margin-bottom: 12rpx;
}

.tesla-menu-label {
    font-size: 24rpx;
    color: var(--tesla-text-primary);
    font-weight: 500;
}

/* ========== Tesla 风格区域容器 ========== */
.tesla-section {
    padding: 32rpx 24rpx;
    background: var(--tesla-bg-primary);
}

.tesla-section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24rpx;
}

.tesla-section-title {
    font-size: 36rpx;
    font-weight: 600;
    color: var(--tesla-text-primary);
    letter-spacing: 0.5rpx;
}

.tesla-section-more {
    font-size: 28rpx;
    color: var(--publicSubColor);
}

/* ========== Tesla 风格公告列表 ========== */
.tesla-news-list {
    background: var(--tesla-bg-secondary);
    border-radius: 16rpx;
    overflow: hidden;
}

.tesla-news-item {
    display: flex;
    align-items: center;
    padding: 28rpx 24rpx;
    position: relative;
    transition: background 0.2s ease;
}

.tesla-news-item:active {
    background: rgba(0, 0, 0, 0.02);
}

.tesla-news-item + .tesla-news-item::before {
    content: '';
    position: absolute;
    top: 0;
    left: 56rpx;
    right: 24rpx;
    height: 1rpx;
    background: var(--tesla-border);
}

.tesla-news-indicator {
    width: 6rpx;
    height: 6rpx;
    background: var(--publicMainColor);
    border-radius: 50%;
    margin-right: 20rpx;
    flex-shrink: 0;
}

.tesla-news-title {
    flex: 1;
    font-size: 30rpx;
    color: var(--tesla-text-primary);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.tesla-news-arrow {
    margin-left: 16rpx;
    color: var(--tesla-text-secondary);
    font-size: 28rpx;
}

/* ========== Tesla 风格商品列表 ========== */
.tesla-product-list {
    display: flex;
    gap: 16rpx;
    overflow-x: auto;
    padding-bottom: 8rpx;
}

.tesla-product-list::-webkit-scrollbar {
    display: none;
}

.tesla-product-card {
    flex-shrink: 0;
    width: 280rpx;
    background: var(--tesla-bg-secondary);
    border-radius: 16rpx;
    overflow: hidden;
    box-shadow: var(--tesla-card-shadow);
}

.tesla-product-image-wrapper {
    width: 100%;
    height: 280rpx;
    overflow: hidden;
    background: #F3F4F6;
}

.tesla-product-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.tesla-product-name {
    padding: 20rpx 16rpx;
    font-size: 28rpx;
    color: var(--tesla-text-primary);
    text-align: center;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* ========== Tesla 风格商家列表 ========== */
.tesla-merchant-list {
    display: flex;
    flex-wrap: wrap;
    gap: 16rpx;
}

.tesla-merchant-card {
    width: calc((100% - 32rpx) / 2);
    background: var(--tesla-bg-secondary);
    border-radius: 16rpx;
    overflow: hidden;
    box-shadow: var(--tesla-card-shadow);
}

.tesla-merchant-image-wrapper {
    width: 100%;
    aspect-ratio: 4/3;
    overflow: hidden;
    background: #F3F4F6;
}

.tesla-merchant-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.tesla-merchant-name {
    padding: 20rpx 16rpx;
    font-size: 28rpx;
    color: var(--tesla-text-primary);
    text-align: center;
    font-weight: 500;
}

/* ========== 隐藏旧样式 ========== */
.header, .menu, .listBox, .uni-product-list {
    display: none !important;
}
```

### Success Criteria:

#### Manual Verification:
- [ ] 菜单网格为 4 列布局，浅灰背景上白色卡片
- [ ] 菜单图标为 Tesla Red 颜色
- [ ] 公告列表为卡片式，左侧红色小圆点指示器
- [ ] 商品列表为横向滚动卡片布局
- [ ] 商家列表为双列卡片布局
- [ ] 所有卡片圆角为 16rpx
- [ ] 卡片阴影微妙可见

---

## Phase 5: 微动效添加

### Overview
为卡片添加悬浮效果和点击反馈动画，提升交互体验。

### Changes Required:

#### 1. 添加过渡动画样式

**File**: `uni-mall/pages/index/index.vue`

**新增样式:**
```css
/* ========== Tesla 风格微动效 ========== */

/* 菜单卡片悬浮效果 */
.tesla-menu-item {
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.tesla-menu-item:active {
    transform: scale(0.95);
}

/* 产品卡片悬浮效果 */
.tesla-product-card {
    transition: transform 0.2s ease;
}

.tesla-product-card:active {
    transform: scale(0.97);
}

/* 商家卡片悬浮效果 */
.tesla-merchant-card {
    transition: transform 0.2s ease;
}

.tesla-merchant-card:active {
    transform: scale(0.97);
}

/* 新闻项点击效果 */
.tesla-news-item {
    transition: background 0.2s ease;
}

/* 轮播图过渡效果优化 */
.tesla-swiper {
    transition: transform 0.3s ease-out;
}

/* 查看更多文字点击效果 */
.tesla-section-more {
    transition: opacity 0.2s ease;
}

.tesla-section-more:active {
    opacity: 0.6;
}
```

### Success Criteria:

#### Manual Verification:
- [ ] 点击菜单卡片有缩放效果
- [ ] 点击产品/商家卡片有缩放效果
- [ ] 点击"查看更多"有透明度变化
- [ ] 所有动画流畅无卡顿

---

## 测试策略

### 手动测试清单

#### 视觉测试:
- [ ] 整体色调符合 Tesla 风格（红色强调、蓝色次要、白色背景）
- [ ] 所有卡片圆角一致 (16rpx)
- [ ] 间距合理，有足够留白
- [ ] 文字清晰可读，对比度足够
- [ ] 阴影微妙不突兀

#### 功能测试:
- [ ] 轮播图自动播放正常
- [ ] 菜单点击跳转正常
- [ ] 公告点击跳转详情正常
- [ ] 商品点击跳转详情正常
- [ ] 商家点击跳转详情正常
- [ ] "查看更多"按钮跳转正常

#### 兼容性测试:
- [ ] 微信小程序显示正常
- [ ] 不同屏幕尺寸适配正常
- [ ] iOS 设备显示正常
- [ ] Android 设备显示正常

---

## Performance Considerations

- **样式优化**: 使用 CSS 变量减少重复代码
- **动画性能**: 仅使用 transform 和 opacity 动画，避免 layout 重排
- **图片优化**: 商品/商家图片使用懒加载
- **渲染优化**: 横向滚动列表使用虚拟列表（如需要）

---

## Migration Notes

### 回滚方案
如需回滚，保存以下文件备份：
- `uni-mall/utils/theme.css`
- `uni-mall/pages.json`
- `uni-mall/pages/index/index.vue`

### 版本兼容
- 确保微信开发者工具版本 >= 1.06.2307260
- uni-app 版本兼容性已验证

---

## References

- [Tesla App UI Design - Dribbble](https://dribbble.com/shots/25166247-Tesla-app-UI-Light-dark-mode)
- [2025年UI设计趋势 - 墨刀](https://modao.cc/ad/blog/2025-ui-design-trends.html)
- [2025年UI设计趋势 - 腾讯CoDesign](https://codesign.qq.com/hc/article/2025-design-trends/)
- [特斯拉小程序项目 - GitHub](https://github.com/Chihiro1221/tesla-miniprogram)
