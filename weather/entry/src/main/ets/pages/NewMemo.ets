import router from '@ohos.router';

interface TextEditState {
  textContent: string;
  cursorPosition: number;
}

@Entry
@Component
struct TextEditPage {
  @State private state: TextEditState = {
    textContent: '',
    cursorPosition: 0
  };

  @Builder
  TopNavBar() {
    Row({ space: 12 }) {
      Button({ type: ButtonType.Normal }) {
        Row() {
          Image($r('sys.media.arrowshape_3_triangle_path'))
            .fillColor(Color.Black)
            .width(20)
            .height(20)
        }
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .onClick(() => {
        this.getUIContext().getRouter().pushUrl({ url: 'pages/Index' })
          .then(() => {})
          .catch((err: Error) => {});
      })

      Text('蜂蜜罐')
        .fontColor(Color.Gray)
        .fontSize(16)

      Blank()

      Button({ type: ButtonType.Normal }) {
        Image($r('sys.media.ohos_ic_public_share'))
          .fillColor(Color.Black)
          .width(20)
          .height(20)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .onClick(() => {})

      Button({ type: ButtonType.Normal }) {
        Text('...')
          .fontColor(Color.Black)
          .fontSize(18)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .onClick(() => {})

      Button({ type: ButtonType.Normal }) {
        Image($r('sys.media.AI_circle_viewfinder'))
          .fillColor(Color.White)
          .width(20)
          .height(20)
      }
      .width(40)
      .height(40)
      .backgroundColor('#FFD700')
      .borderRadius(20)
      .onClick(() => {
        this.getUIContext().getRouter().pushUrl({ url: 'pages/Index' })
          .then(() => {})
          .catch((err: Error) => {});
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
  }

  @Builder
  FormatToolbar() {
    Row({ space: 20 }) {
      Button({ type: ButtonType.Normal }) {
        Text('格式')
          .fontColor(Color.Black)
          .fontSize(14)
      }
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .onClick(() => {})

      Button({ type: ButtonType.Normal }) {
        Text('•')
          .fontColor(Color.Black)
          .fontSize(18)
      }
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .onClick(() => {})

      Button({ type: ButtonType.Normal }) {
        Text('田')
          .fontColor(Color.Black)
          .fontSize(14)
      }
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .onClick(() => {})

      Button({ type: ButtonType.Normal }) {
        Text('📎')
          .fontColor(Color.Black)
          .fontSize(14)
      }
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .onClick(() => {})

      Button({ type: ButtonType.Normal }) {
        Text('A')
          .fontColor(Color.Black)
          .fontSize(14)
      }
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .onClick(() => {})

      Button({ type: ButtonType.Normal }) {
        Text('E')
          .fontColor(Color.Black)
          .fontSize(14)
      }
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .onClick(() => {})
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  @Builder
  VirtualKeyboard() {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        Text('我')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('你')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('但是')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('那')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('不')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('是')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('好')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('这个')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
        Text('▼')
          .fontColor(Color.Black)
          .fontSize(16)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .padding(8)
          .onClick(() => {})
      }

      Row({ space: 4 }) {
        Button('123', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button(',.?!', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('ABC', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('DEF', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('<×', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            if (this.state.textContent.length > 0) {
              this.state.textContent = this.state.textContent.substring(0, this.state.textContent.length - 1);
              this.state.cursorPosition = Math.max(0, this.state.cursorPosition - 1);
            }
          })
      }

      Row({ space: 4 }) {
        Button('#@¥', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('GHI', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('JKL', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('MNO', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('^^', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
      }

      Row({ space: 4 }) {
        Button('ABC', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('PQRS', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('TUV', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('WXYZ', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('←', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.state.textContent += '\n';
            this.state.cursorPosition = this.state.textContent.length;
          })
      }

      Row({ space: 4 }) {
        Button('😊', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('选拼音', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Button('空格', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.state.textContent += ' ';
            this.state.cursorPosition = this.state.textContent.length;
          })
        Button('←', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.state.textContent += '\n';
            this.state.cursorPosition = this.state.textContent.length;
          })
      }

      Row({ space: 4 }) {
        Button('🌐', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
        Blank()
        Button('🎤', { type: ButtonType.Normal })
          .fontColor(Color.Black)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .onClick(() => {})
      }
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#F0F0F0')
    .borderRadius(16)
  }

  build() {
    Column() {
      this.TopNavBar()

      TextArea({ text: this.state.textContent })
        //.placeholder('请输入内容')
        .fontColor(Color.Black)
        .backgroundColor(Color.White)
        .width('100%')
        .height('60%')
        .onChange((value: string) => {
          this.state.textContent = value;
          this.state.cursorPosition = value.length;
        })

      this.FormatToolbar()

      this.VirtualKeyboard()
        //.layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}