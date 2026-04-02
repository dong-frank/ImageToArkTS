import router from '@ohos.router';

interface NoteEdit_ToolItem {
  icon: string;
  isActive: boolean;
}

interface NoteEdit_AddMenuItem {
  name: string;
  icon: string;
}

interface NoteEdit_ColorItem {
  color: string;
}

@Entry
@Component
struct NoteEdit {
  @State currentTool: string = 'pen';
  @State showAddMenu: boolean = false;
  @State showColorPicker: boolean = false;
  @State colorPickerTab: string = 'grid';
  @State showShapePicker: boolean = false;
  @State showSignaturePad: boolean = false;
  @State noteContent: string = `交通：一个半小时到虹桥站……
疯狂动物城
小熊维尼
冰雪奇缘：欢唱盛会 13:15
8.55开车 9.24到 上电梯右转 9.32坐下来`;
  @State selectedColor: string = '#000000';
  @State hdrValue: number = -100;
  @State opacityValue: number = 100;
  @State redValue: number = 0;
  @State greenValue: number = 0;
  @State blueValue: number = 0;

  private tools: Array<NoteEdit_ToolItem> = [
    { icon: 'pen', isActive: true },
    { icon: 'pen-thin', isActive: false },
    { icon: 'highlighter', isActive: false },
    { icon: 'eraser', isActive: false },
    { icon: 'pencil', isActive: false }
  ];

  private addMenuItems: Array<NoteEdit_AddMenuItem> = [
    { name: '添加贴纸', icon: 'sticker' },
    { name: '添加文本', icon: 'text' },
    { name: '添加签名', icon: 'signature' },
    { name: '添加形状', icon: 'shape' },
    { name: '添加放大镜', icon: 'magnifier' }
  ];

  private colors: Array<NoteEdit_ColorItem> = [
    { color: '#FF0000' }, { color: '#FFA500' }, { color: '#FFFF00' }, { color: '#008000' }, { color: '#0000FF' },
    { color: '#4B0082' }, { color: '#EE82EE' }, { color: '#808080' }, { color: '#000000' }, { color: '#FFFFFF' }
  ];

  private shapes: Array<string> = ['square', 'rounded-square', 'circle', 'triangle', 'hexagon', 'arrow-right', 'star', 'speech-bubble', 'arrow-diagonal'];

