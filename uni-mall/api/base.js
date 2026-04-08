// 根据环境自动切换服务器地址
const isDev = process.env.NODE_ENV === 'development'

const base = {
    // 开发环境使用本地服务器
    devUrl: "http://localhost:8080/zhinengxiaochengxsc/",
    // 生产环境使用线上服务器
    prodUrl: "http://47.83.117.201:8080/zhinengxiaochengxsc/",
    // 当前使用的URL（根据环境自动选择）
    get url() {
        return isDev ? this.devUrl : this.prodUrl
    }
}

export default base
