import router from '@ohos.router';

@Entry
@Component
struct OrgRegisterPage {
  @State orgType: number = 0;
  @State email: string = '';
  @State password: string = '';
  @State agreedToTerms: boolean = false;

  build() {
    Scroll() {
      Column() {
        // Navigation bar
        Row() {
          Text('\u2190')
            .fontSize(22)
            .fontColor('#333333')
            .onClick(() => { router.back(); })
          Text('知乎机构号注册')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 8 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')

        // Hero section
        Column() {
          Text('入驻知乎机构号')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0066FF')
          Text('影响有影响力的人')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0066FF')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding({ top: 30, bottom: 30 })
        .backgroundColor('#F0F6FF')
        .alignItems(HorizontalAlign.Center)

        // Organization type selector
        Row() {
          this.OrgTypeItem(0, '\u{1F454}', '企业')
          this.OrgTypeItem(1, '\u{1F4F7}', '媒体')
          this.OrgTypeItem(2, '\u{1F6E1}', '政府')
          this.OrgTypeItem(3, '\u{1F3E2}', '其他')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 20 })
        .justifyContent(FlexAlign.SpaceAround)

        // Form card
        Column() {
          Text('机构注册信息')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 16 })

          this.FormInput('机构名称', '请输入机构名称')
          this.FormInput('邮箱地址', '请输入邮箱地址')
          this.FormInput('设置密码', '请输入密码（6-20位）')
          this.FormInput('验证码', '请输入验证码')

          Row() {
            Text('我已阅读并同意《知乎机构号服务协议》')
              .fontSize(12)
              .fontColor('#666666')
            Toggle({ type: ToggleType.Checkbox, isOn: this.agreedToTerms })
              .onChange((value: boolean) => {
                this.agreedToTerms = value;
              })
          }
          .width('100%')
          .margin({ top: 12 })

          Button('立即注册')
            .width('100%')
            .height(44)
            .fontSize(16)
            .backgroundColor(this.agreedToTerms ? '#0066FF' : '#CCCCCC')
            .borderRadius(22)
            .margin({ top: 20 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16, top: 16 })

        // Benefits
        Column() {
          Text('入驻权益')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 12 })

          this.BenefitItem('官方认证标识', '获得知乎官方机构认证蓝V标识')
          this.BenefitItem('内容分发加权', '优质内容获得更多曝光推荐')
          this.BenefitItem('数据分析工具', '查看内容数据分析和用户画像')
          this.BenefitItem('品牌保护', '保护机构名称和品牌权益')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16, top: 16, bottom: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .scrollBar(BarState.Off)
  }

  @Builder
  OrgTypeItem(index: number, icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(32)
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor(this.orgType === index ? '#0066FF' : '#F0F0F0')
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(13)
        .fontColor(this.orgType === index ? '#0066FF' : '#333333')
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.orgType = index; })
  }

  @Builder
  FormInput(label: string, placeholder: string) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .width('100%')
        .margin({ bottom: 4 })
      TextInput({ placeholder: placeholder })
        .width('100%')
        .height(40)
        .fontSize(14)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  BenefitItem(title: string, desc: string) {
    Row() {
      Text('\u2713')
        .fontSize(16)
        .fontColor('#0066FF')
      Column() {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
        Text(desc)
          .fontSize(12)
          .fontColor('#999999')
      }
      .margin({ left: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }
}
