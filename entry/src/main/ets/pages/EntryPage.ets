import { Want,common } from "@kit.AbilityKit";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { JSON } from "@kit.ArkTS";


@Entry
@Component
struct EntryPage {
  @State message: string = 'entryability页面';
  private value=this.getUIContext().getHostContext() as common.UIAbilityContext
  build() {
    Column(){
      Button('点击跳转')
        .onClick(()=>{
          //定义跳转参数
          let info:Want={
            deviceId:'',//为空为本设备
            bundleName:'com.example.myapplication',//包名称
            abilityName:'EntryAbility1',//跳转目标ability名字
            parameters:{
              str:'传递123'
          }
          }
          //启动跳转
          this.value.startAbility(info).then(()=>{
            hilog.info(555,'Ability','true')
          }).catch((error:BusinessError)=>{
            hilog.error(555,'Ability','false'+JSON.stringify(error))

          })
        })
    }
  }
}