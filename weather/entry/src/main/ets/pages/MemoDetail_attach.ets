import router from '@ohos.router';

interface NoteItem_Index {
  text: string;
  isUnderlined?: boolean;
}

interface FileItem_Index {
  title: string;
  subtitle: string;
  size: string;
}

interface MenuItem_Index {
  icon: Resource;
  text: string;
}

@Entry
@Component
struct Index {
  @State currentPage: string = 'noteEdit';
  @State noteTitle: string = '迪士尼';
  @State noteContent: Array<NoteItem_Index> = [
    { text: '交通：一个半小时到虹桥站……' },
    { text: '疯狂动物城' },
    { text: '小熊维尼' },
    { text: '加勒比海盗-沉落宝藏之战' },
    { text: '冰雪奇缘：欢唱盛会 13:15', isUnderlined: true },
    { text: '旋转蜂蜜罐' },
    { text: '8.55开车 9.24到' },
    { text: '上电梯右转' },
    { text: '9.32坐下来' }
  ];
  @State recentFiles: Array<FileItem_Index> = [
    { title: '【一年级数学九月学科竞...人证书', subtitle: '2025/11/18', size: '2.7 MB' }
  ];
  @State showAttachmentMenu: boolean = false;
  @State recordingTime: string = '00:00.00';
  @State isRecording: boolean = false;
  @State showRecordMenu: boolean = false;
  @State activeTab: string = 'recent';

