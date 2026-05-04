import { router } from '@kit.ArkUI';

interface AgreementSection {
  title?: string;
  paragraphs: string[];
}

@Entry
@Component
struct ZhihuAgreementPage {
  private sections: AgreementSection[] = [
    {
      paragraphs: [
        '欢迎您来到知乎。',
        '知乎产品和/或服务由北京智者天下科技有限公司及其关联方合法拥有及运营（以下简称「知乎」或「我们」）。我们为用户（以下简称「您」）通过知乎 App、知乎网站（https://www.zhihu.com）、小程序以及我们现在或将来还可能不时提供的其他程序、软件、客户端或其他类似产品（以下统称「本平台」或「知乎平台」）提供在线网络社区的产品和/或服务（包括以问答产品或其他形式的内容产品和/或有关服务）。',
        '本协议是知乎与您订立的，就您下载、安装、使用知乎平台的相关事宜约定双方权利义务的协议，知乎已经发布的或将来可能发布/更新的并采取合理途径通知的各类协议规范（包括使用单项服务时的协议）、规则、声明、公告、政策、站内信通知等，是本协议不可分割的组成部分，您在使用知乎的产品、接受知乎提供的服务时应同样遵守。请您仔细阅读知乎协议（「本协议」）以下条款，如果您对本协议的任何条款有异议，您可以选择不进入知乎平台，不接受知乎平台的服务和产品。请您了解，一旦您进入知乎平台，即视为您开始使用知乎的产品、接受知乎提供的服务。即使您对本协议的条款存在异议，您仍可以选择停止使用并退出。'
      ]
    },
    {
      title: '一、服务使用规范',
      paragraphs: [
        '1.1 您在知乎平台的注册、登录、使用等行为，将视为对本协议的接受，即表示您同意接受本协议各项条款的约束。',
        '1.2 您应当对您使用知乎平台的行为负责。您在使用知乎平台服务的过程中，应遵守法律法规、社会公德及本协议的约定，不得利用知乎平台从事任何违法违规活动。',
        '1.3 您在使用知乎平台的过程中，应尊重他人的合法权益，不得侵犯他人的知识产权、名誉权、隐私权等合法权益。',
        '1.4 知乎平台上的内容由用户自行发布，知乎不对用户发布的内容承担任何责任。如您发现任何违法违规内容，可通过知乎平台提供的举报渠道进行举报。',
        '1.5 知乎有权对您发布的内容进行审核，并根据相关法律法规及本协议的规定，对违法违规内容采取删除、屏蔽等措施。'
      ]
    },
    {
      title: '二、知识产权',
      paragraphs: [
        '2.1 知乎平台上的所有内容，包括但不限于文字、图片、音频、视频、图表、软件等，其知识产权归知乎或相关权利人所有。',
        '2.2 未经知乎或相关权利人书面许可，您不得以任何方式使用、复制、修改、传播、出版、展示知乎平台上的内容。',
        '2.3 您在知乎平台上发布的内容，其知识产权归您所有。您授予知乎在全球范围内免费、永久、不可撤销的使用、复制、修改、改编、出版、翻译、传播、展示该等内容的权利。'
      ]
    },
    {
      title: '三、隐私保护',
      paragraphs: [
        '3.1 知乎重视您的隐私保护。我们将按照《个人信息保护指引》和《隐私政策》的规定收集、使用和保护您的个人信息。',
        '3.2 您在使用知乎平台的过程中，可能需要提供一些个人信息。您应确保提供的信息真实、准确、完整。',
        '3.3 知乎将采取合理的安全措施保护您的个人信息，防止信息泄露、丢失或被盗用。'
      ]
    },
    {
      title: '四、免责声明',
      paragraphs: [
        '4.1 知乎平台按"现状"和"可得到"的状态向您提供服务，不对服务的及时性、安全性、准确性作任何保证。',
        '4.2 您理解并同意，使用知乎平台的服务可能存在不可预见的风险。您应自行承担使用知乎平台服务所产生的风险。',
        '4.3 在法律允许的最大范围内，知乎不对因使用或无法使用知乎平台服务而产生的任何直接、间接、附带、特殊、惩罚性或结果性的损失承担责任。'
      ]
    },
    {
      title: '五、协议的变更与终止',
      paragraphs: [
        '5.1 知乎有权根据需要修改本协议。协议修改后，知乎将通过适当方式通知您。如您不同意修改后的协议，您可以选择停止使用知乎平台的服务。',
        '5.2 如果您继续使用知乎平台的服务，则视为您接受修改后的协议。',
        '5.3 如果您违反了本协议的任何条款，知乎有权随时终止向您提供服务，并保留追究您法律责任的权利。'
      ]
    },
    {
      title: '六、法律适用与争议解决',
      paragraphs: [
        '6.1 本协议的订立、执行和解释均适用中华人民共和国法律。',
        '6.2 因本协议引起的或与本协议有关的任何争议，双方应首先通过友好协商解决。协商不成的，任何一方均有权将争议提交至北京智者天下科技有限公司所在地有管辖权的人民法院诉讼解决。'
      ]
    },
    {
      title: '七、其他',
      paragraphs: [
        '7.1 本协议构成双方就使用知乎平台服务达成的完整协议，取代之前所有口头或书面的约定。',
        '7.2 如本协议的任何条款被认定为无效或不可执行，该条款应在必要范围内予以限制或删除，不影响本协议其他条款的效力。',
        '7.3 本协议条款的标题仅为方便阅读而设，不影响本协议条款的解释。'
      ]
    }
  ];

  onBack(): void {
    router.back();
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

        Text('知乎协议')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .layoutWeight(1)

        Text('⋯')
          .fontSize(22)
          .fontColor('#1A1A1A')
          .padding({ left: 12, right: 4, top: 8, bottom: 8 })
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
          // Title
          Text('知乎协议')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 20, bottom: 12 })

          // Metadata: dates
          Column() {
            Text('更新于2025-03-20')
              .fontSize(13)
              .fontColor('#888888')
              .margin({ bottom: 4 })

            Text('生效于2025-03-25')
              .fontSize(13)
              .fontColor('#888888')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 24 })

          // Divider after metadata
          Divider()
            .strokeWidth(0.5)
            .color('#E8E8E8')
            .margin({ bottom: 20 })

          // Agreement sections
          ForEach(this.sections, (section: AgreementSection, sectionIndex: number) => {
            Column() {
              // Section title (skip for intro content without titles)
              if (section.title && section.title.length > 0) {
                Text(section.title)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                  .width('100%')
                  .margin({ top: 16, bottom: 10 })
              }

              // Section paragraphs
              ForEach(section.paragraphs, (paragraph: string) => {
                Text(paragraph)
                  .fontSize(15)
                  .fontColor('#333333')
                  .lineHeight(26)
                  .width('100%')
                  .margin({ bottom: 12 })
                  .textAlign(TextAlign.Start)
              })
            }
            .width('100%')

            // Section divider (except for the first intro block and last section)
            if (section.title && section.title.length > 0 && sectionIndex < this.sections.length - 1) {
              Divider()
                .strokeWidth(0.5)
                .color('#E8E8E8')
                .margin({ top: 8, bottom: 8 })
            }
          }, (section: AgreementSection, sectionIndex: number) => sectionIndex.toString())

          // Bottom spacer for safe area
          Blank().height(48)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
