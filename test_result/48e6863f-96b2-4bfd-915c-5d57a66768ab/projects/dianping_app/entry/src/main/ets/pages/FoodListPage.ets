import router from '@ohos.router';
import { FoodItem } from '../models/DataTypes';

@Entry
@Component
struct FoodListPage {
  @State searchText: string = '';
  @State activeFilter: string = '全部';
  @State sortBy: string = '综合排序';
  @State selectedCategory: string = '';

  private filters: string[] = ['全部', '火锅', '烧烤', '日料', '甜品', '小吃', '西餐', '海鲜'];
  private sortOptions: string[] = ['综合排序', '评分最高', '距离最近', '人均最低', '人均最高'];

  private foodList: FoodItem[] = [
    new FoodItem(1, '海底捞火锅（朝阳大悦城店）', '🫕', '4.8', 12860, '¥120/人', '火锅',
      ['服务好', '环境好', '停车方便'], '1.2km', '朝阳北路101号朝阳大悦城6层', true),
    new FoodItem(2, '牛角日本烧肉专门店', '🥩', '4.7', 5620, '¥180/人', '日料',
      ['和牛', '日式烤肉', '约会圣地'], '0.8km', '三里屯太古里南区B1层', true),
    new FoodItem(3, '满记甜品（国贸店）', '🍰', '4.5', 8920, '¥45/人', '甜品',
      ['杨枝甘露', '榴莲班戟', '下午茶'], '2.1km', '建国门外大街1号国贸商城B1层', false),
    new FoodItem(4, '木屋烧烤（望京店）', '🍖', '4.6', 15680, '¥85/人', '烧烤',
      ['烤串', '夜宵', '性价比高'], '3.5km', '望京街9号望京国际商业中心1层', true),
    new FoodItem(5, '鼎泰丰（SKP店）', '🥟', '4.7', 7230, '¥150/人', '小吃',
      ['小笼包', '米其林', '江浙菜'], '1.8km', '建国路87号SKP 6层', false),
    new FoodItem(6, '川味观·精品川菜', '🌶️', '4.4', 4320, '¥95/人', '火锅',
      ['川菜', '麻辣', '聚会'], '2.5km', '工体北路甲2号盈科中心3层', false),
    new FoodItem(7, '鮨一日本料理', '🍣', '4.9', 3210, '¥680/人', '日料',
      ['Omakase', '高端', '纪念日'], '4.2km', '亮马桥路48号四季酒店2层', true),
    new FoodItem(8, '文和友龙虾馆', '🦞', '4.3', 21300, '¥110/人', '海鲜',
      ['小龙虾', '网红店', '夜宵'], '5.0km', '青年路7号达美中心1层', false),
    new FoodItem(9, 'The Cheesecake Factory', '🧀', '4.5', 6540, '¥130/人', '西餐',
      ['芝士蛋糕', '美式', '分量大'], '1.5km', '东大桥路9号侨福芳草地B1层', false),
    new FoodItem(10, '喜茶（三里屯黑金店）', '🧋', '4.6', 28900, '¥28/人', '甜品',
      ['奶茶', '网红', '排队'], '0.6km', '三里屯太古里南区1层', true),
  ];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['category'] !== undefined) {
      this.selectedCategory = params['category'] as string;
      this.activeFilter = this.selectedCategory;
    }
  }

  build() {
    Column() {
      // Header with back button
      this.HeaderSection()

      // Search bar
      this.SearchBarSection()

      // Filter row
      this.FilterRow()

      // Sort row
      this.SortRow()

      // Food list
      this.FoodListView()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  HeaderSection() {
    Row() {
      Text('←')
        .fontSize(22)
        .fontColor('#333333')
        .padding({ left: 4, right: 12, top: 4, bottom: 4 })
        .onClick(() => {
          router.back();
        })

      Text(this.selectedCategory ? this.selectedCategory + '美食' : '美食列表')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)

      Text('🗺️')
        .fontSize(20)
        .margin({ right: 12 })

      Text('🔍')
        .fontSize(20)
    }
    .width('100%')
    .padding({ left: 12, right: 16, top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SearchBarSection() {
    Row() {
      Text('🔍')
        .fontSize(14)
        .margin({ left: 12, right: 6 })

      TextInput({ placeholder: '搜索餐厅、菜系或关键词', text: this.searchText })
        .fontSize(13)
        .layoutWeight(1)
        .height(36)
        .backgroundColor('transparent')
        .onChange((value: string) => {
          this.searchText = value;
        })

      if (this.searchText.length > 0) {
        Text('✕')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 10 })
          .onClick(() => {
            this.searchText = '';
          })
      }
    }
    .width('100%')
    .height(40)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  FilterRow() {
    Scroll() {
      Row() {
        ForEach(this.filters, (filter: string) => {
          Text(filter)
            .fontSize(13)
            .fontColor(this.activeFilter === filter ? '#FFFFFF' : '#666666')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(this.activeFilter === filter ? '#FF6600' : '#FFFFFF')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.activeFilter = filter;
              if (filter === '全部') {
                this.selectedCategory = '';
              } else {
                this.selectedCategory = filter;
              }
            })
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SortRow() {
    Row() {
      ForEach(this.sortOptions, (option: string) => {
        Row() {
          Text(option)
            .fontSize(12)
            .fontColor(this.sortBy === option ? '#FF6600' : '#666666')
          if (option === '综合排序' || option === '人均最低' || option === '人均最高') {
            Text('▼')
              .fontSize(8)
              .fontColor(this.sortBy === option ? '#FF6600' : '#999999')
              .margin({ left: 2 })
          }
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .onClick(() => {
          this.sortBy = option;
        })
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 1 })
  }

  @Builder
  FoodListView() {
    Scroll() {
      List() {
        ForEach(this.getFilteredFoodList(), (item: FoodItem) => {
          ListItem() {
            this.FoodItemCard(item)
          }
          .margin({ left: 16, right: 16, bottom: 10 })
        })
      }
      .width('100%')
      .padding({ top: 10, bottom: 16 })
      .divider({
        strokeWidth: 0,
      })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  FoodItemCard(item: FoodItem) {
    Row() {
      // Food image placeholder
      Text(item.image)
        .fontSize(40)
        .width(90)
        .height(90)
        .textAlign(TextAlign.Center)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

      Column() {
        Row() {
          Text(item.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (item.isFeatured) {
            Text('精选')
              .fontSize(9)
              .fontColor('#FFFFFF')
              .padding({ left: 5, right: 5, top: 2, bottom: 2 })
              .backgroundColor('#FF6600')
              .borderRadius(3)
          }
        }
        .width('100%')

        Row() {
          Text('⭐ ' + item.rating)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6600')
          Text(item.reviewCount + '条评价')
            .fontSize(11)
            .fontColor('#999999')
            .margin({ left: 6 })
          Text(item.distance)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ left: 6 })
        }
        .width('100%')
        .margin({ top: 4 })

        Row() {
          ForEach(item.tags, (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor('#FF6600')
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .border({ width: 0.5, color: '#FF6600', radius: 3 })
              .margin({ right: 4 })
          })
        }
        .width('100%')
        .margin({ top: 4 })

        Row() {
          Text(item.avgPrice)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF6600')

          Blank()

          Text(item.address)
            .fontSize(10)
            .fontColor('#BBBBBB')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .height(90)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .onClick(() => {
      router.pushUrl({ url: 'pages/NoteDetailPage', params: { name: item.name } });
    })
  }

  // Filter logic
  private getFilteredFoodList(): FoodItem[] {
    let result = this.foodList;

    // Filter by category
    if (this.selectedCategory && this.selectedCategory !== '全部') {
      result = result.filter((item: FoodItem) => item.category === this.selectedCategory);
    }

    // Filter by search text
    if (this.searchText.trim().length > 0) {
      const keyword = this.searchText.trim().toLowerCase();
      result = result.filter((item: FoodItem) =>
        item.name.toLowerCase().includes(keyword) ||
      item.category.toLowerCase().includes(keyword) ||
      item.tags.some((tag: string) => tag.toLowerCase().includes(keyword))
      );
    }

    // Sort
    switch (this.sortBy) {
      case '评分最高':
        result = [...result].sort((a, b) => parseFloat(b.rating) - parseFloat(a.rating));
        break;
      case '距离最近':
        result = [...result].sort((a, b) => parseFloat(a.distance) - parseFloat(b.distance));
        break;
      case '人均最低':
        result = [...result].sort((a, b) => {
          const priceA = parseInt(a.avgPrice.replace(/[^0-9]/g, ''));
          const priceB = parseInt(b.avgPrice.replace(/[^0-9]/g, ''));
          return priceA - priceB;
        });
        break;
      case '人均最高':
        result = [...result].sort((a, b) => {
          const priceA = parseInt(a.avgPrice.replace(/[^0-9]/g, ''));
          const priceB = parseInt(b.avgPrice.replace(/[^0-9]/g, ''));
          return priceB - priceA;
        });
        break;
      default:
        break;
    }

    return result;
  }
}
