import router from '@ohos.router';

@Entry
@Component
struct IcpRecordPage {

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
        Text('ICP 备案信息')
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
          // ICP record info
          Column() {
            Text('ICP 备案信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 16 })

            this.RecordRow('主办单位名称', '北京智者天下科技有限公司')
            this.RecordRow('主办单位性质', '企业')
            this.RecordRow('网站名称', '知乎')
            this.RecordRow('网站首页地址', 'www.zhihu.com')
            this.RecordRow('网站域名', 'zhihu.com')
            this.RecordRow('ICP 备案号', '京 ICP 备 11020904 号')
            this.RecordRow('ICP 许可证号', '京 ICP 证 110745 号')
            this.RecordRow('审核通过日期', '2024-12-15')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Public security filing
          Column() {
            Text('公网安备信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 16 })

            this.RecordRow('公网安备号', '11010802020290 号')
            this.RecordRow('备案机关', '北京市公安局海淀分局')
            this.RecordRow('备案时间', '2024-12-20')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Business license
          Column() {
            Text('营业执照信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 16 })

            this.RecordRow('统一社会信用代码', '91110108567891234X')
            this.RecordRow('法定代表人', '周源')
            this.RecordRow('注册资本', '1000 万人民币')
            this.RecordRow('注册地址', '北京市海淀区中关村')
            this.RecordRow('经营范围', '技术开发、技术服务、互联网信息服务等')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 8 })

          // Footer
          Column() {
            Text('如您对以上信息有疑问，请联系我们')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 12 })
            Text('客服邮箱：support@zhihu.com')
              .fontSize(12)
              .fontColor('#0066FF')
              .margin({ top: 4, bottom: 24 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
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
  RecordRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#999999')
        .width(130)
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 0.5 }, color: '#F5F5F5' })
  }
}
