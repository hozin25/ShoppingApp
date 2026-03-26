<template>
  <div>
    <el-form
      class="detail-form-content"
      ref="ruleForm"
      :rules="rules"
      :model="ruleForm"
      label-width="80px"
    >
      <el-form-item label="原密码" prop="password">
        <el-input v-model="ruleForm.password" show-password></el-input>
      </el-form-item>
      <el-form-item label="新密码" prop="newpassword">
        <el-input type="password" v-model="ruleForm.newpassword" show-password></el-input>
      </el-form-item>
      <el-form-item label="确认密码" prop="repassword">
        <el-input type="password" v-model="ruleForm.repassword" show-password></el-input>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="onUpdateHandler">确 定</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>
<script>
export default {
  data() {
    return {
      dialogVisible: false,
      ruleForm: {},
      user: {},
      rules: {
        password: [
          {
            required: true,
            message: "密码不能为空",
            trigger: "blur"
          }
        ],
        newpassword: [
          {
            required: true,
            message: "新密码不能为空",
            trigger: "blur"
          }
        ],
        repassword: [
          {
            required: true,
            message: "确认密码不能为空",
            trigger: "blur"
          }
        ]
      }
    };
  },
  mounted() {
    this.$http({
      url: `${this.$storage.get("sessionTable")}/session`,
      method: "get"
    }).then(({ data }) => {
      if (data && data.code === 0) {
        this.user = data.data;
      } else {
        this.$message.error(data.msg);
      }
    });
  },
  methods: {
    onLogout() {
      this.$storage.remove("Token");
      this.$router.replace({ name: "login" });
    },
    // 修改密码
    onUpdateHandler() {
      this.$refs["ruleForm"].validate(valid => {
        if (valid) {
          // 1. 前端只验证：新密码和确认密码是否一致
          if (this.ruleForm.newpassword != this.ruleForm.repassword) {
            this.$message.error("两次密码输入不一致");
            return;
          }

          // 2. 使用updatePassword接口，让后端验证原密码
          this.$http({
            url: `${this.$storage.get("sessionTable")}/updatePassword`,
            method: "get",
            params: {
              oldPassword: this.ruleForm.password,
              newPassword: this.ruleForm.newpassword
            }
          }).then(({ data }) => {
            if (data && data.code === 0) {
              // 3. 检查响应中是否包含新token并更新
              if (data.token) {
                this.$storage.set("Token", data.token);
              }

              // 4. 显示成功消息
              this.$message({
                message: data.token ? "修改密码成功,token已更新" : "修改密码成功",
                type: "success",
                duration: 1500,
                onClose: () => {
                  // 清空表单
                  this.ruleForm = {};
                  this.$refs["ruleForm"].resetFields();
                }
              });
            } else {
              // 5. 显示错误消息（如"原密码错误"）
              this.$message.error(data.msg);
            }
          });
        }
      });
    }
  }
};
</script>
<style lang="scss" scoped>
</style>