  @Builder
  ToolBarBuilder() {
    Row({ space: 20 }) {
      ForEach(this.tools, (tool: NoteEdit_ToolItem) => {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.startIcon'))
            .fillColor(tool.isActive ? '#FF0000' : '#CCCCCC')
        }
        .width(40)
        .height(40)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          this.tools.forEach(t => t.isActive = false);
          tool.isActive = true;
          this.currentTool = tool.icon;
        })
      })

      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.startIcon'))
          .fillColor(this.selectedColor)
      }
      .width(40)
      .height(40)
      .backgroundColor('#F5F5F5')
      .onClick(() => {
        this.showColorPicker = true;
      })

      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(24)
          .fontColor('#333333')
      }
      .width(40)
      .height(40)
      .backgroundColor('#F5F5F5')
      .onClick(() => {
        this.showAddMenu = true;
      })
    }
    .padding(10)
    .backgroundColor('rgba(245,245,245,0.9)')
    .borderRadius(20)
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
  }

  @Builder
  AddMenuBuilder() {
    Column() {
      ForEach(this.addMenuItems, (item: NoteEdit_AddMenuItem) => {
        Row({ space: 15 }) {
          Image($r('app.media.startIcon'))
            .width(24)
            .height(24)
            .fillColor('#666666')
          Text(item.name)
            .fontSize(16)
            .fontColor('#333333')
        }
        .width('100%')
        .padding(15)
        .onClick(() => {
          this.showAddMenu = false;
          if (item.name === '添加签名') {
            this.showSignaturePad = true;
          } else if (item.name === '添加形状') {
            this.showShapePicker = true;
          } else if (item.name === '添加文本') {
            this.noteContent += '\n[新文本]';
          }
        })
      })
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 10, color: '#000000', offsetX: 0, offsetY: 2 })
    .width('90%')
  }

  @Builder
  ColorPickerBuilder() {
    Column() {
      Row({ space: 20 }) {
        Button('网格', { type: ButtonType.Normal })
          .fontColor(this.colorPickerTab === 'grid' ? '#007AFF' : '#666666')
          .onClick(() => { this.colorPickerTab = 'grid'; })
        Button('光谱', { type: ButtonType.Normal })
          .fontColor(this.colorPickerTab === 'spectrum' ? '#007AFF' : '#666666')
          .onClick(() => { this.colorPickerTab = 'spectrum'; })
        Button('滑块', { type: ButtonType.Normal })
          .fontColor(this.colorPickerTab === 'slider' ? '#007AFF' : '#666666')
          .onClick(() => { this.colorPickerTab = 'slider'; })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ bottom: 20 })

      if (this.colorPickerTab === 'grid') {
        Text('HDR 增强')
          .fontSize(14)
          .fontColor('#333333')
          .margin({ top: 20 })
        Slider({
          value: this.hdrValue,
          min: -100,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .onChange((value: number) => {
          this.hdrValue = value;
        })

        Text('不透明度')
          .fontSize(14)
          .fontColor('#333333')
          .margin({ top: 20 })
        Slider({
          value: this.opacityValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .onChange((value: number) => {
          this.opacityValue = value;
        })
      } else if (this.colorPickerTab === 'slider') {
        Text('红色')
          .fontSize(14)
          .fontColor('#333333')
        Slider({
          value: this.redValue,
          min: 0,
          max: 255,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .onChange((value: number) => {
          this.redValue = value;
          this.updateColorFromRGB();
        })

        Text('绿色')
          .fontSize(14)
          .fontColor('#333333')
          .margin({ top: 10 })
        Slider({
          value: this.greenValue,
          min: 0,
          max: 255,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .onChange((value: number) => {
          this.greenValue = value;
          this.updateColorFromRGB();
        })

        Text('蓝色')
          .fontSize(14)
          .fontColor('#333333')
          .margin({ top: 10 })
        Slider({
          value: this.blueValue,
          min: 0,
          max: 255,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('100%')
        .onChange((value: number) => {
          this.blueValue = value;
          this.updateColorFromRGB();
        })

        Text(`Hex: ${this.selectedColor}`)
          .fontSize(14)
          .fontColor('#333333')
          .margin({ top: 20 })
      }

      Row({ space: 20 }) {
        Button('取消', { type: ButtonType.Normal })
          .fontColor('#666666')
          .onClick(() => {
            this.showColorPicker = false;
          })
        Button('确定', { type: ButtonType.Normal })
          .fontColor('#007AFF')
          .onClick(() => {
            this.showColorPicker = false;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 30 })
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 10, color: '#000000', offsetX: 0, offsetY: 2 })
    .width('80%')
  }

  @Builder
  ShapePickerBuilder() {


  }

  @Builder
  SignaturePadBuilder() {
    Column() {
      Row({ space: 20 }) {
        Button('X')
          .fontSize(18)
          .fontColor('#666666')
          .onClick(() => {
            this.showSignaturePad = false;
          })
        Text('新签名')
          .fontSize(18)
          .fontColor('#333333')
          .flexGrow(1)
          .textAlign(TextAlign.Center)
        Button('✓')
          .fontSize(18)
          .fontColor('#FFCC00')
          .onClick(() => {
            this.showSignaturePad = false;
            this.noteContent += '\n[签名]';
          })
      }
      .width('100%')
      .padding({ bottom: 20 })

      Column() {
        Text('画布区域')
          .fontSize(16)
          .fontColor('#999999')
      }
      .width('100%')
      .height(200)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, style: BorderStyle.Dashed, color: '#CCCCCC' })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text('用手指签名')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 10 })

      Button('清除')
      .margin({ top: 20 })
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 10, color: '#000000', offsetX: 0, offsetY: 2 })
    .width('90%')
  }

  private updateColorFromRGB() {
    const r = this.redValue.toString(16).padStart(2, '0');
    const g = this.greenValue.toString(16).padStart(2, '0');
    const b = this.blueValue.toString(16).padStart(2, '0');
    this.selectedColor = `#${r}${g}${b}`;
  }

  build() {
    Stack() {
      Column() {
        Row({ space: 20 }) {
          Button('<')
            .fontSize(24)
            .fontColor('#333333')
            .backgroundColor('#F0F0F0')
            .width(40)
            .height(40)
            .borderRadius(20)
            .onClick(() => {
              router.back();
            })

          Text('迪士尼')
            .fontSize(20)
            .fontColor('#333333')
            .flexGrow(1)
            .textAlign(TextAlign.Center)

          Button('...')
            .fontSize(24)
            .fontColor('#333333')
            .backgroundColor('#F0F0F0')
            .width(40)
            .height(40)
            .borderRadius(8)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/MemoDetail_menu'
              })
              .then(() => {})
              .catch((err: Error) => {});
            })

          Button('✓')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .backgroundColor('#FFCC00')
            .width(40)
            .height(40)
            .borderRadius(20)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/MemoList'
              })
              .then(() => {})
              .catch((err: Error) => {});
            })
        }
        .width('100%')
        .padding(10)

        Scroll() {
          Text(this.noteContent)
            .fontSize(16)
            .fontColor('#000000')
            .textAlign(TextAlign.Start)
            .lineHeight(24)
            .width('100%')
            .padding(20)
        }
        .flexGrow(1)
        .backgroundColor('#FFFFFF')
        .margin({ top: 10 })

        this.ToolBarBuilder()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      if (this.showAddMenu) {
        Column() {
          this.AddMenuBuilder()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('rgba(0,0,0,0.3)')
      }

      if (this.showColorPicker) {
        Column() {
          this.ColorPickerBuilder()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('rgba(0,0,0,0.3)')
      }

      if (this.showShapePicker) {
        Column() {
          this.ShapePickerBuilder()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('rgba(0,0,0,0.3)')
      }

      if (this.showSignaturePad) {
        Column() {
          this.SignaturePadBuilder()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('rgba(0,0,0,0.3)')
      }
    }
    .width('100%')
    .height('100%')
  }
}