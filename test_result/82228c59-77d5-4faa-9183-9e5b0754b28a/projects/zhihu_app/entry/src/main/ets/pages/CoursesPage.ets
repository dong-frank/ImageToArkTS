import router from '@ohos.router';

interface CourseItem {
  title: string;
  instructor: string;
  lessons: string;
  progress: string;
  cover: string;
}

@Entry
@Component
struct CoursesPage {
  courseList: CourseItem[] = [
    { title: 'AI大模型应用开发实战', instructor: '张老师', lessons: '24课时', progress: '已学 65%', cover: '🎓' },
    { title: 'Python数据科学入门', instructor: '李教授', lessons: '18课时', progress: '已完成', cover: '🐍' },
    { title: '产品经理技能提升', instructor: '王导师', lessons: '32课时', progress: '已学 30%', cover: '📊' },
    { title: '前端开发进阶指南', instructor: '赵工程师', lessons: '28课时', progress: '未开始', cover: '💻' },
    { title: '商业思维与创业实践', instructor: '陈总', lessons: '16课时', progress: '已学 100%', cover: '💼' },
  ];

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
        Text('我的课程')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Summary card
      Row() {
        Column() {
          Text('学习中')
            .fontSize(12)
            .fontColor('#999999')
          Text('3')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0066FF')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text('已完成')
            .fontSize(12)
            .fontColor('#999999')
          Text('2')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00AA66')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text('总课时')
            .fontSize(12)
            .fontColor('#999999')
          Text('118')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 20, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .margin({ top: 8 })

      // Course list
      Scroll() {
        Column() {
          Text('所有课程')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 8 })

          ForEach(this.courseList, (course: CourseItem) => {
            this.CourseCard(course);
          })
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
  CourseCard(course: CourseItem) {
    Row() {
      Text(course.cover)
        .fontSize(32)
        .width(56)
        .height(56)
        .backgroundColor('#FFF3E0')
        .borderRadius(8)
        .textAlign(TextAlign.Center)

      Column() {
        Text(course.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(course.instructor)
            .fontSize(12)
            .fontColor('#999999')
          Text(' · ')
            .fontSize(12)
            .fontColor('#CCCCCC')
          Text(course.lessons)
            .fontSize(12)
            .fontColor('#999999')
        }
        .margin({ top: 4 })

        Text(course.progress)
          .fontSize(11)
          .fontColor(course.progress === '已完成' ? '#00AA66' : '#0066FF')
          .backgroundColor(course.progress === '已完成' ? '#E8F8EE' : '#E8F0FE')
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .margin({ top: 6 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .margin({ left: 12, right: 12, top: 4, bottom: 4 })
    .borderRadius(8)
    .onClick(() => {
      // Navigate to course detail/player
    })
  }
}
