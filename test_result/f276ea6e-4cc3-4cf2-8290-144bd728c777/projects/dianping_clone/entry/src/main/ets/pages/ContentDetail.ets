import router from '@ohos.router';

@Entry
@Component
struct ContentDetail {
  @State isFollowed: boolean = false;
  @State currentImageIndex: number = 1;
  @State totalImages: number = 18;
  @State likeCount: number = 20;
  @State isLiked: boolean = false;
  @State favoriteCount: number = 17;
  @State isFavorited: boolean = false;
  @State showMoreMenu: boolean = false;

  build() {
    Stack() {
      Column() {
        // Navigation Bar
        Row() {
          // Back button
          Button() {
            Text('\u2190')
              .fontSize(22)
              .fontColor('#333333')
          }
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .width(40)
          .height(40)
          .onClick(() => {
            router.back();
          })

          Blank()

          // More button
          Button() {
            Text('\u22EF')
              .fontSize(22)
              .fontColor('#333333')
          }
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .width(40)
          .height(40)
          .onClick(() => {
            this.showMoreMenu = !this.showMoreMenu;
          })
        }
        .width('100%')
        .height(48)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#FFFFFF')

        // Scrollable content area
        Scroll() {
          Column() {
            // Author Header
            Row({ space: 10 }) {
              // Avatar
              Circle()
                .width(40)
                .height(40)
                .fill('#FF6B35')

              Column({ space: 2 }) {
                Row({ space: 6 }) {
                  Text('万君')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')

                  // Badge
                  Text('5星真探官')
                    .fontSize(10)
                    .fontColor('#FF6B35')
                    .backgroundColor('#FFF3ED')
                    .borderRadius(4)
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                }

                Text('3860.3万浏览')
                  .fontSize(11)
                  .fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              // Follow button
              Button() {
                Text(this.isFollowed ? '已关注' : '关注')
                  .fontSize(13)
                  .fontColor(this.isFollowed ? '#999999' : '#FF6B35')
              }
              .type(ButtonType.Normal)
              .backgroundColor(this.isFollowed ? '#F5F5F5' : '#FFF3ED')
              .borderRadius(14)
              .height(28)
              .padding({ left: 14, right: 14 })
              .onClick(() => {
                this.isFollowed = !this.isFollowed;
              })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor('#FFFFFF')

            // Image Carousel
            Stack() {
              // Placeholder image area
              Column() {
                Text('探店图片')
                  .fontSize(14)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .height(280)
              .backgroundColor('#F0F0F0')
              .justifyContent(FlexAlign.Center)

              // Image index indicator
              Text(`${this.currentImageIndex}/${this.totalImages}`)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor('rgba(0, 0, 0, 0.5)')
                .borderRadius(10)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .position({ right: 12, bottom: 12 })

              // "实况" label
              Text('实况')
                .fontSize(11)
                .fontColor('#FFFFFF')
                .backgroundColor('rgba(0, 0, 0, 0.4)')
                .borderRadius(4)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .position({ left: 12, top: 12 })

              // Swipe areas for carousel
              Row() {
                // Left tap area - previous image
                Column()
                  .width('50%')
                  .height('100%')
                  .onClick(() => {
                    if (this.currentImageIndex > 1) {
                      this.currentImageIndex--;
                    }
                  })

                // Right tap area - next image
                Column()
                  .width('50%')
                  .height('100%')
                  .onClick(() => {
                    if (this.currentImageIndex < this.totalImages) {
                      this.currentImageIndex++;
                    }
                  })
              }
              .width('100%')
              .height('100%')
            }
            .width('100%')
            .height(280)

            // Content Body
            Column({ space: 8 }) {
              // Trend tag + subtitle row
              Row({ space: 8 }) {
                Text('新趋势')
                  .fontSize(11)
                  .fontColor('#FF6B35')
                  .backgroundColor('#FFF3ED')
                  .borderRadius(4)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })

                Text('地方菜新大陆被我挖到了')
                  .fontSize(14)
                  .fontColor('#666666')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }

              // Headline
              Text('仙林!!! 居然有这种好地方!!!!')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#222222')
                .lineHeight(28)

              // Summary
              Text('真的要被南京这家农家乐美\u00B0晕了！')
                .fontSize(15)
                .fontColor('#555555')
                .lineHeight(22)

              // Location tag
              Row({ space: 6 }) {
                Text('\uD83D\uDCCD')
                  .fontSize(14)
                Text('东部山庄\u00B7农家乐\u00B74.5星')
                  .fontSize(14)
                  .fontColor('#FF6B35')
                  .fontWeight(FontWeight.Medium)
              }
              .margin({ top: 4 })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 14, bottom: 10 })
            .backgroundColor('#FFFFFF')
            .alignItems(HorizontalAlign.Start)

            // CTA Button - "进店 >"
            Row() {
              Button() {
                Row({ space: 4 }) {
                  Text('进店')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#FFFFFF')
                  Text('>')
                    .fontSize(15)
                    .fontColor('#FFFFFF')
                }
              }
              .type(ButtonType.Normal)
              .backgroundColor('#FF6B35')
              .borderRadius(20)
              .height(40)
              .padding({ left: 24, right: 24 })
              .onClick(() => {
                // Unresolved target: 商家详情页 not yet covered
                // Keep as placeholder - do not implement as confirmed route
                console.info('[ContentDetail] 进店按钮点击 - 目标商家详情页未覆盖');
              })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor('#FFFFFF')
            .justifyContent(FlexAlign.Start)

            // Interaction Bar
            Row() {
              // Like
              Row({ space: 4 }) {
                Text(this.isLiked ? '\uD83D\uDC4D' : '\uD83D\uDC4D')
                  .fontSize(18)
                Text(`${this.likeCount}`)
                  .fontSize(13)
                  .fontColor(this.isLiked ? '#FF6B35' : '#666666')
              }
              .onClick(() => {
                this.isLiked = !this.isLiked;
                if (this.isLiked) {
                  this.likeCount++;
                } else {
                  this.likeCount--;
                }
              })

              Blank()

              // Favorite
              Row({ space: 4 }) {
                Text(this.isFavorited ? '\u2B50' : '\u2606')
                  .fontSize(18)
                Text(`${this.favoriteCount}`)
                  .fontSize(13)
                  .fontColor(this.isFavorited ? '#FF6B35' : '#666666')
              }
              .onClick(() => {
                this.isFavorited = !this.isFavorited;
                if (this.isFavorited) {
                  this.favoriteCount++;
                } else {
                  this.favoriteCount--;
                }
              })

              Blank()

              // Comment
              Row({ space: 4 }) {
                Text('\uD83D\uDCAC')
                  .fontSize(18)
                Text('评论')
                  .fontSize(13)
                  .fontColor('#666666')
              }
              .onClick(() => {
                console.info('[ContentDetail] 评论按钮点击');
              })

              Blank()

              // Share
              Row({ space: 4 }) {
                Text('\u2197')
                  .fontSize(18)
                Text('分享')
                  .fontSize(13)
                  .fontColor('#666666')
              }
              .onClick(() => {
                console.info('[ContentDetail] 分享按钮点击');
              })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor('#FFFFFF')

            // Promo badge area
            Row() {
              Text('周周抢')
                .fontSize(11)
                .fontColor('#FF6B35')
                .backgroundColor('#FFF3ED')
                .borderRadius(4)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            }
            .width('100%')
            .padding({ left: 14, right: 14, bottom: 20 })
            .backgroundColor('#FFFFFF')
            .justifyContent(FlexAlign.End)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      // More menu overlay
      if (this.showMoreMenu) {
        Column() {
          // Backdrop
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.3)')
            .onClick(() => {
              this.showMoreMenu = false;
            })
        }
        .width('100%')
        .height('100%')

        // Menu panel
        Column({ space: 0 }) {
          Row() {
            Text('分享')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .onClick(() => {
            this.showMoreMenu = false;
            console.info('[ContentDetail] 更多菜单 - 分享');
          })

          Divider()
            .height(0.5)
            .color('#EEEEEE')

          Row() {
            Text('举报')
              .fontSize(16)
              .fontColor('#333333')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .onClick(() => {
            this.showMoreMenu = false;
            console.info('[ContentDetail] 更多菜单 - 举报');
          })

          Divider()
            .height(0.5)
            .color('#EEEEEE')

          Row() {
            Text('取消')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showMoreMenu = false;
          })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius({ topLeft: 12, topRight: 12 })
        .position({ bottom: 0 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
