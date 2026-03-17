@Entry
@Component
@Preview
struct Index {
  @State message: string = '微信';

  build() {
    Column() {
      RelativeContainer() {
        Text(this.message)
          .id('HelloWorld')

          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .alignRules({
            //  居中：保持水平方向在容器中间
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
            //  上移：将顶端（top）对齐容器的顶端
            top: { anchor: '__container__', align: VerticalAlign.Top }
          })

          .margin({ top: 50 })

          .onClick(() => {
            this.message = 'Welcome';
          })
      }
      .height('15%')
      .width('100%')

      login()
    }

  }
}

@Component
@Preview
struct login {
  @State username: string = '';
  @State password: string = '';

  build() {
    // 使用 RelativeContainer 实现灵活定位
    RelativeContainer() {
      //  登录标题
      Text('欢迎登录')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .id('loginTitle')
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          top: { anchor: '__container__', align: VerticalAlign.Top }
        })
        .margin({ top: 100 })

      //  用户名输入框
      TextInput({ placeholder: '请输入用户名', text: this.username })
        .id('usernameInput')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          top: { anchor: 'loginTitle', align: VerticalAlign.Bottom } // 在标题下方
        })
        .onChange((value: string) => {
          this.username = value;
        })

      // 密码输入框
      TextInput({ placeholder: '请输入密码', text: this.password })
        .id('passwordInput')
        .type(InputType.Password) // 隐藏密码字符
        .width('80%')
        .height(50)
        .margin({ top: 15 })
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          top: { anchor: 'usernameInput', align: VerticalAlign.Bottom } // 在用户名框下方
        })
        .onChange((value: string) => {
          this.password = value;
        })

      // 登录按钮
      Button('登录')
        .width('80%')
        .height(45)
        .margin({ top: 40 })
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          top: { anchor: 'passwordInput', align: VerticalAlign.Bottom }
        })
        .onClick(() => {
          console.info(`用户尝试登录: ${this.username}`);
        })
    }
    .width('100%')
    .height('100%')

  }
}