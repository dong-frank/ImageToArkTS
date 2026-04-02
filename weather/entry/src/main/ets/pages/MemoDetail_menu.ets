import router from '@ohos.router';

interface IndexMenuItem {
  text: string;
  note: string;
}

@Entry
@Component
struct Index {
  @State private isMenuVisible: boolean = false;
  @State private isAttachmentViewExpanded: boolean = false;
  @State private isMathResultExpanded: boolean = false;
  @State private isRecentNotesExpanded: boolean = false;
  @State private memoContent: string = `雷鸣山漂流
小勇者营地
旋转蜂蜜罐
8.55开车 9.24 上电梯右转 9.32坐下来`;
  @State private recentNotes: Array<string> = ['迪士尼', '但是还是好', '购物清单', '会议记录'];
  @State private mathResultOption: string = '建议结果';

  @Builder
  ActionSheetMenu() {
    Column() {
      Column() {
        Row() {
          Image($r('sys.media.AI_search'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .margin({ right: 12 })
          Text('扫描')
            .fontSize(16)
            .fontColor('#1C1C1E')
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.Start)
        .padding({ left: 16 })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/Scan'
          }).then(() => {}).catch((err: Error) => {});
        })

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Row() {
          Image($r('sys.media.balloon_fill'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .margin({ right: 12 })
          Text('置顶备忘录')
            .fontSize(16)
            .fontColor('#1C1C1E')
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.Start)
        .padding({ left: 16 })
        .onClick(() => {
          console.log('置顶备忘录');
        })

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Row() {
          Image($r('sys.media.person_shield'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .margin({ right: 12 })
          Text('锁定')
            .fontSize(16)
            .fontColor('#1C1C1E')
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.Start)
        .padding({ left: 16 })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/LockGuide'
          }).then(() => {}).catch((err: Error) => {});
        })
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 8 })

      Column() {
        Row() {
          Image($r('sys.media.AI_search'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .margin({ right: 12 })
          Text('在备忘录中查找')
            .fontSize(16)
            .fontColor('#1C1C1E')
          Blank()
          Image($r('sys.media.arrowshape_3_triangle_path'))
            .width(16)
            .height(16)
            .fillColor('#757575')
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          console.log('在备忘录中查找');
        })

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Row() {
          Image($r('sys.media.waveform_folder_fill'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .margin({ right: 12 })
          Text('移动备忘录')
            .fontSize(16)
            .fontColor('#1C1C1E')
          Blank()
          Image($r('sys.media.arrowshape_3_triangle_path'))
            .width(16)
            .height(16)
            .fillColor('#757575')
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          console.log('移动备忘录');
        })

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Column() {
          Row() {
            Image($r('sys.media.media_sound'))
              .width(24)
              .height(24)
              .fillColor('#1C1C1E')
              .margin({ right: 12 })
            Text('最近备忘录')
              .fontSize(16)
              .fontColor('#1C1C1E')
            Blank()
            Image($r('sys.media.arrowshape_3_triangle_path'))
              .width(16)
              .height(16)
              .fillColor('#757575')
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.isRecentNotesExpanded = !this.isRecentNotesExpanded;
          })

          if (this.isRecentNotesExpanded) {
            Column() {
              ForEach(this.recentNotes, (note: string) => {
                Text(note)
                  .fontSize(16)
                  .fontColor('#1C1C1E')
                  .width('100%')
                  .height(48)
                  .padding({ left: 52 })
                  .onClick(() => {
                    console.log('跳转到备忘录:', note);
                  })
                Divider().color('#E5E5EA').strokeWidth(0.5).margin({ left: 52 })
              })
            }
          }
        }

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Column() {
          Row() {
            Image($r('sys.media.AI_form'))
              .width(24)
              .height(24)
              .fillColor('#1C1C1E')
              .margin({ right: 12 })
            Text('数学结果')
              .fontSize(16)
              .fontColor('#1C1C1E')
            Blank()
            Image($r('sys.media.arrowshape_3_triangle_path'))
              .width(16)
              .height(16)
              .fillColor('#757575')
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.isMathResultExpanded = !this.isMathResultExpanded;
          })

          if (this.isMathResultExpanded) {
            Column() {
              Row() {
                Text('插入结果')
                  .fontSize(16)
                  .fontColor('#1C1C1E')
                Blank()
                if (this.mathResultOption === '插入结果') {
                  Image($r('sys.media.anahs_notification_icon'))
                    .width(20)
                    .height(20)
                    .fillColor('#007AFF')
                }
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({ left: 52, right: 16 })
              .onClick(() => {
                this.mathResultOption = '插入结果';
              })

              Divider().color('#E5E5EA').strokeWidth(0.5).margin({ left: 52 })

              Row() {
                Text('建议结果')
                  .fontSize(16)
                  .fontColor('#1C1C1E')
                Blank()
                if (this.mathResultOption === '建议结果') {
                  Image($r('sys.media.anahs_notification_icon'))
                    .width(20)
                    .height(20)
                    .fillColor('#007AFF')
                }
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({ left: 52, right: 16 })
              .onClick(() => {
                this.mathResultOption = '建议结果';
              })

              Divider().color('#E5E5EA').strokeWidth(0.5).margin({ left: 52 })

              Row() {
                Text('关')
                  .fontSize(16)
                  .fontColor('#1C1C1E')
                Blank()
                if (this.mathResultOption === '关') {
                  Image($r('sys.media.anahs_notification_icon'))
                    .width(20)
                    .height(20)
                    .fillColor('#007AFF')
                }
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({ left: 52, right: 16 })
              .onClick(() => {
                this.mathResultOption = '关';
              })
            }
          }
        }

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Row() {
          Image($r('sys.media.AI_panels'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .margin({ right: 12 })
          Text('横线与网格')
            .fontSize(16)
            .fontColor('#1C1C1E')
          Blank()
          Image($r('sys.media.arrowshape_3_triangle_path'))
            .width(16)
            .height(16)
            .fillColor('#757575')
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/GridStyle'
          }).then(() => {}).catch((err: Error) => {});
        })

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Column() {
          Row() {
            Image($r('sys.media.ohos_ic_public_share'))
              .width(24)
              .height(24)
              .fillColor('#1C1C1E')
              .margin({ right: 12 })
            Text('附件视图')
              .fontSize(16)
              .fontColor('#1C1C1E')
            Blank()
            Image($r('sys.media.arrowshape_3_triangle_path'))
              .width(16)
              .height(16)
              .fillColor('#757575')
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.isAttachmentViewExpanded = !this.isAttachmentViewExpanded;
          })

          if (this.isAttachmentViewExpanded) {
            Column() {
              Text('全部设为小尺寸')
                .fontSize(16)
                .fontColor('#1C1C1E')
                .width('100%')
                .height(48)
                .padding({ left: 52 })
                .onClick(() => {
                  console.log('全部设为小尺寸');
                })
              Divider().color('#E5E5EA').strokeWidth(0.5).margin({ left: 52 })
              Text('全部设为大尺寸')
                .fontSize(16)
                .fontColor('#1C1C1E')
                .width('100%')
                .height(48)
                .padding({ left: 52 })
                .onClick(() => {
                  console.log('全部设为大尺寸');
                })
            }
          }
        }

        Divider().color('#E5E5EA').strokeWidth(0.5)

        Row() {
          Image($r('sys.media.rectangle_filled_and_line_horizontal_and_rectangle'))
            .width(24)
            .height(24)
            .fillColor('#FF3B30')
            .margin({ right: 12 })
          Text('删除')
            .fontSize(16)
            .fontColor('#FF3B30')
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.Start)
        .padding({ left: 16 })
        .onClick(() => {
          console.log('删除备忘录');
        })
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('80%')
    .alignItems(HorizontalAlign.Start)
    .position({ x: '20%', y: 80 })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Image($r('sys.media.arrowshape_3_triangle_path'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .rotate({ angle: 180 })
            .onClick(() => {
              router.back();
            })
          Blank()
          Text('丝梦游')
            .fontSize(18)
            .fontColor('#1C1C1E')
            .fontWeight(FontWeight.Medium)
          Blank()
          Image($r('sys.media.ic_public_voice_filled'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .onClick(() => {
              this.isMenuVisible = !this.isMenuVisible;
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')

        Scroll() {
          Text(this.memoContent)
            .fontSize(17)
            .fontColor('#1C1C1E')
            .textAlign(TextAlign.Start)
            .width('100%')
            .padding({ top: 16, left: 16, right: 16 })
        }
        .flexGrow(1)
        .backgroundColor('#FFFFFF')

        Row() {
          Image($r('sys.media.AI_panels'))
            .width(28)
            .height(28)
            .fillColor('#1C1C1E')
            .margin({ left: 32, right: 32 })
            .onClick(() => {
              console.log('列表/项目符号');
            })
          Image($r('sys.media.ohos_ic_public_share'))
            .width(28)
            .height(28)
            .fillColor('#1C1C1E')
            .margin({ right: 32 })
            .onClick(() => {
              console.log('添加附件');
            })
          Image($r('sys.media.textformat_size_square_fill'))
            .width(28)
            .height(28)
            .fillColor('#1C1C1E')
            .margin({ right: 32 })
            .onClick(() => {
              console.log('字体样式');
            })
          Blank()
          Image($r('sys.media.AI_keyboard'))
            .width(28)
            .height(28)
            .fillColor('#1C1C1E')
            .margin({ right: 16 })
            .onClick(() => {
              console.log('编辑');
            })
        }
        .width('100%')
        .height(60)
        .backgroundColor('#FFFFFF')
        .border({ width: { top: 0.5 }, color: '#E5E5EA' })
      }

      if (this.isMenuVisible) {
        Column() {
          this.ActionSheetMenu()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => {
          this.isMenuVisible = false;
          this.isAttachmentViewExpanded = false;
          this.isMathResultExpanded = false;
          this.isRecentNotesExpanded = false;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}