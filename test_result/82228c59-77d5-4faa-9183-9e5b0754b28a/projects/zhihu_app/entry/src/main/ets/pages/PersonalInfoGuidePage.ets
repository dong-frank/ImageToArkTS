import router from '@ohos.router';

@Entry
@Component
struct PersonalInfoGuidePage {

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
        Text('个人信息保护指引')
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
          // Info section card
          Column() {
            Text('引言')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })

            Text('知乎非常重视用户的隐私和个人信息保护。本指引旨在向您说明我们如何收集、使用、存储和保护您的个人信息，以及您所享有的相关权利。')
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(22)
              .width('100%')
              .margin({ bottom: 16 })

            Text('请您在使用知乎的产品和/或服务前，仔细阅读并了解本指引的全部内容。如您对本指引的内容有任何疑问，您可以通过知乎 App 内的"帮助与客服"渠道或发送邮件至 privacy@zhihu.com 与我们联系。')
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(22)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 1: Information we collect
          Column() {
            Text('一、我们收集的信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })

            Text('1. 注册信息：当您创建知乎账号时，我们会收集您提供的手机号码、邮箱地址或第三方账号信息。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('2. 个人资料：您可以选择填写昵称、头像、性别、个人简介等资料。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('3. 使用信息：我们记录您的浏览、搜索、点赞、收藏、评论、关注等使用行为。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('4. 设备信息：我们收集设备型号、操作系统版本、IP 地址等基础设备信息。')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 2: How we use info
          Column() {
            Text('二、我们如何使用信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })

            Text('1. 提供、维护和改进我们的产品和服务')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('2. 个性化推荐您可能感兴趣的内容')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('3. 保障产品和服务的安全性和可靠性')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 6 })

            Text('4. 向您发送通知和推送消息')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 3: Your rights
          Column() {
            Text('三、您的权利')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })

            this.RightItem('访问和更正', '您可以在个人主页查看和编辑您的个人信息')
            this.RightItem('删除', '您可以在设置中申请删除您的账号和相关数据')
            this.RightItem('撤回同意', '您可以在设置中管理各项授权的开启/关闭状态')
            this.RightItem('投诉举报', '您可以通过帮助与客服渠道进行投诉和举报')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Section 4: Contact us
          Column() {
            Text('四、联系我们')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 10 })

            Text('如您对本指引或个人信息保护相关事宜有任何疑问、意见或建议，请通过以下方式联系我们：')
              .fontSize(13)
              .fontColor('#666666')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 8 })

            Text('📧 电子邮件：privacy@zhihu.com')
              .fontSize(13)
              .fontColor('#333333')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 4 })

            Text('📱 在线客服：知乎 App 内"帮助与客服"')
              .fontSize(13)
              .fontColor('#333333')
              .lineHeight(20)
              .width('100%')
              .margin({ bottom: 4 })

            Text('📮 地址：北京市海淀区中关村大街 11 号')
              .fontSize(13)
              .fontColor('#333333')
              .lineHeight(20)
              .width('100%')

            Text('更新日期：2025 年 1 月 1 日')
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .margin({ top: 16 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8, bottom: 16 })
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

  @Builder
  RightItem(title: string, description: string) {
    Row() {
      Text('●')
        .fontSize(6)
        .fontColor('#0066FF')
        .margin({ right: 8 })
      Column() {
        Text(title)
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
        Text(description)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .margin({ bottom: 10 })
  }
}
