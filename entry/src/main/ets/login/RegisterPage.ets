import { RdbManager } from '../utils/RdbManager';
import router from '@ohos.router';
import type { User } from '../types';

@Entry
@Component
struct RegisterPage {
  @State nickname: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  async handleRegister() {
    if (!this.nickname.trim()) {
      this.errorMessage = '请输入昵称';
      return;
    }

    if (this.nickname.length < 2) {
      this.errorMessage = '昵称至少 2 个字符';
      return;
    }

    if (!this.password) {
      this.errorMessage = '请输入密码';
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      let userId: string;
      
      // 如果数据库已初始化，使用数据库注册
      if (RdbManager.isInitialized()) {
        console.info('RegisterPage', '使用数据库注册');
        userId = await RdbManager.createUser(this.nickname);
      } else {
        // 数据库未初始化，使用本地模拟注册
        console.warn('RegisterPage', '数据库未初始化，使用本地模拟注册');
        userId = 'local_user_' + Date.now();
      }
      
      const user: User = {
        user_id: userId,
        nickname: this.nickname,
        avatar_url: '',
        create_time: Date.now()
      };

      if (user) {
        // 注册成功，自动登录
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('isLoggedIn', true);
        
        console.info('RegisterPage', '注册成功！欢迎：' + user.nickname);
        
        // 直接返回上一页
        router.back();
      } else {
        this.errorMessage = '注册失败，请重试';
      }
    } catch (err) {
      console.error('注册失败:', JSON.stringify(err));
      this.errorMessage = '注册失败，请重试';
    }

    this.isLoading = false;
  }

  build() {
    Column() {
      // 顶部标题
      Text('注册觅食记账号')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF5E00')
        .margin({ top: 80, bottom: 40 })

      // 注册表单
      Column() {
        // 昵称输入
        Text('昵称')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入您的昵称', text: this.nickname })
          .width('100%')
          .height(50)
          .padding(10)
          .borderRadius(8)
          .border({
            width: 1,
            color: this.nickname ? '#FF5E00' : '#E5E5E5'
          })
          .onChange((value: string) => {
            this.nickname = value;
            this.errorMessage = '';
          })

        // 密码输入
        Text('密码')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)
          .margin({ top: 20, bottom: 8 })
        
        TextInput({ placeholder: '请设置登录密码', text: this.password })
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

        // 确认密码
        Text('确认密码')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)
          .margin({ top: 20, bottom: 8 })
        
        TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
          .type(InputType.Password)
          .width('100%')
          .height(50)
          .padding(10)
          .borderRadius(8)
          .border({
            width: 1,
            color: this.confirmPassword ? '#FF5E00' : '#E5E5E5'
          })
          .onChange((value: string) => {
            this.confirmPassword = value;
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

        // 注册按钮
        Button(this.isLoading ? '注册中...' : '立即注册')
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
            this.handleRegister();
          })

      }
      .width('80%')

      // 底部登录提示
      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor('#666666')
        
        Text('立即登录')
          .fontSize(14)
          .fontColor('#FF5E00')
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            // 返回登录页面
            router.back();
          })
      }
      .margin({ top: 40 })

    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}