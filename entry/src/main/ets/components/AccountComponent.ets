
//跨文件自定义构建函数
@Builder
export function LoginBuilder(
  username: string,
  password: string,
  onUsernameChange: (value: string) => void,
  onPasswordChange: (value: string) => void,
  onLoginClick: () => void
) {
  // 核心 UI 结构完全保留
  RelativeContainer() {
    // 登录标题
    Text('欢迎登录')
      .fontSize(24)
      .fontWeight(FontWeight.Bold)
      .id('loginTitle')
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: '__container__', align: VerticalAlign.Top }
      })
      .margin({ top: 100 })

    // 用户名输入框
    TextInput({ placeholder: '请输入用户名', text: username }) // 使用参数传入的值
      .id('usernameInput')
      .width('80%')
      .height(50)
      .margin({ top: 20 })
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: 'loginTitle', align: VerticalAlign.Bottom }
      })
      .onChange((value: string) => {
        onUsernameChange(value); // 触发父组件传进来的修改方法
      })

    // 密码输入框
    TextInput({ placeholder: '请输入密码', text: password }) // 使用参数传入的值
      .id('passwordInput')
      .type(InputType.Password)
      .width('80%')
      .height(50)
      .margin({ top: 15 })
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: 'usernameInput', align: VerticalAlign.Bottom }
      })
      .onChange((value: string) => {
        onPasswordChange(value); // 触发父组件传进来的修改方法
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
        onLoginClick(); // 触发父组件的点击事件
      })
  }
  .width('100%')
  .height('100%')
}