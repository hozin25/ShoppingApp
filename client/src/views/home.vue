<template>
<div class="content">
  <!--  <div style="width: 100%;height: 100%" v-if="sessionTable!='users'">-->
  <div class="glass-container">
    <div class="glass-card welcome-card">
      <div class="welcome-icon">🎉</div>
      <div class="text main-text">欢迎使用 {{this.$project.projectName}}</div>
      <div class="text sub-text">智能电商管理系统</div>
    </div>
  </div>
  <div style="width: 100%;height: 100%;display:flex " v-if="sessionTable=='users' && false">
    <div style="width: 50%;height: 100%">
        <div id="statistic1" style="width:100%;height:600px;"></div>
    </div>
    <div style="width: 50%;height: 100%">
      <el-date-picker
          v-model="echartsDate"
          type="month"
          placeholder="选择月">
      </el-date-picker>
      <el-button @click="chartDialog2()">查询</el-button>
        <div id="statistic2" style="width:100%;height:600px;"></div>
    </div>
  </div>

</div>
</template>
<script>
import router from '@/router/router-static'
export default {
  data() {
    return {
      sessionTable : "",//登录账户所在表名
      role : "",//权限
      userId:"",//当前登录人的id

      echartsDate: new Date(),//echarts的时间查询字段


    };
  },
  mounted(){

    //获取当前登录用户的信息
    this.sessionTable = this.$storage.get("sessionTable");
    this.role = this.$storage.get("role");
    this.userId = this.$storage.get("userId");

    this.init();
    this.chartDialog1();
    this.chartDialog2();
  },
  methods:{
    chartDialog1() {
      let _this = this;
      // this.$nextTick(()=>{
      //   var statistic = this.$echarts.init(document.getElementById("statistic1"),'macarons');
      //   let params = {
      //     tableName: "wuzi",
      //     groupColumn: "wuzi_types",
      //   }
      //   this.$http({
      //     url: "newSelectGroupCount",//pieSum pieCount
      //     method: "get",
      //     params: params
      //   }).then(({data}) => {
      //     if (data && data.code === 0) {
      //       let res = data.data;
      //       let xAxis = [];
      //       let yAxis = [];
      //       let pArray = []
      //       var option = {};
      //       for(let i=0;i<res.length;i++){
      //         xAxis.push(res[i].name);
      //         yAxis.push(res[i].value);
      //         pArray.push({
      //           value: res[i].value,
      //           name: res[i].name
      //         })
      //         option = {
      //           title: {
      //             text: '物资类型分布图',
      //             left: 'center'
      //           },
      //           tooltip: {
      //             trigger: 'item',
      //             formatter: '{b} : {c} ({d}%)'
      //           },
      //           legend: {
      //             orient: 'vertical',
      //             left: 'left'
      //           },
      //           series: [
      //             {
      //               type: 'pie',
      //               radius: '55%',
      //               center: ['50%', '60%'],
      //               data: pArray,
      //               emphasis: {
      //                 itemStyle: {
      //                   shadowBlur: 10,
      //                   shadowOffsetX: 0,
      //                   shadowColor: 'rgba(0, 0, 0, 0.5)'
      //                 }
      //               }
      //             }
      //           ]
      //         };
      //       }
      //       statistic.setOption(option,true);
      //       window.onresize = function() {
      //         statistic.resize();
      //       };
      //     }
      //   });
      // })

      // let params = {
      //   dateFormat :"%Y", //%Y-%m
      //   riqi :getYearFormat(_this.echartsDate),//年
      //   // riqi :getMonthFormat(_this.echartsDate),//年月
      //   thisTable : {//当前表
      //     tableName :'shangpin',//当前表表名,
      //     sumColum : 'shangpin_number', //求和字段
      //     date : 'insert_time',//分组日期字段
      //     // string : 'shangpin_name',//分组字符串字段
      //     // types : 'shangpin_types',//分组下拉框字段
      //   },
      //   // joinTable : {//级联表（可以不存在）
      //   //     tableName :'yonghu',//级联表表名
      //   //     // date : 'insert_time',//分组日期字段
      //   //     string : 'yonghu_name',//分组字符串字段
      //   //     // types : 'yonghu_types',//分组下拉框字段
      //   // }
      // }
      // _this.chartVisiable = true;
      // _this.$nextTick(() => {
      //   var statistic = this.$echarts.init(document.getElementById("statistic1"), 'macarons');
      //   this.$http({
      //     url: "barSum",//barCountOne barCountTwo barSumOne barSumTwo
      //     method: "get",
      //     params: params
      //   }).then(({data}) => {
      //     if(data && data.code === 0){
      //       let yAxisName = "数值";//y轴
      //       let xAxisName = "月份";//x轴
      //       let series = [];//具体数据值
      //       data.data.yAxis.forEach(function (item,index) {//点击可关闭的按钮字符串在后台方法中
      //         let tempMap = {};
      //         tempMap.name=data.data.legend[index];
      //         tempMap.type='bar';
      //         tempMap.data=item;
      //         series.push(tempMap);
      //       })
      //
      //       var option = {
      //         tooltip: {
      //           trigger: 'axis',
      //           axisPointer: {
      //             type: 'cross',
      //             crossStyle: {
      //               color: '#999'
      //             }
      //           }
      //         },
      //         toolbox: {
      //           feature: {
      //             // dataView: { show: true, readOnly: false },  // 数据查看
      //             magicType: { show: true, type: ['line', 'bar'] },//切换图形展示方式
      //             // restore: { show: true }, // 刷新
      //             saveAsImage: { show: true }//保存
      //           }
      //         },
      //         legend: {
      //           data: data.data.legend//标题  可以点击导致某一列数据消失
      //         },
      //         xAxis: [
      //           {
      //             type: 'category',
      //             axisLabel:{interval: 0},
      //             name: xAxisName,
      //             data: data.data.xAxis,
      //             axisPointer: {
      //               type: 'shadow'
      //             }
      //           }
      //         ],
      //         yAxis: [
      //           {
      //             type: 'value',//不能改
      //             name: yAxisName,//y轴单位
      //             axisLabel: {
      //               formatter: '{value}' // 后缀
      //             }
      //           }
      //         ],
      //         series:series//具体数据
      //       };
      //       statistic.setOption(option,true);
      //       window.onresize = function () {
      //         statistic.resize();
      //       };
      //     }else {
      //       this.$message({
      //         message: "报表未查询到数据",
      //         type: "success",
      //         duration: 1500,
      //         onClose: () => {
      //           this.search();
      //         }
      //       });
      //     }
      //   });
      // });


    },
    chartDialog2() {
      let _this = this;
      // this.$nextTick(()=>{
      //   var statistic = this.$echarts.init(document.getElementById("statistic2"),'macarons');
      //
      //   var year = _this.echartsDate.getFullYear();
      //   var month = _this.echartsDate.getMonth() + 1 < 10 ? '0' + (_this.echartsDate.getMonth() + 1) : _this.echartsDate.getMonth() + 1;
      //   var riqi=year + "-" + month;
      //
      //   this.$http({
      //     url: "pieSum",//pieSum pieCount
      //     method: "get",
      //     params: {
      //       riqi :riqi
      //     }
      //   }).then(({data}) => {
      //     if (data && data.code === 0) {
      //       let res = data.data;
      //       let xAxis = [];
      //       let yAxis = [];
      //       let pArray = []
      //       var option = {};
      //       for(let i=0;i<res.length;i++){
      //         xAxis.push(res[i].name);
      //         yAxis.push(res[i].value);
      //         pArray.push({
      //           value: res[i].value,
      //           name: res[i].name
      //         })
      //         option = {
      //           title: {
      //             text: '物资月度申请统计报表',
      //             left: 'center'
      //           },
      //           tooltip: {
      //             trigger: 'item',
      //             formatter: '{b} : {c} ({d}%)'
      //           },
      //           legend: {
      //             orient: 'vertical',
      //             left: 'left'
      //           },
      //           series: [
      //             {
      //               type: 'pie',
      //               radius: '55%',
      //               center: ['50%', '60%'],
      //               data: pArray,
      //               emphasis: {
      //                 itemStyle: {
      //                   shadowBlur: 10,
      //                   shadowOffsetX: 0,
      //                   shadowColor: 'rgba(0, 0, 0, 0.5)'
      //                 }
      //               }
      //             }
      //           ]
      //         };
      //       }
      //       statistic.setOption(option,true);
      //       window.onresize = function() {
      //         statistic.resize();
      //       };
      //     }
      //   });
      // })
    },
    init(){
        if(this.$storage.get('Token')){
        this.$http({
            url: `${this.$storage.get('sessionTable')}/session`,
            method: "get"
        }).then(({ data }) => {
            if (data && data.code != 0) {
            router.push({ name: 'login' })
            }
        });
        }else{
            router.push({ name: 'login' })
        }
    }
  }
};
</script>

