<template>
  <el-breadcrumb class="app-breadcrumb glass-breadcrumb" separator="✌">
    <transition-group name="breadcrumb" class="box" :style="1==1?'justifyContent:flex-start;':1==2?'justifyContent:center;':'justifyContent:flex-end;'">
      <el-breadcrumb-item v-for="(item,index) in levelList" :key="item.path">
        <span v-if="item.redirect==='noRedirect'||index==levelList.length-1" class="no-redirect">{{ item.name }}</span>
        <a v-else @click.prevent="handleLink(item)">{{ item.name }}</a>
      </el-breadcrumb-item>
    </transition-group>
  </el-breadcrumb>
</template>

<script>
    import pathToRegexp from 'path-to-regexp'
    import { generateTitle } from '@/utils/i18n'
    export default {
        data() {
            return {
                levelList: null
            }
        },
        watch: {
            $route() {
                this.getBreadcrumb()
            }
        },
        created() {
            this.getBreadcrumb()
            this.breadcrumbStyleChange()
        },
        methods: {
            generateTitle,
            getBreadcrumb() {
                // only show routes with meta.title
                let route = this.$route
                let matched = route.matched.filter(item => item.meta)
                const first = matched[0]
                matched = [{ path: '/index' }].concat(matched)

                this.levelList = matched.filter(item => item.meta)
            },
            isDashboard(route) {
                const name = route && route.name
                if (!name) {
                    return false
                }
                return name.trim().toLocaleLowerCase() === 'Index'.toLocaleLowerCase()
            },
            pathCompile(path) {
                // To solve this problem https://github.com/PanJiaChen/vue-element-admin/issues/561
                const { params } = this.$route
                var toPath = pathToRegexp.compile(path)
                return toPath(params)
            },
            handleLink(item) {
                const { redirect, path } = item
                if (redirect) {
                    this.$router.push(redirect)
                    return
                }
                this.$router.push(path)
            },
            breadcrumbStyleChange(val) {
                this.$nextTick(()=>{
                    document.querySelectorAll('.app-breadcrumb .el-breadcrumb__separator').forEach(el=>{
                        el.innerText = "✌"
                        el.style.color = "rgba(102, 102, 102, 0.6)"
                    })
                    document.querySelectorAll('.app-breadcrumb .el-breadcrumb__inner a').forEach(el=>{
                        el.style.color = "rgba(51, 51, 51, 0.85)"
                    })
                    document.querySelectorAll('.app-breadcrumb .el-breadcrumb__inner .no-redirect').forEach(el=>{
                        el.style.color = "rgba(102, 102, 102, 0.6)"
                    })

        let str = "vertical"
        if("vertical" === str) {
          let headHeight = "40px"
          headHeight = parseInt(headHeight) + 10 + 'px'
          document.querySelectorAll('.app-breadcrumb').forEach(el=>{
            el.style.marginTop = headHeight
          })
        }

      })
    },
  }
}
</script>

<style lang="scss" scoped>
.app-breadcrumb {
  display: block;
  font-size: 14px;
  line-height: 50px;
  padding: 12px 24px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(15px) saturate(180%);
  -webkit-backdrop-filter: blur(15px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.7);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
  margin-bottom: 16px;

  .box {
    display: flex;
    width: 100%;
    height: 100%;
    justify-content: flex-start;
    align-items: center;
  }

  .no-redirect {
    color: rgba(102, 102, 102, 0.6);
    cursor: text;
  }

  a {
    color: rgba(51, 51, 51, 0.85);
    transition: all 0.3s ease;

    &:hover {
      color: var(--publicMainColor);
      text-decoration: none;
    }
  }
}
</style>
