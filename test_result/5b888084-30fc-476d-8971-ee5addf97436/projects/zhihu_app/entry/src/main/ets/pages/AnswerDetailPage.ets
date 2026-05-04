import router from '@ohos.router';

/**
 * 回答详情页
 * 从信息流卡片点击进入，标准 push/pop 导航。
 * 无底部导航栏。
 */

@Entry
@Component
struct AnswerDetailPage {
  @State isFollowed: boolean = false;
  @State isUpvoted: boolean = true;
  @State isStarred: boolean = false;
  @State isContentExpanded: boolean = false;

  build() {
    Column() {
      // ── 顶部导航栏 ──
      Row() {
        Text('←')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('↗')
          .fontSize(20)
          .fontColor('#666666')
          .margin({ right: 16 })
          .onClick(() => {
            // 分享操作 - 占位
          })
      }
      .width('100%')
      .padding({ top: 8, bottom: 4 })
      .backgroundColor('#ffffff')

      // ── 可滚动内容区 ──
      Scroll() {
        Column() {
          // ── 问题头部 ──
          Column() {
            Text('无大算力时，作为学生，LLM 还有哪些值得做的研究？')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a1a')
              .lineHeight(28)
              .width('100%')
              .padding({ left: 16, right: 16, top: 16 })

            Text('2.4 万人关注')
              .fontSize(13)
              .fontColor('#8590a6')
              .width('100%')
              .padding({ left: 16, right: 16, top: 8 })

            // 操作行：邀请回答 / 写回答 / 搜索
            Row({ space: 0 }) {
              Row({ space: 4 }) {
                Text('✏')
                  .fontSize(14)
                  .fontColor('#0066ff')
                Text('邀请回答')
                  .fontSize(13)
                  .fontColor('#0066ff')
              }
              .border({ width: 1, color: '#0066ff', radius: 4 })
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })

              Row({ space: 4 }) {
                Text('✍')
                  .fontSize(14)
                  .fontColor('#0066ff')
                Text('写回答')
                  .fontSize(13)
                  .fontColor('#0066ff')
              }
              .border({ width: 1, color: '#0066ff', radius: 4 })
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ left: 10 })

              Blank()

              Text('🔍')
                .fontSize(18)
                .fontColor('#666666')
                .padding({ left: 8, right: 4, top: 6, bottom: 6 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          }

          // 分割线
          Divider()
            .strokeWidth(8)
            .color('#f6f6f6')
            .width('100%')

          // ── 回答内容区 ──
          Column() {
            // ── 作者行 ──
            Row() {
              // 头像
              Column() {
                Text('C')
                  .fontSize(16)
                  .fontColor('#ffffff')
                  .fontWeight(FontWeight.Bold)
              }
              .width(40)
              .height(40)
              .borderRadius(20)
              .backgroundColor('#0066ff')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              // 作者信息
              Column() {
                Row({ space: 4 }) {
                  Text('Cv大法代码酱')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1a1a1a')
                  Text('✓')
                    .fontSize(11)
                    .fontColor('#0066ff')
                }
                Text('认证标识')
                  .fontSize(11)
                  .fontColor('#8590a6')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })

              Blank()

              // 关注按钮
              Button(this.isFollowed ? '已关注' : '+ 关注')
                .fontSize(13)
                .fontColor(this.isFollowed ? '#8590a6' : '#0066ff')
                .backgroundColor(this.isFollowed ? '#f6f6f6' : '#e6f0ff')
                .borderRadius(4)
                .height(32)
                .padding({ left: 14, right: 14 })
                .onClick(() => {
                  this.isFollowed = !this.isFollowed;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16 })

            // 赞同数
            Text('3424 人赞同了该回答')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1a1a1a')
              .width('100%')
              .padding({ left: 16, right: 16, top: 14 })

            // 听过数
            Row({ space: 4 }) {
              Text('🔊')
                .fontSize(14)
              Text('13 人听过')
                .fontSize(13)
                .fontColor('#8590a6')
            }
            .padding({ left: 16, top: 6 })

            // ── 回答正文 ──
            Text(
              '看到你说研0非LLM相关，手里没大算力，又觉得RAG和Agent偏工程没什么可研究的，我仿佛看到了五六年前那一波做CV的学生，也是对着ImageNet的大模型望洋兴叹。但其实，咱们得把思路打开，算力贫民窟里也能炼出金子，而且往往这地方出来的东西，比堆算力更有思考深度。'
            )
              .fontSize(16)
              .fontColor('#1a1a1a')
              .lineHeight(26)
              .width('100%')
              .padding({ left: 16, right: 16, top: 14 })

            Text(
              '我们要先打破一个巨大的误区，就是觉得只有预训练Pre-training才叫研究，只有跑得动70B甚至更大的模型才叫搞LLM。这个观点在大厂里盛行，是因为他们有卡，他们有资本去烧。但作为学术界，尤其是作为一个独立的研究者，拼算力你永远拼不过OpenAI和Google，这就像你非要跟法拉利比谁跑直线跑得快，必输无疑。我们得比过弯，比技巧，比对原理的理解。'
            )
              .fontSize(16)
              .fontColor('#1a1a1a')
              .lineHeight(26)
              .width('100%')
              .padding({ left: 16, right: 16, top: 12 })

            // 折叠/展开切换
            if (!this.isContentExpanded) {
              Column() {
                Text('展开阅读全文 ↓')
                  .fontSize(14)
                  .fontColor('#0066ff')
                  .padding({ top: 8, bottom: 8 })
                  .onClick(() => {
                    this.isContentExpanded = true;
                  })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            } else {
              Text(
                '这就引出了第一个极具价值却又被低估的方向：高效推理与模型压缩。不需要预训练，不需要千卡集群，一张消费级显卡甚至纯CPU就能做。量化、剪枝、知识蒸馏、稀疏注意力——这些方向的论文在顶会上的接收率一直很高，因为它们解决的是工业界最真实的需求。'
              )
                .fontSize(16)
                .fontColor('#1a1a1a')
                .lineHeight(26)
                .width('100%')
                .padding({ left: 16, right: 16, top: 12 })

              Row() {
                Text('收起 ↑')
                  .fontSize(14)
                  .fontColor('#0066ff')
                  .padding({ top: 8, bottom: 8 })
                  .onClick(() => {
                    this.isContentExpanded = false;
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
            }
          }

          // 底部留白，避免被底部互动栏遮挡
          Column()
            .height(60)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // ── 底部互动栏 ──
      Column() {
        Row() {
          // 作者缩略信息
          Row({ space: 8 }) {
            Column() {
              Text('C')
                .fontSize(11)
                .fontColor('#ffffff')
                .fontWeight(FontWeight.Bold)
            }
            .width(28)
            .height(28)
            .borderRadius(14)
            .backgroundColor('#0066ff')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text('Cv大法代码酱')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1a1a1a')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 80 })
              Text('+关注')
                .fontSize(10)
                .fontColor('#0066ff')
            }
            .alignItems(HorizontalAlign.Start)
          }
          .padding({ left: 16 })

          Blank()

          // 互动按钮组
          Row({ space: 0 }) {
            // 点赞
            Row({ space: 2 }) {
              Text('▲')
                .fontSize(18)
                .fontColor(this.isUpvoted ? '#0066ff' : '#8590a6')
                .fontWeight(FontWeight.Bold)
              Text('3424')
                .fontSize(12)
                .fontColor(this.isUpvoted ? '#0066ff' : '#8590a6')
            }
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .onClick(() => {
              this.isUpvoted = !this.isUpvoted;
            })

            // 踩
            Row({ space: 2 }) {
              Text('▼')
                .fontSize(14)
                .fontColor('#8590a6')
            }
            .padding({ left: 8, right: 8, top: 8, bottom: 8 })

            // 收藏
            Row({ space: 2 }) {
              Text(this.isStarred ? '★' : '☆')
                .fontSize(20)
                .fontColor(this.isStarred ? '#ff9500' : '#8590a6')
              Text('5917')
                .fontSize(12)
                .fontColor('#8590a6')
            }
            .padding({ left: 8, right: 8, top: 8, bottom: 8 })
            .onClick(() => {
              this.isStarred = !this.isStarred;
            })

            // 评论
            Row({ space: 2 }) {
              Text('💬')
                .fontSize(16)
                .fontColor('#8590a6')
              Text('95')
                .fontSize(12)
                .fontColor('#8590a6')
            }
            .padding({ left: 8, right: 8, top: 8, bottom: 8 })
            .onClick(() => {
              // 评论区导航 - 占位，目标页面未在当前任务边界内且路由未注册
            })

            // 更多
            Text('⋯')
              .fontSize(20)
              .fontColor('#8590a6')
              .padding({ left: 8, right: 12, top: 8, bottom: 8 })
          }
        }
        .width('100%')
        .height(52)
        .backgroundColor('#ffffff')
      }
      .width('100%')
      .backgroundColor('#ffffff')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}
