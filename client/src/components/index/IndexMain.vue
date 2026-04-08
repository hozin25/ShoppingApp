<template>
	<el-main class="main-container">
		<bread-crumbs :title="title" class="bread-crumbs"></bread-crumbs>
		<router-view class="router-view"></router-view>
	</el-main>
</template>
<script>
	import menu from "@/utils/menu";
	export default {
		data() {
			return {
				menuList: [],
				role: "",
				currentIndex: -2,
				itemMenu: [],
				title: ''
			};
		},
		mounted() {
			let menus = menu.list();
			this.menuList = menus;
			this.role = this.$storage.get("role");
		},
		methods: {
			menuHandler(menu) {
				this.$router.push({
					name: menu.tableName
				});
				this.title = menu.menu;
			},
			titleChange(index, menus) {
				this.currentIndex = index
				this.itemMenu = menus;
				console.log(menus);
			},
			homeChange(index) {
				this.itemMenu = [];
				this.title = ""
				this.currentIndex = index
				this.$router.push({
					name: 'home'
				});
			},
			centerChange(index) {
				this.itemMenu = [{
					"buttons": ["新增", "查看", "修改", "删除"],
					"menu": "修改密码",
					"tableName": "updatePassword"
				}, {
					"buttons": ["新增", "查看", "修改", "删除"],
					"menu": "个人信息",
					"tableName": "center"
				}];
				this.title = ""
				this.currentIndex = index
				this.$router.push({
					name: 'home'
				});
			}
		}
	};
</script>
<style lang="scss" scoped>
	a {
		text-decoration: none;
		color: #555;
	}

	a:hover {
		background: #00c292;
	}

	.nav-list {
		width: 100%;
		margin: 0 auto;
		text-align: left;
		margin-top: 20px;

		.nav-title {
			display: inline-block;
			font-size: 15px;
			color: #333;
			padding: 15px 25px;
			border: none;
		}

		.nav-title.active {
			color: #555;
			cursor: default;
			background-color: #fff;
		}
	}

	.nav-item {
		margin-top: 20px;
		background: #FFFFFF;
		padding: 15px 0;

		.menu {
			padding: 15px 25px;
		}
	}

	.main-container {
		background: linear-gradient(135deg, rgba(245, 247, 250, 0.95) 0%, rgba(230, 240, 255, 0.9) 50%, rgba(245, 250, 255, 0.95) 100%);
		background-attachment: fixed;
		padding: 0 24px;
		position: relative;
		min-height: calc(100vh - 60px);

		// 添加浮动装饰元素
		&::before {
			content: '';
			position: fixed;
			width: 600px;
			height: 600px;
			background: radial-gradient(circle, rgba(100, 126, 255, 0.03) 0%, transparent 70%);
			border-radius: 50%;
			top: -300px;
			right: -200px;
			pointer-events: none;
			animation: float 25s infinite ease-in-out;
		}

		&::after {
			content: '';
			position: fixed;
			width: 500px;
			height: 500px;
			background: radial-gradient(circle, rgba(66, 211, 146, 0.03) 0%, transparent 70%);
			border-radius: 50%;
			bottom: -250px;
			left: -150px;
			pointer-events: none;
			animation: float 20s infinite ease-in-out reverse;
		}

		@keyframes float {
			0%, 100% {
				transform: translate(0, 0) scale(1);
			}
			50% {
				transform: translate(30px, 30px) scale(1.05);
			}
		}
	}

	.router-view {
		padding: 20px;
		margin-top: 10px;
		background: rgba(255, 255, 255, 0.65);
		backdrop-filter: blur(10px);
		-webkit-backdrop-filter: blur(10px);
		border-radius: 16px;
		border: 1px solid rgba(255, 255, 255, 0.8);
		box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
		box-sizing: border-box;
		min-height: calc(100vh - 100px);
		position: relative;
		z-index: 1;
	}

	.bread-crumbs {
		width: 100%;
		// border-bottom: 1px solid #e9eef3;
		// border-top: 1px solid #e9eef3;
		margin-top: 10px;
		box-sizing: border-box;
		position: relative;
		z-index: 1;
	}
</style>
