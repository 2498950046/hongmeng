import { RdbManager } from '../utils/RdbManager';
import router from '@ohos.router';

// 定义用户接口
interface User {
  user_id: string;
  nickname: string;
  avatar_url: string;
  create_time: number;
}

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  aboutToAppear() {
    // 检查是否已有登录用户
    this.checkExistingUser();
  }

  async checkExistingUser() {
    // 屏蔽掉自动登录，否则如果你之前创建过 user_001，一进页面就会闪退回主页
    // 实际项目中，这里应该去查 Preferences（本地轻量缓存）里的登录状态
    console.info('LoginPage', '进入登录页，等待用户输入');
  }

  async handleLogin() {
    if (!this.username.trim()) {
      this.errorMessage = '请输入用户名';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 1. 用用户输入的 username 去数据库里查
      let user = await RdbManager.getUserById(this.username);

      if (!user) {
        // 2. 如果查不到，说明是新用户，直接为他注册（模拟一键注册并登录）
        const newUserId = await RdbManager.createUser(this.username);
        user = await RdbManager.getUserById(newUserId);
      }

      if (user) {
        // 3. 登录成功，保存全局状态并返回上一页
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('isLoggedIn', true);

        // 提示一下成功
        console.info('LoginPage', '登录成功！欢迎：' + user.nickname);
        router.back();
      } else {
        this.errorMessage = '系统异常：无法创建用户';
      }
    } catch (err) {
      console.error('登录异常:', JSON.stringify(err));
      this.errorMessage = '数据库异常，登录失败';
    } finally {
      this.isLoading = false; // 放到 finally 里确保按钮状态能恢复
    }
  }
  build() {
    Column() {
      // 顶部标题
      Text('欢迎登录觅食记')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF5E00')
        .margin({ top: 100, bottom: 50 })

      // 登录表单
      Column() {
        // 用户名输入
        Text('用户名')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入您的用户名', text: this.username })
          .width('100%')
          .height(50)
          .padding(10)
          .borderRadius(8)
          .border({
            width: 1,
            color: this.username ? '#FF5E00' : '#E5E5E5'
          })
          .onChange((value: string) => {
            this.username = value;
            this.errorMessage = '';
          })

        // 密码输入（简化版，实际项目中需要密码验证）
        Text('密码')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)
          .margin({ top: 20, bottom: 8 })
        
        TextInput({ placeholder: '请输入密码（任意密码）', text: this.password })
          .type(InputType.Password)
          .width('100%')
          .height(50)
          .padding(10)
          .borderRadius(8)
          .border({
            width: 1,
            color: this.password ? '#FF5E00' : '#E5E5E5'
          })
          .onChange((value: string) => {
            this.password = value;
            this.errorMessage = '';
          })

        // 错误消息
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF3B30')
            .align(Alignment.Start)
            .margin({ top: 10 })
        }

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(50)
          .margin({ top: 30 })
          .backgroundColor(this.isLoading ? '#CCCCCC' : '#FF5E00')
          .fontColor('#FFFFFF')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .borderRadius(25)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin();
          })

        // 测试用户提示
        Text('提示：首次登录将自动创建用户账号')
          .fontSize(12)
          .fontColor('#8A8A8A')
          .margin({ top: 20 })

      }
      .width('80%')

      // 底部注册提示
      Row() {
        Text('还没有账号？')
          .fontSize(14)
          .fontColor('#666666')
        
        Text('立即注册')
          .fontSize(14)
          .fontColor('#FF5E00')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            // 跳转到注册页面
            router.pushUrl({
              url: 'login/RegisterPage'
            });
          })
      }
      .margin({ top: 50 })

    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}