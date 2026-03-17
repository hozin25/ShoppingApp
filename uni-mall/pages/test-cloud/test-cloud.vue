<template>
	<view class="content">
		<view class="title">云开发测试页面</view>

		<view class="section">
			<view class="section-title">1. 测试基础调用</view>
			<button @click="testHello">调用 Hello 接口</button>
			<view class="result" v-if="helloResult">
				<text>{{ helloResult }}</text>
			</view>
		</view>

		<view class="section">
			<view class="section-title">2. 测试获取用户信息</view>
			<button @click="testGetUserInfo">获取用户 OpenID</button>
			<view class="result" v-if="userInfoResult">
				<text>{{ userInfoResult }}</text>
			</view>
		</view>

		<view class="section">
			<view class="section-title">3. 测试计算功能</view>
			<view class="input-group">
				<input type="number" v-model="num1" placeholder="数字1" />
				<text>+</text>
				<input type="number" v-model="num2" placeholder="数字2" />
			</view>
			<button @click="testAdd">计算</button>
			<view class="result" v-if="addResult">
				<text>{{ addResult }}</text>
			</view>
		</view>

		<view class="section">
			<view class="section-title">云函数状态</view>
			<view class="status">{{ cloudStatus }}</view>
		</view>
	</view>
</template>

<script>
export default {
	data() {
		return {
			cloudStatus: '初始化中...',
			helloResult: '',
			userInfoResult: '',
			addResult: '',
			num1: 0,
			num2: 0
		}
	},

	onLoad() {
		this.initCloud()
	},

	methods: {
		// 初始化云开发
		initCloud() {
			if (!wx.cloud) {
				this.cloudStatus = '请使用微信开发者工具预览'
				return
			}

			// 初始化云开发
			wx.cloud.init({
				env: 'cloudbase-4g79jfxf7a19c733', // 替换为你的云环境 ID
				traceUser: true
			})

			this.cloudStatus = '云开发已初始化 ✓'
			uni.showToast({
				title: '云开发初始化成功',
				icon: 'success'
			})
		},

		// 测试 Hello 接口
		testHello() {
			uni.showLoading({ title: '调用中...' })

			wx.cloud.callFunction({
				name: 'getData',
				data: {
					action: 'hello',
					data: {
						message: '来自 uni-app 的调用'
					}
				}
			}).then(res => {
				uni.hideLoading()
				console.log('云函数返回：', res)
				this.helloResult = JSON.stringify(res.result, null, 2)

				uni.showToast({
					title: '调用成功',
					icon: 'success'
				})
			}).catch(err => {
				uni.hideLoading()
				console.error('调用失败：', err)
				this.helloResult = '错误：' + err.errMsg

				uni.showToast({
					title: '调用失败',
					icon: 'none'
				})
			})
		},

		// 测试获取用户信息
		testGetUserInfo() {
			uni.showLoading({ title: '获取中...' })

			wx.cloud.callFunction({
				name: 'getData',
				data: {
					action: 'getUserInfo'
				}
			}).then(res => {
				uni.hideLoading()
				console.log('用户信息：', res)
				this.userInfoResult = JSON.stringify(res.result, null, 2)

				uni.showToast({
					title: '获取成功',
					icon: 'success'
				})
			}).catch(err => {
				uni.hideLoading()
				console.error('获取失败：', err)
				this.userInfoResult = '错误：' + err.errMsg

				uni.showToast({
					title: '获取失败',
					icon: 'none'
				})
			})
		},

		// 测试计算
		testAdd() {
			uni.showLoading({ title: '计算中...' })

			wx.cloud.callFunction({
				name: 'getData',
				data: {
					action: 'add',
					data: {
						a: Number(this.num1) || 0,
						b: Number(this.num2) || 0
					}
				}
			}).then(res => {
				uni.hideLoading()
				console.log('计算结果：', res)
				this.addResult = `${this.num1} + ${this.num2} = ${res.result.data.result}`

				uni.showToast({
					title: '计算成功',
					icon: 'success'
				})
			}).catch(err => {
				uni.hideLoading()
				console.error('计算失败：', err)
				this.addResult = '错误：' + err.errMsg

				uni.showToast({
					title: '计算失败',
					icon: 'none'
				})
			})
		}
	}
}
</script>

<style scoped>
.content {
	padding: 20rpx;
}

.title {
	font-size: 40rpx;
	font-weight: bold;
	text-align: center;
	margin-bottom: 40rpx;
	color: #333;
}

.section {
	background: #fff;
	border-radius: 10rpx;
	padding: 30rpx;
	margin-bottom: 20rpx;
	box-shadow: 0 2rpx 10rpx rgba(0, 0, 0, 0.1);
}

.section-title {
	font-size: 32rpx;
	font-weight: bold;
	margin-bottom: 20rpx;
	color: #666;
}

button {
	margin-bottom: 20rpx;
	background: #007AFF;
	color: #fff;
}

.input-group {
	display: flex;
	align-items: center;
	margin-bottom: 20rpx;
}

.input-group input {
	flex: 1;
	border: 1rpx solid #ddd;
	border-radius: 8rpx;
	padding: 15rpx;
	margin: 0 10rpx;
	text-align: center;
}

.input-group text {
	font-size: 32rpx;
	font-weight: bold;
}

.result {
	background: #f5f5f5;
	border-radius: 8rpx;
	padding: 20rpx;
	margin-top: 20rpx;
	font-size: 24rpx;
	line-height: 1.6;
	word-break: break-all;
}

.status {
	padding: 20rpx;
	background: #e8f5e9;
	border-radius: 8rpx;
	color: #4caf50;
	font-size: 28rpx;
	text-align: center;
}
</style>
