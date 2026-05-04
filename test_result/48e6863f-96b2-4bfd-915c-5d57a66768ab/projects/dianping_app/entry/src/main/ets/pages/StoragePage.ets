import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct StoragePage {
  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('存储空间')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row()
          .width(22)
          .height(22)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // Storage overview section
          Column() {
            // Progress bar
            Column() {
              // Simplified progress bar
              Row() {
                Row()
                  .width('2%')
                  .height(8)
                  .backgroundColor('#FF6600')
                  .borderRadius(4)

                Row()
                  .width('48%')
                  .height(8)
                  .backgroundColor('#FFB380')
                  .borderRadius(4)
                  .margin({ left: 2 })

                Row()
                  .width('50%')
                  .height(8)
                  .backgroundColor('#E0E0E0')
                  .borderRadius(4)
                  .margin({ left: 2 })
              }
              .width('100%')
              .margin({ bottom: 16 })

              // Legend
              Row() {
                this.LegendItem('#FF6600', '大众点评已用空间')
                this.LegendItem('#FFB380', '手机已用空间')
                this.LegendItem('#E0E0E0', '手机可用空间')
              }
              .width('100%')
              .margin({ bottom: 20 })
            }
            .width('100%')

            // Space usage
            Text('大众点评已用空间')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ bottom: 8 })

            Text('1.2 GB')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 4 })

            Text('占据手机不足 1% 存储空间')
              .fontSize(13)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 24, bottom: 24 })
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 12 })

          // Storage items
          Column() {
            this.StorageItem(
              '已用空间',
              '1.2 GB',
              '包含应用数据、缓存等',
              '查看详情',
              () => {
                // View details
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.StorageItem(
              '缓存',
              '856 MB',
              '可安全清理，不影响使用',
              '清理',
              () => {
                promptAction.showToast({ message: '缓存已清理' });
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.StorageItem(
              '草稿箱',
              '128 MB',
              '未发布的笔记和评价草稿',
              '管理',
              () => {
                // Manage drafts
              }
            )

            Divider()
              .strokeWidth(0.5)
              .color('#F0F0F0')
              .margin({ left: 16 })

            this.StorageItem(
              '必要文件',
              '216 MB',
              '应用运行必需文件，不可删除',
              '',
              () => {}
            )
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 12, right: 12, top: 12 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  LegendItem(color: string, label: string) {
    Row() {
      Row()
        .width(10)
        .height(10)
        .backgroundColor(color)
        .borderRadius(2)
        .margin({ right: 6 })

      Text(label)
        .fontSize(11)
        .fontColor('#999999')
    }
    .margin({ right: 16 })
  }

  @Builder
  StorageItem(
    title: string,
    size: string,
    description: string,
    actionText: string,
    onAction: () => void
  ) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#333333')
        Text(description)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text(size)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        if (actionText !== '') {
          Text(actionText)
            .fontSize(12)
            .fontColor('#FF6600')
            .margin({ top: 4 })
            .onClick(() => {
              onAction();
            })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }
}
