import { router } from '@kit.ArkUI';

@Entry
@Component
struct PrivacyGuidePage {
  onBack(): void {
    router.back();
  }

  onOverflowMenu(): void {
    // Overflow menu: share / copy / feedback - placeholder
    // In production, this could show a context menu or ActionSheet
  }

  build() {
    Column() {
      // ── Top Navigation Bar ──
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#1A1A1A')
          .padding({ left: 4, right: 12, top: 8, bottom: 8 })
          .onClick(() => {
            this.onBack();
          })

        Text('个人信息保护指引')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('⋯')
          .fontSize(22)
          .fontColor('#1A1A1A')
          .padding({ left: 12, right: 4, top: 8, bottom: 8 })
          .onClick(() => {
            this.onOverflowMenu();
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({
        width: { bottom: 0.5 },
        color: '#E0E0E0'
      })

      // ── Scrollable Document Content ──
      Scroll() {
        Column() {
          // Version header
          Text('第 5.2 版本')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ top: 24, bottom: 16 })

          // Update date
          Row() {
            Text('更新日期：')
              .fontSize(15)
              .fontColor('#666666')
            Text('2025 年 10 月 10 日')
              .fontSize(15)
              .fontColor('#1A1A1A')
          }
          .width('100%')
          .margin({ bottom: 8 })

          // Effective date
          Row() {
            Text('生效日期：')
              .fontSize(15)
              .fontColor('#666666')
            Text('2025 年 10 月 15 日')
              .fontSize(15)
              .fontColor('#1A1A1A')
          }
          .width('100%')
          .margin({ bottom: 24 })

          // Separator
          Divider()
            .strokeWidth(0.5)
            .color('#E8E8E8')
            .margin({ bottom: 24 })

          // Section: Introduction
          Text('引言')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '知乎产品和/或服务是由北京智者天下科技有限公司（注册地址：北京市海淀区学清路18号6幢2层6220室，联系地址：北京市海淀区学清路18号6幢2层6220室）和智者四海（北京）技术有限公司（注册地址：北京市海淀区学清路18号6幢2层6219室；联系地址：北京市海淀区学清路18号6幢2层6219室）作为共同处理者共同提供（以下简称「知乎」或「我们」）。我们为用户（以下简称「您」）通过「知乎」App及关联版本（包括「知乎盐选版」App等）、知乎网站（https://www.zhihu.com）、小程序以及我们现在或将来的其他程序、软件、客户端或其他类似产品，及由我们提供给第三方平台和应用程序使用的软件开发工具包（SDK）和应用程序编程接口（API）（以下统称「本平台」）提供在线网络社区的产品和服务（包括以问答产品或其他形式组织的内容产品和/或有关服务），以「让人们更好地分享知识、经验和见解，找到自己的解答」为使命，旨在以可持续发展、独立运营并获得健康增长的方式通过社区产品提供值得信赖的内容给用户。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 16 })

          Text(
            '我们根据《中华人民共和国网络安全法》《中华人民共和国个人信息保护法》《中华人民共和国数据安全法》《常见类型移动互联网应用程序必要个人信息范围规定》等法律法规，并参考《信息安全技术 个人信息安全规范》（GB/T 35273-2020）等国家标准，制定本《个人信息保护指引》（以下简称「本指引」）。我们将按照本指引的规定收集、使用、存储、处理和保护您的个人信息。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 24 })

          // Section: Personal Information We Collect
          Text('一、我们如何收集和使用您的个人信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '个人信息是指以电子或者其他方式记录的与已识别或者可识别的自然人有关的各种信息，不包括匿名化处理后的信息。我们将在以下场景中收集和使用您的个人信息：'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 12 })

          Text('1. 注册和登录')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 8 })

          Text(
            '当您注册和登录知乎账号时，我们需要收集您的手机号码或电子邮箱地址，以及您设置的密码。您也可以选择使用第三方平台账号（如微信、QQ、微博、Apple ID等）进行登录，此时我们会从第三方平台获取您的账号信息（如昵称、头像等）。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 12 })

          Text('2. 个人资料')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 8 })

          Text(
            '您可以在个人资料页编辑和补充您的个人信息，包括头像、昵称、性别、生日、所在地、个人简介、教育背景、职业经历等。这些信息将帮助其他用户更好地了解您，您可以选择不填写或部分填写。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 12 })

          Text('3. 内容发布与互动')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 8 })

          Text(
            '当您在知乎平台发布提问、回答、文章、想法、评论等内容时，我们会收集您发布的内容信息，并展示您的昵称、头像和发布内容。当您对其他用户的内容进行赞同、收藏、感谢、举报等互动操作时，我们会收集您的操作记录。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 16 })

          // Section: How We Store and Protect
          Text('二、我们如何存储和保护您的个人信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '我们将在中华人民共和国境内存储您的个人信息。我们会采取合理可行的安全防护措施保护您的个人信息，防止数据遭到未经授权的访问、公开披露、使用、修改、损坏或丢失。我们已通过ISO 27001信息安全管理体系认证和国家信息安全等级保护三级认证。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '我们会在为您提供产品和服务所必需的期间内保留您的个人信息，法律法规另有规定的除外。当您注销账号后，我们将在合理期限内删除或匿名化处理您的个人信息。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 24 })

          // Section: How We Share
          Text('三、我们如何共享、转让、公开披露您的个人信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '我们不会将您的个人信息出售给任何第三方。我们仅在以下情况下共享您的个人信息：（1）获得您的明确同意；（2）根据法律法规规定或行政、司法机关的强制性要求；（3）与我们的关联公司共享，且受本指引的约束；（4）与授权合作伙伴共享，仅为实现本指引中声明的目的。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '关于我们与第三方共享个人信息的具体情况，请参见《与第三方共享个人信息清单》。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 24 })

          // Section: Your Rights
          Text('四、您的权利')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '您有权访问、更正、删除您的个人信息，有权撤回您的同意，有权注销您的账号，有权获取您的个人信息副本。您可以通过知乎App中的"设置-隐私"路径行使上述权利，也可以联系我们的个人信息保护专员。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 24 })

          // Section: Contact Us
          Text('五、如何联系我们')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '如果您对本指引或个人信息保护有任何疑问、意见或建议，可以通过以下方式与我们联系：\n\n联系地址：北京市海淀区学清路18号6幢2层6220室\n个人信息保护专员邮箱：privacy@zhihu.com\n\n我们将在收到您的请求后15个工作日内予以回复。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 24 })

          // Section: Update History
          Text('六、本指引的更新')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '我们可能会适时修订本指引。未经您明确同意，我们不会削减您按照本指引所应享有的权利。我们会在本页面上发布对本指引所做的任何变更。对于重大变更，我们还会通过App推送通知、弹窗或其他适当方式向您提示。'
          )
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 12 })

          Text(
            '本指引的更新日期为2025年10月10日，生效日期为2025年10月15日。'
          )
            .fontSize(15)
            .fontColor('#666666')
            .lineHeight(26)
            .width('100%')
            .margin({ bottom: 40 })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