  @Builder
  TopNavBar() {
    Row() {
      Image($r('sys.media.arrowshape_3_triangle_path'))
        .width(24)
        .height(24)
        .fillColor('#000000')
        .onClick(() => {
          router.back();
        })
      Text(this.currentPage === 'noteEdit' ? this.noteTitle : (this.currentPage === 'fileManage' ? '最近项目' : '新录音'))
        .fontSize(18)
        .fontColor('#000000')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      if (this.currentPage === 'noteEdit') {
        Image($r('sys.media.ohos_ic_public_share'))
          .width(24)
          .height(24)
          .fillColor('#000000')
          .margin({ right: 16 })
          .onClick(() => {
            console.log('分享');
          })
        Image($r('sys.media.anahs_notification_icon'))
          .width(24)
          .height(24)
          .fillColor('#000000')
          .onClick(() => {
            console.log('更多');
          })
      } else if (this.currentPage === 'fileManage') {
        Image($r('sys.media.AI_search'))
          .width(24)
          .height(24)
          .fillColor('#000000')
          .margin({ right: 16 })
          .onClick(() => {
            console.log('搜索');
          })
        Image($r('sys.media.mic_sound'))
          .width(24)
          .height(24)
          .fillColor('#000000')
          .onClick(() => {
            console.log('语音搜索');
          })
      } else if (this.currentPage === 'record') {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .fillColor('#000000')
          .onClick(() => {
            console.log('保存录音');
            this.currentPage = 'noteEdit';
          })
        Image($r('sys.media.anahs_notification_icon'))
          .width(24)
          .height(24)
          .fillColor('#000000')
          .margin({ left: 16 })
          .onClick(() => {
            this.showRecordMenu = !this.showRecordMenu;
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  NoteEditContent() {
    Column() {
      ForEach(this.noteContent, (item: NoteItem_Index) => {
        Text(item.text)
          .fontSize(16)
          .fontColor('#000000')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ bottom: 8 })
          .decoration({ type: item.isUnderlined ? TextDecorationType.Underline : TextDecorationType.None })
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 80 })
  }

  @Builder
  FileManageContent() {
    Column() {
      Column() {
        Image($r('app.media.startIcon'))
          .width(60)
          .height(80)
          .borderRadius(8)
          .border({ width: 2, color: '#FFD700' })
        Text(this.recentFiles[0].title)
          .fontSize(16)
          .fontColor('#000000')
          .margin({ top: 8 })
          .maxLines(1)
        Text(this.recentFiles[0].subtitle + ' ' + this.recentFiles[0].size)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 4, color: '#20000000', offsetX: 0, offsetY: 2 })
      .margin({ top: 16 })

      Row() {
        Column() {
          Image($r('app.media.startIcon'))
            .width(24)
            .height(24)
            .fillColor(this.activeTab === 'recent' ? '#FFD700' : '#999999')
          Text('最近项目')
            .fontSize(12)
            .fontColor(this.activeTab === 'recent' ? '#FFD700' : '#999999')
            .margin({ top: 4 })
        }
        .onClick(() => { this.activeTab = 'recent'; })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Image($r('sys.media.ohos_ic_public_share'))
            .width(24)
            .height(24)
            .fillColor(this.activeTab === 'shared' ? '#FFD700' : '#999999')
          Text('共享')
            .fontSize(12)
            .fontColor(this.activeTab === 'shared' ? '#FFD700' : '#999999')
            .margin({ top: 4 })
        }
        .onClick(() => { this.activeTab = 'shared'; })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Image($r('sys.media.AI_search'))
            .width(24)
            .height(24)
            .fillColor(this.activeTab === 'browse' ? '#FFD700' : '#999999')
          Text('浏览')
            .fontSize(12)
            .fontColor(this.activeTab === 'browse' ? '#FFD700' : '#999999')
            .margin({ top: 4 })
        }
        .onClick(() => { this.activeTab = 'browse'; })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(60)
      .margin({ top: 32 })
      .border({ width: 1, color: '#F0F0F0' })
    }
    .width('100%')
  }

  @Builder
  RecordContent() {
    Column() {
      Text('今天 10:46 ' + this.recordingTime)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
      Row() {
        ForEach(Array.from({ length: 20 }), () => {
          Rect()
            .width(4)
            .height(40)
            .fill('#FFD700')
            .margin({ right: 2 })
        })
      }
      .height(60)
      .margin({ top: 40 })
      Text(this.recordingTime)
        .fontSize(36)
        .fontColor('#000000')
        .margin({ top: 40 })
      Row() {
        Button('15')
          .width(48)
          .height(48)
          .fontSize(14)
          .fontColor('#666666')
          .border({ width: 1, color: '#CCCCCC', radius: 24 })
          .backgroundColor('#FFFFFF')
          .onClick(() => { console.log('倒退15秒'); })
        Button('15')
          .width(48)
          .height(48)
          .fontSize(14)
          .fontColor('#666666')
          .border({ width: 1, color: '#CCCCCC', radius: 24 })
          .backgroundColor('#FFFFFF')
          .margin({ left: 16 })
          .onClick(() => { console.log('快进15秒'); })
        Image($r('sys.media.AI_play'))
          .width(48)
          .height(48)
          .fillColor('#666666')
          .margin({ left: 32 })
          .onClick(() => { console.log('播放'); })
        Image($r('sys.media.media_sound'))
          .width(24)
          .height(24)
          .fillColor('#666666')
          .margin({ left: 32 })
          .onClick(() => {
            console.log('语音转文字');
          })
        Button('')
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor('#FF3B30')
          .margin({ left: 32 })
          .onClick(() => {
            this.isRecording = !this.isRecording;
            console.log(this.isRecording ? '开始录音' : '停止录音');
          })
      }
      .margin({ top: 40 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ top: 16 })
  }

  @Builder
  AttachmentMenu() {
    Column() {
      this.MenuItem($r('sys.media.AI_search'), '扫描文本')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.MenuItem($r('sys.media.AI_form'), '扫描文稿')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.MenuItem($r('sys.media.AI_phone'), '拍照或录像')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.MenuItem($r('sys.media.AI_panels'), '选取照片或视频')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.MenuItem($r('sys.media.mic_sound'), '录音')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.MenuItem($r('sys.media.waveform_folder_fill'), '附加文件')
    }
    .width('90%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor('#F8F8F8')
    .borderRadius(16)
    .shadow({ radius: 10, color: '#40000000', offsetX: 0, offsetY: -2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  MenuItem(iconRes: Resource, textStr: string) {
    Row() {
      Image(iconRes)
        .width(24)
        .height(24)
        .fillColor('#333333')
        .margin({ left: 16, right: 12 })
      Text(textStr)
        .fontSize(16)
        .fontColor('#000000')
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      console.log('点击了' + textStr);
      if (textStr === '录音') {
        this.currentPage = 'record';
        this.showAttachmentMenu = false;
      } else {
        this.showAttachmentMenu = false;
      }
    })
  }

  @Builder
  RecordMenu() {
    Column() {
      this.RecordMenuItem($r('app.media.startIcon'), '重新命名')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.RecordMenuItem($r('sys.media.waveform_folder_fill'), '将音频保存到‘文件’')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.RecordMenuItem($r('sys.media.ohos_ic_public_share'), '共享音频')
      Divider().strokeWidth(0.5).color('#E0E0E0')
      this.RecordMenuItem($r('app.media.startIcon'), '删除')
       // .fontColor('#FF3B30')
    }
    .width(200)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 5, color: '#30000000' })
    .position({ x: '80%', y: 60 })
  }

  @Builder
  RecordMenuItem(iconRes: Resource, textStr: string) {
    Row() {
      Image(iconRes)
        .width(20)
        .height(20)
        .fillColor('#333333')
        .margin({ left: 12, right: 12 })
      Text(textStr)
        .fontSize(14)
        .fontColor('#000000')
    }
    .width('100%')
    .height(44)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      console.log('点击了' + textStr);
      this.showRecordMenu = false;
    })
  }

  @Builder
  BottomToolBar() {
    Row() {
      Button('+')
        .width(56)
        .height(56)
        .fontSize(24)
        .fontColor('#FFFFFF')
        .borderRadius(28)
        .backgroundColor('#007AFF')
        .onClick(() => {
          this.showAttachmentMenu = !this.showAttachmentMenu;
        })
    }
    .width('100%')
    .height(80)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#F0F0F0' })
  }

  build() {
    Column() {
      this.TopNavBar()
      if (this.currentPage === 'noteEdit') {
        this.NoteEditContent()
      } else if (this.currentPage === 'fileManage') {
        this.FileManageContent()
      } else if (this.currentPage === 'record') {
        this.RecordContent()
      }
      if (this.currentPage === 'noteEdit') {
        this.BottomToolBar()
      }
      if (this.showAttachmentMenu) {
        this.AttachmentMenu()
          //.position({ x: '5%', y: '80%' })
      }
      if (this.showRecordMenu) {
        this.RecordMenu()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}