import router from '@ohos.router';

@Entry
@Component
struct HelpFeedbackPage {
  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('帮助与反馈')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EDEDED')

      Scroll() {
        Column() {
          this.HelpCategoryItem('账号与登录', '账号被封、忘记密码、收到安全提醒', () => {
            // Placeholder
          })
          this.HelpCategoryItem('通讯录', '添加好友、删除/拉黑', () => {
            // Placeholder
          })
          this.HelpCategoryItem('朋友圈', '发布方法、权限设置、评论规则', () => {
            // Placeholder
          })
          this.HelpCategoryItem('未成年人模式', '如何使用、修改独立密码', () => {
            // Placeholder
          })
          this.HelpCategoryItem('关怀模式', '听文字消息、调整字体', () => {
            // Placeholder
          })
          this.HelpCategoryItem('聊天', '备份聊天记录、消息撤回、发起投票', () => {
            // Placeholder
          })
          this.HelpCategoryItem('视频号', '视频审核、互动浏览', () => {
            // Placeholder
          })
          this.HelpCategoryItem('支付', '支付限制、自动扣费、绑定银行卡', () => {
            // Placeholder
          })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ top: 16, bottom: 80 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#EDEDED')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HelpCategoryItem(title: string, summary: string, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#333333')
        Text(summary)
          .fontSize(12)
          .fontColor('#B3B3B3')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      onClick();
    })
    .border({
      width: { bottom: 0.5 },
      color: '#F1F1F1'
    })
  }
}
