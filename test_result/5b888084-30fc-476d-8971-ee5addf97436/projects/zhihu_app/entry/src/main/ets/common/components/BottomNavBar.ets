@Component
export struct BottomNavBar {
  @Prop currentPage: string = '';
  @Prop tabs: string[] = [];

  build() {
    Row({ space: 8 }) {
      ForEach(this.tabs, (tab: string) => {
        Text(tab)
          .fontSize(14)
          .fontWeight(this.currentPage === tab ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentPage === tab ? '#111111' : '#888888')
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding({ top: 12, bottom: 12 })
  }
}
