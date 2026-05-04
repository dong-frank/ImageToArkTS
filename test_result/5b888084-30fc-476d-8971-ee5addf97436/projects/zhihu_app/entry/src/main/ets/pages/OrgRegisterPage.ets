import { router } from '@kit.ArkUI';

interface CategoryItem {
  label: string;
  icon: string;
}

@Entry
@Component
struct OrgRegisterPage {
  @State email: string = '';
  @State password: string = '';
  @State captcha: string = '';
  @State passwordVisible: boolean = false;
  @State agreementChecked: boolean = false;

  build() {
    Column() {
      // Top navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 12, right: 8 })
          .onClick(() => {
            router.back();
          })

        Blank()

        Text('知乎机构号注册')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1a1a1a')

        Blank()

        Text('⋯')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ left: 8, right: 12 })
          .onClick(() => {
            console.info('Overflow menu tapped');
          })
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      // Scrollable content
      Scroll() {
        Column() {
          // Hero section
          Column() {
            Text('入驻知乎机构号')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1565C0')

            Text('影响有影响力的人')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1565C0')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 32, bottom: 24 })
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F0F4FA')

          // Category grid
          Row() {
            ForEach(
              [
                { label: '企业', icon: '👔' } as CategoryItem,
                { label: '媒体', icon: '🎙️' } as CategoryItem,
                { label: '政府', icon: '🛡️' } as CategoryItem,
                { label: '其他', icon: '🏢' } as CategoryItem
              ],
              (item: CategoryItem) => {
                Column({ space: 8 }) {
                  Text(item.icon)
                    .fontSize(28)
                  Text(item.label)
                    .fontSize(13)
                    .fontColor('#666666')
                }
                .width('25%')
                .alignItems(HorizontalAlign.Center)
              }
            )
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .backgroundColor('#F0F4FA')

          // Form card
          Column({ space: 16 }) {
            // Email input
            Column({ space: 6 }) {
              Text('请填写邮箱地址')
                .fontSize(14)
                .fontColor('#333333')
              TextInput({ placeholder: '请输入邮箱', text: this.email })
                .width('100%')
                .height(44)
                .fontSize(15)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.email = value;
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // Password input
            Column({ space: 6 }) {
              Text('密码（不少于 8 位）')
                .fontSize(14)
                .fontColor('#333333')
              Row() {
                TextInput({ placeholder: '请输入密码', text: this.password })
                  .layoutWeight(1)
                  .height(44)
                  .fontSize(15)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .type(this.passwordVisible ? InputType.Normal : InputType.Password)
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => {
                    this.password = value;
                  })
                Text(this.passwordVisible ? '👁' : '👁‍🗨')
                  .fontSize(20)
                  .fontColor('#999999')
                  .padding({ left: 8, right: 4 })
                  .onClick(() => {
                    this.passwordVisible = !this.passwordVisible;
                  })
              }
              .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // Captcha input
            Column({ space: 6 }) {
              Text('验证码')
                .fontSize(14)
                .fontColor('#333333')
              Row({ space: 10 }) {
                TextInput({ placeholder: '请输入验证码', text: this.captcha })
                  .layoutWeight(1)
                  .height(44)
                  .fontSize(15)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => {
                    this.captcha = value;
                  })
                Button('获取验证码')
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#1565C0')
                  .borderRadius(8)
                  .height(44)
                  .padding({ left: 14, right: 14 })
                  .onClick(() => {
                    console.info('Get captcha tapped');
                  })
              }
              .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // Register button
            Button('注册机构号')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor('#1565C0')
              .borderRadius(24)
              .margin({ top: 8 })
              .onClick(() => {
                console.info('Register tapped, email:', this.email);
              })
          }
          .width('90%')
          .padding(20)
          .margin({ top: 16 })
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          // Agreement section
          Column({ space: 6 }) {
            Row() {
              Text('☐')
                .fontSize(18)
                .fontColor(this.agreementChecked ? '#1565C0' : '#999999')
                .padding({ right: 6 })
                .onClick(() => {
                  this.agreementChecked = !this.agreementChecked;
                })
              Text('同意知乎协议')
                .fontSize(13)
                .fontColor('#999999')
            }

            Row() {
              Text('点击「注册机构号」按钮，即代表你同意')
                .fontSize(12)
                .fontColor('#AAAAAA')
            }

            Row() {
              Text('《知乎机构账号服务协议》')
                .fontSize(12)
                .fontColor('#1565C0')
                .onClick(() => {
                  router.pushUrl({ url: 'pages/ZhihuAgreementPage' });
                })
              Text('《个人信息保护指引》')
                .fontSize(12)
                .fontColor('#1565C0')
                .margin({ left: 6 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/PrivacyGuidePage' });
                })
            }
          }
          .width('90%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 16, bottom: 8 })

          // Bottom badge
          Row() {
            Text('—')
              .fontColor('#FFB300')
            Text(' 亮点权益 ')
              .fontSize(14)
              .fontColor('#FFB300')
              .fontWeight(FontWeight.Medium)
            Text('—')
              .fontColor('#FFB300')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 20, bottom: 32 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F4FA')
  }
}
