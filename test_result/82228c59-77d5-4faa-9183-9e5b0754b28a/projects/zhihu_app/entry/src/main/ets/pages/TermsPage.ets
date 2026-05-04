import router from '@ohos.router';

@Entry
@Component
struct TermsPage {

  build() {
    Column() {
      // Status bar
      Row() {
        Text('15:17')
          .fontSize(12)
          .fontColor('#333333')
        Blank()
        Text('56%')
          .fontSize(12)
          .fontColor('#333333')
      }
      .width('100%')
      .height(28)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')

      // Navigation bar
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#333333')
          .padding({ right: 12 })
          .onClick(() => {
            router.back();
          })
        Text('用户协议')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Preamble
          Column() {
            Text('知乎用户协议')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 12 })

            Text('更新日期：2025 年 1 月 1 日')
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .margin({ bottom: 16 })

            Text('欢迎您使用知乎平台和相关服务！')
              .fontSize(14)
              .fontColor('#333333')
              .lineHeight(22)
              .width('100%')
              .margin({ bottom: 8 })

            Text('为使用知乎平台（以下简称"本平台"）及服务，您应当阅读并遵守《知乎用户协议》（以下简称"本协议"）。请您务必审慎阅读、充分理解各条款内容，特别是免除或者限制责任的条款、法律适用和争议解决条款。')
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(22)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 1
          Column() {
            Text('一、协议的范围')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })

            Text('1. 本协议是您与北京智者天下科技有限公司（以下简称"知乎"）之间关于使用知乎平台服务所订立的协议。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('2. 本协议包括协议正文以及知乎已经发布或将来可能发布的各类规则。所有规则为本协议不可分割的一部分，与本协议正文具有同等法律效力。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 2
          Column() {
            Text('二、账号注册与使用')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })

            Text('1. 您在使用本平台服务前需要注册一个知乎账号。您应当提供真实、准确、完整的注册信息。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('2. 您应当妥善保管您的账号和密码，因您保管不善可能导致遭受的损失，由您自行承担。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('3. 您不得将您的账号赠与、借用、租用、转让或以其他方式提供给他人使用。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 3
          Column() {
            Text('三、用户行为规范')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })

            Text('您在使用知乎平台服务时，应当遵守法律法规，尊重社会公德，不得发布和传播以下内容：')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('• 反对宪法所确定的基本原则的内容')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 3 })

            Text('• 危害国家安全，泄露国家秘密的信息')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 3 })

            Text('• 损害国家荣誉和利益的内容')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 3 })

            Text('• 煽动民族仇恨、民族歧视的内容')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 3 })

            Text('• 破坏国家宗教政策，宣扬邪教和封建迷信的内容')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 3 })

            Text('• 散布谣言，扰乱社会秩序的内容')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 4
          Column() {
            Text('四、知识产权')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })

            Text('1. 您在知乎平台上发布的内容，您保留相应的知识产权。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('2. 您授予知乎一项全球范围内免费、非独家、可再许可的使用权，以便知乎展示、传播您发布的内容。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('3. 您应当确保您发布的内容不侵犯他人的知识产权。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 5
          Column() {
            Text('五、免责声明')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })

            Text('知乎不对因通信线路故障、技术问题、网络中断、电脑病毒、黑客攻击或其他不可抗力因素造成的服务中断或不能满足您的要求承担责任。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 6
          Column() {
            Text('六、法律适用与争议解决')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })

            Text('本协议的订立、执行和解释及争议的解决均适用中华人民共和国法律。如发生协议条款与法律相抵触时，该条款将按法律规定重新解释，其他条款继续有效。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Footer
          Column() {
            Text('北京智者天下科技有限公司')
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 24, bottom: 24 })
          }
          .width('100%')
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
}
