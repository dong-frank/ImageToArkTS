import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

// Storage item data model
interface StorageItemData {
  label: string;
  value: string;
  description?: string;
  actionLabel?: string;
  actionType?: 'clear' | 'manage';
  colorHint?: string;
}

@Entry
@Component
struct StorageSpace {
  @State showClearDialog: boolean = false;

  // Storage items data
  private storageItems: StorageItemData[] = [
    {
      label: '大众点评已用空间',
      value: '1.2 GB',
      description: '占据手机不足 1% 存储空间',
      colorHint: '#FF6600'
    },
    {
      label: '缓存',
      value: '253.3 MB',
      description: '缓存是使用大众点评过程中产生的临时数据，清理缓存不会影响大众点评的正常使用',
      actionLabel: '清理',
      actionType: 'clear',
      colorHint: '#FF6600'
    },
    {
      label: '草稿箱',
      value: '19.7 KB',
      description: '清理后草稿内容将不再保留，若需保留，可发布草稿以释放相应存储空间',
      actionLabel: '管理',
      actionType: 'manage',
      colorHint: '#4A90D9'
    },
    {
      label: '必要文件',
      value: '921.3 MB',
      description: '包含大众点评运行所需的必要文件，该类别的大小因当前大众点评的使用状态而异',
      colorHint: '#999999'
    }
  ];

  // Calculate progress bar widths
  // Total: 1.2 GB = 1228.8 MB; Cache: 253.3 MB; Drafts: 0.0197 MB; Necessary: 921.3 MB
  private cachePercent: number = (253.3 / 1228.8) * 100;
  private draftsPercent: number = (0.0197 / 1228.8) * 100;
  private necessaryPercent: number = (921.3 / 1228.8) * 100;

  build() {
    Stack() {
      Column() {
        // Navigation bar
        Row() {
          Text('←')
            .fontSize(22)
            .fontColor('#333333')
            .padding({ left: 16, right: 8, top: 12, bottom: 12 })
            .onClick(() => {
              router.back();
            })

          Text('存储空间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Blank()
        }
        .width('100%')
        .height(48)
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

        // Scrollable content
        Scroll() {
          Column() {
            // Progress bar section
            Column() {
              // Segmented progress bar
              Row() {
                // Cache segment (orange)
                Row()
                  .width(`${this.cachePercent}%`)
                  .height(8)
                  .backgroundColor('#FF6600')
                  .borderRadius({ topLeft: 4, bottomLeft: 4 })

                // Drafts segment (blue)
                Row()
                  .width(`${this.draftsPercent}%`)
                  .height(8)
                  .backgroundColor('#4A90D9')

                // Necessary files segment (gray)
                Row()
                  .width(`${this.necessaryPercent}%`)
                  .height(8)
                  .backgroundColor('#CCCCCC')
                  .borderRadius({ topRight: 4, bottomRight: 4 })
              }
              .width('100%')
              .height(8)
              .borderRadius(4)
              .backgroundColor('#F0F0F0')

              // Legend
              Row({ space: 24 }) {
                Row({ space: 6 }) {
                  Row()
                    .width(10)
                    .height(10)
                    .borderRadius(2)
                    .backgroundColor('#FF6600')
                  Text('缓存')
                    .fontSize(12)
                    .fontColor('#999999')
                }

                Row({ space: 6 }) {
                  Row()
                    .width(10)
                    .height(10)
                    .borderRadius(2)
                    .backgroundColor('#4A90D9')
                  Text('草稿箱')
                    .fontSize(12)
                    .fontColor('#999999')
                }

                Row({ space: 6 }) {
                  Row()
                    .width(10)
                    .height(10)
                    .borderRadius(2)
                    .backgroundColor('#CCCCCC')
                  Text('必要文件')
                    .fontSize(12)
                    .fontColor('#999999')
                }
              }
              .margin({ top: 12 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 20, bottom: 16 })
            .backgroundColor('#FFFFFF')

            // Spacing
            Row()
              .width('100%')
              .height(10)
              .backgroundColor('#F5F5F5')

            // Storage detail items
            Column() {
              ForEach(this.storageItems, (item: StorageItemData, index: number) => {
                Column() {
                  // Item header: label + value
                  Row() {
                    Text(item.label)
                      .fontSize(16)
                      .fontColor('#333333')
                      .fontWeight(FontWeight.Medium)

                    Blank()

                    Text(item.value)
                      .fontSize(16)
                      .fontColor('#333333')
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')
                  .margin({ bottom: 6 })

                  // Description text
                  if (item.description) {
                    Text(item.description)
                      .fontSize(13)
                      .fontColor('#999999')
                      .lineHeight(18)
                      .width('100%')
                      .margin({ bottom: item.actionLabel ? 12 : 0 })
                  }

                  // Action button
                  if (item.actionLabel) {
                    Row() {
                      Button(item.actionLabel)
                        .fontSize(14)
                        .fontColor(item.actionType === 'clear' ? '#FFFFFF' : '#FF6600')
                        .backgroundColor(item.actionType === 'clear' ? '#FF6600' : '#FFFFFF')
                        .border({
                          width: item.actionType === 'clear' ? 0 : 1,
                          color: '#FF6600',
                          radius: 4
                        })
                        .height(32)
                        .padding({ left: 16, right: 16 })
                        .onClick(() => {
                          if (item.actionType === 'clear') {
                            this.showClearDialog = true;
                          } else if (item.actionType === 'manage') {
                            // 草稿箱管理页目标未覆盖，显示提示
                            promptAction.showToast({
                              message: '草稿箱管理功能开发中',
                              duration: 2000
                            });
                          }
                        })
                    }
                    .margin({ bottom: 4 })
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                .backgroundColor('#FFFFFF')

                // Divider between items (except last)
                if (index < this.storageItems.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#F0F0F0')
                    .margin({ left: 16 })
                }
              })
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // Clear cache confirmation dialog
      if (this.showClearDialog) {
        Column() {
          Column() {
            Text('确认清理缓存')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ bottom: 12 })

            Text('清理缓存不会影响大众点评的正常使用，确认清理 253.3 MB 缓存数据？')
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(20)
              .textAlign(TextAlign.Center)
              .margin({ bottom: 20 })

            Row() {
              Button('取消')
                .fontSize(15)
                .fontColor('#666666')
                .backgroundColor('#F5F5F5')
                .layoutWeight(1)
                .height(44)
                .borderRadius(8)
                .onClick(() => {
                  this.showClearDialog = false;
                })

              Button('确认清理')
                .fontSize(15)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF6600')
                .layoutWeight(1)
                .height(44)
                .borderRadius(8)
                .margin({ left: 12 })
                .onClick(() => {
                  this.showClearDialog = false;
                  promptAction.showToast({
                    message: '缓存已清理',
                    duration: 2000
                  });
                })
            }
            .width('100%')
          }
          .width('80%')
          .padding(24)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => {
            // Prevent click from bubbling to backdrop dismiss
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          // Tap outside to dismiss
          this.showClearDialog = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