<style lang="scss" scoped>
.content {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  min-height: 500px;
  text-align: center;
  background: transparent;
  position: relative;
  overflow: hidden;

  // 添加背景装饰
  &::before {
    content: '';
    position: absolute;
    width: 500px;
    height: 500px;
    background: radial-gradient(circle, rgba(100, 126, 255, 0.04) 0%, transparent 70%);
    border-radius: 50%;
    top: -250px;
    right: -250px;
    animation: float 20s infinite ease-in-out;
  }

  &::after {
    content: '';
    position: absolute;
    width: 400px;
    height: 400px;
    background: radial-gradient(circle, rgba(66, 211, 146, 0.04) 0%, transparent 70%);
    border-radius: 50%;
    bottom: -200px;
    left: -200px;
    animation: float 15s infinite ease-in-out reverse;
  }

  @keyframes float {
    0%, 100% {
      transform: translate(0, 0) scale(1);
    }
    50% {
      transform: translate(50px, 50px) scale(1.1);
    }
  }
}

.glass-container {
  position: relative;
  z-index: 1;
  padding: 20px;
}

.glass-card {
  background: rgba(255, 255, 255, 0.75);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.8);
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.08),
    inset 0 1px 0 rgba(255, 255, 255, 0.9);
  padding: 60px 80px;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;

  // 玻璃光泽效果
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(
      90deg,
      transparent,
      rgba(255, 255, 255, 0.4),
      transparent
    );
    transition: left 0.5s ease;
  }

  &:hover {
    transform: translateY(-5px);
    box-shadow:
      0 12px 48px rgba(0, 0, 0, 0.12),
      inset 0 1px 0 rgba(255, 255, 255, 1);

    &::before {
      left: 100%;
    }
  }
}

.welcome-card {
  max-width: 600px;

  .welcome-icon {
    font-size: 64px;
    margin-bottom: 24px;
    animation: bounce 2s infinite;
  }

  @keyframes bounce {
    0%, 100% {
      transform: translateY(0);
    }
    50% {
      transform: translateY(-10px);
    }
  }
}

.main-text {
  font-size: 38px;
  font-weight: bold;
  color: rgba(51, 51, 51, 0.9);
  margin-bottom: 16px;
  text-shadow: 0 1px 2px rgba(255, 255, 255, 0.8);
}

.sub-text {
  font-size: 20px;
  font-weight: 500;
  color: rgba(102, 102, 102, 0.75);
  text-shadow: 0 1px 2px rgba(255, 255, 255, 0.5);
}

.text {
  position: relative;
  z-index: 1;
}
</style>
