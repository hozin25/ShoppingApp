<template>
    <view class="uni-padding-wrap">

        <!-- Tesla 风格轮播图 -->
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

        <!-- Tesla 风格菜单网格 -->
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


        <!-- Tesla 风格公告区域 -->
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
        <!-- Tesla 风格商品展示 -->
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
        <!-- Tesla 风格商家展示 -->
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


    </view>
</template>

<script>
    import menu from '@/utils/menu'
    import '@/assets/css/global-restaurant.css'
    import uniIcons from "@/components/uni-ui/lib/uni-icons/uni-icons.vue"
    export default {
        components: {
            uniIcons
        },
        data() {
            return {
                role:"",
                table:"",
                autoplaySwiper: true,
                intervalSwiper: 3000,
                //轮播
                swiperList: [],
                newsList: [],
                shangpinList: [],
                shangjiaList: [],
                menuList: [],
                swiperMenuList: [],
                iconArr: [
                    'cuIcon-same',
                    'cuIcon-deliver',
                    'cuIcon-evaluate',
                    'cuIcon-shop',
                    'cuIcon-ticket',
                    'cuIcon-cascades',
                    'cuIcon-discover',
                    'cuIcon-question',
                    'cuIcon-pic',
                    'cuIcon-filter',
                    'cuIcon-footprint',
                    'cuIcon-pulldown',
                    'cuIcon-pullup',
                    'cuIcon-moreandroid',
                    'cuIcon-refund',
                    'cuIcon-qrcode',
                    'cuIcon-remind',
                    'cuIcon-profile',
                    'cuIcon-home',
                    'cuIcon-message',
                    'cuIcon-link',
                    'cuIcon-lock',
                    'cuIcon-unlock',
                    'cuIcon-vip',
                    'cuIcon-weibo',
                    'cuIcon-activity',
                    'cuIcon-friendadd',
                    'cuIcon-friendfamous',
                    'cuIcon-friend',
                    'cuIcon-goods',
                    'cuIcon-selection'
                ],
            }
        },
        computed: {
            baseUrl() {
                return this.$base.url;
            }
        },
        async onLoad() {
            let _this = this
            _this.role = uni.getStorageSync("role");
            _this.table = uni.getStorageSync("nowTable");
            let res = await _this.$api.session(_this.table);
            _this.user = res.data;
            _this.tableName = _this.table;
            let menus = menu.list();
            _this.menuList = menus;
            _this.menuList.forEach((item, key) => {
                if (_this.role == item.roleName) {
                    item.backMenu.forEach((item2, key2) => {
                        if (item2.child[0].buttons.indexOf("查看") > -1) {
                            _this.swiperMenuList.push(item2);
                        }
                    })
                }
            })
        },
        async onShow() {
            // 轮播图
            let swiperList = []
            let res = await this.$api.page('config', {
                page: 1,
                limit: 5
            });
            for (let item of res.data.list) {
                if (item.value && item.value!="" && item.value!=null ) {
                    swiperList.push({
                        img: item.value
                    });
                }
            }
            if (swiperList) {
                this.swiperList = swiperList;
                console.log('轮播图数量:', this.swiperList.length);
                console.log('autoplaySwiper:', this.autoplaySwiper);
                console.log('intervalSwiper:', this.intervalSwiper);
            }
            let news = await this.$api.list('news', {
                page: 1,
                limit: 6,
                });

            this.newsList = news.data.list
            this.newsList.forEach(function(item, index) {
                if(item.newsContent != null && item.newsContent != "" && item.newsContent != "null"){
                    item.newsContent =item.newsContent.replace(/<img [^>]*src=['"]([^'"]+)[^>]*>/gi,"");//替换图片
                }
            });

            let val = [
                {
                    key:'page',
                    val:1
                },
                {
                    key:'limit',
                    val:6
                },
            ]
            let shangpin = await this.$api.requestCondition('shangpin','gexingtuijian',val);

            this.shangpinList = shangpin.data.list
            this.shangpinList.forEach(function(item, index) {
                if(item.shangpinContent != null && item.shangpinContent != "" && item.shangpinContent != "null"){
                    item.shangpinContent =item.shangpinContent.replace(/<img [^>]*src=['"]([^'"]+)[^>]*>/gi,"");//替换图片
                }
            });

            let shangjia = await this.$api.list('shangjia', {
                page: 1,
                limit: 6,
                });

            this.shangjiaList = shangjia.data.list
            this.shangjiaList.forEach(function(item, index) {
                if(item.shangjiaContent != null && item.shangjiaContent != "" && item.shangjiaContent != "null"){
                    item.shangjiaContent =item.shangjiaContent.replace(/<img [^>]*src=['"]([^'"]+)[^>]*>/gi,"");//替换图片
                }
            });

        },

        methods: {
            onPageTap2(url) {
                uni.setStorageSync("useridTag", 0);
                uni.navigateTo({
                    url: url,
                    fail: function () {
                        uni.switchTab({
                            url: url
                        });
                    }
                });
            },
            //轮播图跳转
            onSwiperTap(e) {

            },
            // 新闻详情
            onNewsDetailTap(id) {
                this.$utils.jump(`../news/detail?id=${id}`)
            },
            // 推荐列表点击详情
            onDetailTap(tableName, id) {
                this.$utils.jump(`../${tableName}/detail?id=${id}`)
            },
            onPageTap(tableName){

                uni.navigateTo({
                    url: `../${tableName}/list`,
                    fail: function(){
                        uni.switchTab({
                            url: `../${tableName}/list`
                        });
                    }
                });
            }
        }
    }
</script>

<style>
    page {
        background: #F8F8F8;
    }

    .uni-padding-wrap:after {
        position: fixed;
        top: 0;
        right: 0;
        left: 0;
        bottom: 0;
        content: '';
        background-attachment: fixed;
        background-size: cover;
        background-position: center;
    }

    view {
        /* font-family: '\5FAE\8F6F\96C5\9ED1'; */
        font-size: 30upx;
    }

    .header {
        background: #EEEEEE;
        padding: 0 0 300upx 0;
        margin-bottom: 20upx;
        position: relative;
    }

    .ssbox {
        background: rgba(255, 255, 255, 0.35);
        width: 530upx;
        border-radius: 60rpx;
        padding: 10upx 15upx;
        box-sizing: border-box;
    }

    .ss_input {
        border: none;
        width: 450upx;
        font-size: 30upx;
        color: #fff;
        background: none;
        height: 45upx;
        line-break: 45upx;
    }

    .headerb {
        position: absolute;
        left: 0;
        width: 100%;
        box-sizing: border-box;
    }

    .headerb image {
        width: 100%;
        position: relative;
        z-index: 10;
    }

    .headerb .swiper {
        height: 300upx;
    }

    .swiper /deep/ .uni-swiper-dot {
        width: 16rpx;
        height: 16rpx;
        broder-radius: 50%;
    }


    .notice {
        position: relative;
        z-index: 5;
        padding: 0 50upx;
    }

    .noticem {
        background: #fff;
        padding: 55upx 30upx 15upx;
        border-radius: 10upx;
        margin-top: -45upx;
    }

    .noticer {
        width: 480upx;
        height: 50upx;
    }

    .noticer .swiper-item {
        white-space: nowrap;
        text-overflow: ellipsis;
        overflow: hidden;
        height: 50upx;
        line-height: 50upx;
        font-size: 24upx;
    }

    .list {
        padding: 20upx 20upx 20upx;
    }

    .listm {
        background: #fff;
        border-radius: 15upx;
        box-shadow: 0 0 2upx rgba(0, 0, 0, 0.1);
        margin-bottom: 20upx;
        padding: 30upx;
    }

    .listmpic {
        border-radius: 10upx;
        width: 166upx;
        margin-right: 20upx;
    }

    .listmr {
         width: 460upx;
        display: inline-block;
        flex: 1;
        display: flex;
        justify-content: space-between;
        flex-direction: column;
    }

    /* #ifdef MP-WEIXIN */
    .noticer .swiper-item {
        margin-top: 5upx;
    }

    /* #endif */
    /* #ifdef MP-BAIDU */
    .noticer .swiper-item {
        margin-top: 3upx;
    }

    /* #endif */
    /* #ifdef MP-ALIPAY */
    .noticer .swiper-item {
        margin-top: 2upx;
    }

    /* #endif */
    /* #ifdef MP-QQ */
    .noticer .swiper-item {
        margin-top: 4upx;
    }

    /* #endif */
    /* #ifdef MP-TOUTIAO */
    .noticer .swiper-item {
        margin-top: 4upx;
    }

    /* #endif */

    .uni-product-list {
        display: flex;
        width: 100%;
        flex-wrap: wrap;
        flex-direction: row;
        margin-top: 0;
        padding: 0 14upx;
        box-sizing: border-box;
    }

    .uni-product-list.active {
        padding: 0 12upx;
    }

    .uni-product {
        padding: 10upx;
        margin: 10upx;
        width: 341upx;
        box-sizing: border-box;
        display: flex;
        flex-direction: column;
        background: #FFFFFF;
    }

    .uni-product-list.active .uni-product {
        width: 222upx;
    }

    .image-view {
        height: 321upx;
        width: 321upx;
         margin: 12upx 0;
        display: flex;
        align-items: center;
        overflow: hidden;
    }

    .uni-product-list.active .image-view {
        height: 202upx;
        width: 202upx;
        overflow: hidden;
    }

    .uni-product-image {
        height: 100%;
        width: 100%;
        margin: 0 auto;
        display: block;
    }

    .uni-product-title {
        width: 100%;
        word-break: break-all;
        display: -webkit-box;
        overflow: hidden;
        line-height: 1.5;
        text-overflow: ellipsis;
        -webkit-box-orient: vertical;
        -webkit-line-clamp: 1;
    }

    .uni-product-price {
        width: 100%;
        margin-top: 10upx;
        font-size: 28upx;
        line-height: 1.5;
        position: relative;
    }

    .uni-product-price-original {
        color: #e80080;
    }

    .uni-product-price-favour {
        color: #888888;
        text-decoration: line-through;
        margin-left: 10upx;
    }

    .uni-product-tip {
        position: absolute;
        right: 10upx;
        background-color: #ff3333;
        color: #ffffff;
        padding: 0 10upx;
        border-radius: 5upx;
    }

    .header-title {
        display: flex;
        align-items: center;
        text-align: center;
        justify-content: space-between;
        padding: 0 40upx;
    }

    /* 11111111 */
    .listBox>.title {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .list-box .box {
        position: relative;
    }

    .listBox .list-box .box .title {
        position: absolute;
        left: 0;
        bottom: 0;
        z-index: 1;
    }

    .listBox .style1 {
        display: flex;
        justify-content: space-between;
        flex-wrap: wrap;
    }

    .listBox .style2 {
        display: flex;
        justify-content: space-between;
        flex-wrap: wrap;
    }

    .listBox .style3 .list-item {
        display: flex;
    }

    .listBox .style4 .list-item {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .style6 .list-item {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .style6 .list-item .list-item-body {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .style7 .list-item {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .style8 .list-item {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .style9 .list-item {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .idea {
        display: flex;
        flex-wrap: wrap;
    }

    .listBox .idea .box {
        display: flex;
        justify-content: center;
        align-items: center;
        background-repeat: no-repeat;
        background-size: 100% 100%;
    }

    .iconarr {
        text-align: center;
        line-height: 80 rpx;
    }

    .news-box6 .dian::before {
        content: "";
        display: block;
        width: 8 upx;
        height: 8 upx;
        background-color: red;
        position: absolute;
        top: -4 upx;
        left: 50%;
        transform: translateX(-50%);
        border-radius: 100%;
        z-index: 1;
    }

    .hide1 {
        overflow: hidden;
        text-overflow: ellipsis;
        display: -webkit-box;
        -webkit-line-clamp: 1;
        line-clamp: 1;
        -webkit-box-orient: vertical;
    }

    .hide2 {
        overflow: hidden;
        text-overflow: ellipsis;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        line-clamp: 2;
        -webkit-box-orient: vertical;
    }

    .hide3 {
        overflow: hidden;
        text-overflow: ellipsis;
        display: -webkit-box;
        -webkit-line-clamp: 3;
        line-clamp: 3;
        -webkit-box-orient: vertical;
    }

    .hide4 {
        overflow: hidden;
        text-overflow: ellipsis;
        display: -webkit-box;
        -webkit-line-clamp: 4;
        line-clamp: 4;
        -webkit-box-orient: vertical;
    }

    /* ========== Tesla 风格全局样式 ========== */
    page {
        background: var(--tesla-bg-primary);
    }

    .uni-padding-wrap {
        padding: 0;
    }

    /* ========== Tesla 风格轮播图样式 ========== */
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

    /* ========== 隐藏旧样式 ========== */
    .header, .menu, .listBox, .uni-product-list {
        display: none !important;
    }
</style>
