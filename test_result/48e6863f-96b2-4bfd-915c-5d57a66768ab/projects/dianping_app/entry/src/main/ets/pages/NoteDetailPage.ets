import router from '@ohos.router';

@Entry
@Component
struct NoteDetailPage {
  @State currentImageIndex: number = 1;
  @State totalImages: number = 18;
  @State isLiked: boolean = false;
  @State isFavorited: boolean = false;
  @State likeCount: number = 20;
  @State favoriteCount: number = 17;

  build() {
    Column() {
      // Top Navigation Bar
      this.TopBar();

      // Scrollable content area
      Scroll() {
        Column() {
          // Image Carousel Area
          this.ImageCarousel();

          // Content Header - Trend tag + View count
          this.ContentHeader();

          // Title and Body
          this.TitleAndBody();

          // Location Info
          this.LocationInfo();

          // Business Card
          this.BusinessCard();

          // Action Bar
          this.ActionBar();

          // Promo Badge
          this.PromoBadge();
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // Top Navigation Bar
  @Builder
  TopBar() {
    Row() {
      // Back button
      Text('←')
        .fontSize(24)
        .fontColor('#333333')
        .onClick(() => {
          router.back();
        })

      Blank()

      // Avatar + Nickname
      Row() {
        Circle()
          .width(28)
          .height(28)
          .fill('#FF6B35')
        Text('万君')
          .fontSize(14)
          .fontColor('#333333')
          .margin({ left: 6 })
      }

      Blank()

      // Badge
      Text('5星真探官 >')
        .fontSize(11)
        .fontColor('#FF6600')
        .backgroundColor('#FFF5EB')
        .borderRadius(10)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })

      // Follow button
      Text('关注')
        .fontSize(12)
        .fontColor('#FF6600')
        .border({ width: 1, color: '#FF6600', style: BorderStyle.Solid })
        .borderRadius(12)
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .margin({ left: 8 })

      // Share button
      Text('↗')
        .fontSize(20)
        .fontColor('#333333')
        .margin({ left: 8 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  // Image Carousel
  @Builder
  ImageCarousel() {
    Stack() {
      // Main image placeholder
      Column() {
        Row() {
          Text('实况')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6600')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
        .width('100%')
        .padding({ left: 12, top: 12 })
        .zIndex(1)

        // Image area
        Column() {
          Text('🖼️')
            .fontSize(64)
            .opacity(0.3)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F0F0F0')
      }
      .width('100%')
      .height(320)
      .borderRadius(8)

      // Image index indicator
      Text(`${this.currentImageIndex}/${this.totalImages}`)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .backgroundColor('rgba(0,0,0,0.5)')
        .borderRadius(10)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .position({ right: 12, bottom: 12 })
    }
    .width('100%')
    .height(320)
  }

  // Content Header
  @Builder
  ContentHeader() {
    Column() {
      Row() {
        Text('新趋势 | 地方菜新大陆被我挖到了')
          .fontSize(13)
          .fontColor('#FF6600')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Text('3860.3万浏览 >')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })
    }
  }

  // Title and Body
  @Builder
  TitleAndBody() {
    Column() {
      Text('仙林!!! 居然有这种好地方!!!!')
        .fontSize(20)
        .fontColor('#1A1A1A')
        .fontWeight(FontWeight.Bold)
        .lineHeight(28)
        .width('100%')
        .padding({ left: 16, right: 16, top: 8 })

      Text('真的要被南京这家农家乐美°晕了！')
        .fontSize(15)
        .fontColor('#666666')
        .lineHeight(22)
        .width('100%')
        .padding({ left: 16, right: 16, top: 6 })
        .maxLines(3)
    }
  }

  // Location Info
  @Builder
  LocationInfo() {
    Row() {
      Text('📍')
        .fontSize(16)
      Text('东部山庄·农家乐·4.5星')
        .fontSize(14)
        .fontColor('#333333')
        .margin({ left: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
  }

  // Business Card
  @Builder
  BusinessCard() {
    Row() {
      // Business avatar
      Circle()
        .width(40)
        .height(40)
        .fill('#FF6B35')

      Column() {
        Text('东部山庄·农家乐')
          .fontSize(15)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      .layoutWeight(1)

      Text('进店 >')
        .fontSize(13)
        .fontColor('#FF6600')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ left: 16, right: 16, top: 12 })
    .backgroundColor('#FFF9F5')
    .borderRadius(8)
  }

  // Action Bar
  @Builder
  ActionBar() {
    Row() {
      // Like button
      Row() {
        Text(this.isLiked ? '❤️' : '🤍')
          .fontSize(22)
        Text(`${this.likeCount}`)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ left: 4 })
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

      // Favorite button
      Row() {
        Text(this.isFavorited ? '⭐' : '☆')
          .fontSize(22)
        Text(`${this.favoriteCount}`)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ left: 4 })
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

      // Comment button
      Row() {
        Text('💬')
          .fontSize(22)
        Text('评论')
          .fontSize(13)
          .fontColor('#999999')
          .margin({ left: 4 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  // Promo Badge
  @Builder
  PromoBadge() {
    Row() {
      Text('🏷️')
        .fontSize(16)
      Text('周周抢')
        .fontSize(12)
        .fontColor('#FF6600')
        .margin({ left: 4 })
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor('#FFF5EB')
    .borderRadius(12)
    .margin({ left: 16, top: 8, bottom: 24 })
  }
}
