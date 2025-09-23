<template>
    <view class="content">
        <form>
            <!-- 收货地址选择区域 -->
            <view @tap="onAddressTap" class="cu-form-group">
                <view class="title">地址</view>
                <view v-if="addresszhi != null" style="height: auto;width: 600rpx;">
                    {{addresszhi.addressDizhi}}（{{addresszhi.addressName}} 收） {{addresszhi.addressPhone}}
                </view>
                <view v-else>
                选择地址
                </view>
            </view>
            <!-- 商品购买清单展示区域 -->
            <view class="cu-form-group">
                <view class="title">购买清单</view>
            </view>
            <!-- 循环展示每个商品信息 -->
            <view v-for="(item,index) in orderGoods " v-bind:key="index" class="cu-form-group">
                <image class="avator" :src="baseUrl+item.shangpinPhoto" mode=""></image>
                <view class="title" style="width: 75%;">
                    <view style="margin-top: -50rpx;">{{item.shangpinName}}</view>
                    <view >
                        x{{item.buyNumber}}
                        <text style="margin-left: 30upx;color: red;">￥{{item.shangpinNewMoney}}</text>
                    </view>
                </view>
            </view>
            <!-- 订单总价展示区域 -->
            <view @tap="onAddressTap" class="cu-form-group">
                <view class="title">总价</view>
                <view>
                    <!-- 根据支付类型显示不同的价格信息 -->
                    <text v-if="shangpinOrderPaymentTypes == 1">原价：￥{{(maxNewMouey).toFixed(2)}}</text>
                    <view v-if="shangpinOrderPaymentTypes == 1"></view>
                    <text v-if="shangpinOrderPaymentTypes == 1">折扣价：￥{{(maxNewMouey * zhekou).toFixed(2)}}</text>
                    <text v-if="shangpinOrderPaymentTypes == 2">{{(maxNewMouey).toFixed(2)}}积分</text>
                </view>
            </view>
        </form>
        <!-- 确认支付按钮 -->
        <view class="padding" style="text-align: center;">
            <button @tap="onSubmitTap()" class="bg-red lg">确认支付</button>
        </view>
    </view>
</template>

<script>
    export default {
        data() {
            return {
                user: {},//登录用户信息
                orderGoods: [],//订单商品列表
                maxNewMouey: 0,//订单总价格
                addresszhi: {},//选中的收货地址
                shangpinOrderPaymentTypes:1,//支付类型：1-余额支付，2-积分支付
                zhi:[
                    {
                        id:1,
                        val:"余额"
                    },
                    {
                        id:2,
                        val:"积分"
                    },
                ],
                zhekou:1,//会员折扣率
            }
        },
        computed: {
            // 获取基础URL，用于图片显示
            baseUrl() {
                return this.$base.url;
            },
        },
        async onLoad(options) {
            // 页面加载时获取订单商品信息并计算总价
            this.orderGoods = uni.getStorageSync('orderGoods');
            if(this.orderGoods.length>0){
                for (let i = 0; i < this.orderGoods.length; i++) {
                    this.maxNewMouey = this.maxNewMouey + parseFloat(this.orderGoods[i].shangpinNewMoney) * this.orderGoods[i].buyNumber
                }
            }
            uni.removeStorageSync("orderGoods")
        },
        async onShow() {
            let _this = this
            // 获取当前登录用户信息
            let table = uni.getStorageSync("nowTable");
            let userRes = await _this.$api.session(table)
            _this.user = userRes.data

            // 获取会员等级对应的折扣信息
            let huiyuandengjiTypesRes = await _this.$api.page("dictionary",{
                dicCode: "huiyuandengji_types",
                dicName: "会员等级类型",
                codeIndexStart: _this.user.huiyuandengjiTypes,
                codeIndexEnd: _this.user.huiyuandengjiTypes,
            })
            if(huiyuandengjiTypesRes.data.list.length >0){
                _this.zhekou = Number(huiyuandengjiTypesRes.data.list[0].beizhu);
            }

            // 获取收货地址信息
            let address = uni.getStorageSync('address')
            uni.removeStorageSync("address")
            if(address != null && address != ""){
                _this.addresszhi = address
            }else{
                // 如果没有选择的地址，则获取默认地址
                address = await _this.$api.list('address',{
                    yonghuId: _this.user.id,
                    isdefaultTypes: 2
                });
                if(address.data.list.length > 0){
                    _this.addresszhi = address.data.list[0]
                }else{
                    _this.addresszhi = null
                }
            }
        },
        methods: {
            // 提交订单方法
            async onSubmitTap() {
                let _this = this;
                let table = uni.getStorageSync("nowTable");
                uni.showModal({
                    title: '提示',
                    content: '是否确认支付',
                    success: async function(res) {
                        if (res.confirm) {
                            // 验证是否选择了收货地址
                            if(_this.addresszhi == null){
                                _this.$utils.msg('请选择地址');
                                return
                            }
                            // 构建订单数据
                            let data = {
                                addressId: _this.addresszhi.id,
                                shangpins: JSON.stringify(_this.orderGoods),
                                yonghuId: _this.user.id,
                                shangpinOrderPaymentTypes:  _this.shangpinOrderPaymentTypes,
                            }
                            // 提交订单请求
                            await _this.$api.requestConditionDataGet('shangpinOrder','order',null,data);
                            // 跳转到订单列表页面
                            _this.$utils.jump('/pages/shangpinOrder/list');
                        }
                    }
                });
            },
            // 跳转到地址选择页面
            async onAddressTap() {
                let _this = this
                _this.$utils.jump('/pages/address/list');
            }
        }
    }
</script>

<style lang="scss">
    // 商品图片样式
    .avator {
        width: 150upx;
        height: 150upx;
        margin: 20upx 0;
    }
</style>
