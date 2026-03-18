import { RdbManager } from '../utils/RdbManager';
import router from '@ohos.router';
import type { User } from '../types';

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
    console.info('LoginPage', '===== 登录开始 =====');
    console.info('LoginPage', 'handleLogin 被调用，username:', this.username);
    console.info('LoginPage', '当前 isLoading:', this.isLoading);
    
    if (this.isLoading) {
      console.warn('LoginPage', '正在登录中，忽略重复点击');
      return;
    }
    
    if (!this.username.trim()) {
      console.warn('LoginPage', '用户名为空');
      this.errorMessage = '请输入用户名';
      return;
    }

    console.info('LoginPage', '开始设置 loading 状态');
    this.isLoading = true;
    this.errorMessage = '';
    
    console.info('LoginPage', '数据库是否已初始化:', RdbManager.isInitialized());

    try {
      let user: User | null = null;
      
      // 如果数据库已初始化，使用数据库登录
      if (RdbManager.isInitialized()) {
        console.info('LoginPage', '使用数据库登录');
        // 1. 用用户输入的 username 去数据库里查
        user = await RdbManager.getUserById(this.username);

        if (!user) {
          // 2. 如果查不到，说明是新用户，直接为他注册（模拟一键注册并登录）
          console.info('LoginPage', '用户不存在，开始创建新用户');
          const newUserId = await RdbManager.createUser(this.username);
          user = await RdbManager.getUserById(newUserId);
        }
      } else {
        // 数据库未初始化，使用本地模拟登录
        console.warn('LoginPage', '数据库未初始化，使用本地模拟登录');
        user = {
          user_id: 'local_user_' + Date.now(),
          nickname: this.username,
          avatar_url: '',
          create_time: Date.now()
        };
      }

      console.info('LoginPage', 'user 对象:', user ? user.nickname : 'null');
      
      if (user) {
        // 3. 登录成功，保存全局状态并返回上一页
        console.info('LoginPage', '准备保存登录状态');
        AppStorage.setOrCreate('currentUser', user);
        AppStorage.setOrCreate('isLoggedIn', true);

        // 提示一下成功
        console.info('LoginPage', '登录成功！欢迎：' + user.nickname);
        
        // 直接返回上一页
        console.info('LoginPage', '准备返回上一页');
        router.back();
      } else {
        this.errorMessage = '系统异常：无法创建用户';
      }
    } catch (err) {
      console.error('登录异常:', JSON.stringify(err));
      this.errorMessage = '数据库异常，登录失败';
    } finally {
      console.info('LoginPage', '恢复 loading 状态为 false');
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
        .margin({ top: 60, bottom: 40 })

      // 登录表单
      Column() {
        // 用户名输入
        Text('用户名')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)
          .width('100%')
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入您的用户名', text: this.username })
          .width('100%')
          .height(50)
          .padding(12)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => {
            this.username = value;
            this.errorMessage = '';
          })

        // 密码输入（简化版，实际项目中需要密码验证）
        Text('密码')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Start)
          .width('100%')
          .margin({ top: 24, bottom: 8 })
        
        TextInput({ placeholder: '请输入密码（任意密码）', text: this.password })
          .type(InputType.Password)
          .width('100%')
          .height(50)
          .padding(12)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')
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
            .margin({ top: 12 })
        }

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(50)
          .margin({ top: 40 })
          .backgroundColor('#FF5E00')
          .fontColor('#FFFFFF')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .borderRadius(25)
          .onClick(() => {
            console.info('LoginPage', '===== 登录按钮被点击 =====');
            if (!this.isLoading) {
              this.handleLogin();
            }
          })

        // 测试用户提示
        Text('提示：首次登录将自动创建用户账号')
          .fontSize(12)
          .fontColor('#8A8A8A')
          .margin({ top: 16 })

      }
      .width('85%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({
        radius: 10,
        color: 'rgba(0,0,0,0.1)',
        offsetX: 0,
        offsetY: 4
      })

      // 底部注册提示
      Row() {
        Text('还没有账号？')
          .fontSize(14)
          .fontColor('#666666')
        
        Text('立即注册')
          .fontSize(14)
          .fontColor('#FF5E00')
          .fontWeight(FontWeight.Medium)
          .margin({ left: 4 })
          .onClick(() => {
            console.info('LoginPage', '注册按钮被点击');
            // 跳转到注册页面
            router.pushUrl({
              url: 'login/RegisterPage'
            });
          })
      }
      .margin({ top: 30 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F2F5')
    .alignItems(HorizontalAlign.Center)
  }
}