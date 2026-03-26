// 云函数入口文件
const cloud = require('wx-server-sdk')

cloud.init({
  env: cloud.DYNAMIC_CURRENT_ENV
})

// 云函数入口函数
exports.main = async (event, context) => {
  // event 包含调用云函数时传递的参数
  const { action, data } = event

  console.log('云函数被调用，参数：', event)

  try {
    switch (action) {
      case 'hello':
        return {
          code: 200,
          message: '云函数调用成功',
          data: {
            text: 'Hello from cloud function!',
            timestamp: Date.now(),
            receivedData: data
          }
        }

      case 'getUserInfo':
        // 示例：获取用户信息
        const wxContext = cloud.getWXContext()
        return {
          code: 200,
          message: '获取用户信息成功',
          data: {
            openid: wxContext.OPENID,
            appid: wxContext.APPID,
            unionid: wxContext.UNIONID
          }
        }

      case 'add':
        // 示例：简单的计算
        const { a, b } = data
        return {
          code: 200,
          message: '计算成功',
          data: {
            result: a + b
          }
        }

      default:
        return {
          code: 400,
          message: '未知的操作类型',
          data: null
        }
    }
  } catch (error) {
    console.error('云函数执行出错：', error)
    return {
      code: 500,
      message: '服务器错误',
      error: error.message
    }
  }
}
