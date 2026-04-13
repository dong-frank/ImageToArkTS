import { ObservedArray } from '../utils'
import { nativePagesManager } from '../sdk'
import { themeState } from '../theme'

class PickerStyle {
  textFontColor: string = '#ff182431'
  textFontDarkColor: string = 'rgba(255, 255, 255, 0.8)'
  selectedTextFontColor: string = '#007aff'
  selectedTextFontDarkColor: string = '#007aff'
  cancelFontColor: string = '#888888'
  cancelFontDarkColor: string = 'rgba(255, 255, 255, 0.8)'
  confirmFontColor: string = '#007aff'
  backgroundColor: string = '#FFFFFF'
  backgroundDarkColor: string = '#232323'

  constructor() {
  }
}

const pickerStyle = new PickerStyle()

interface Detail {
  column?: number
  value?: string | number | number[]
}

interface CustomEvent {
  detail: Detail
}

type Range = string[] | string[][] | object[] | object[][]

// #region MultiSelectorPicker
interface MultiSelectorPickerEvent {
  onChange?: (value: string | string[], index: number | number[]) => void
  onAccept?: (value: TextPickerResult) => void
  onCancel?: () => void
  onDidDisappear?: () => void
}

@Observed
class MultiSelectorPickerState {
  value: string[] = new ObservedArray<string>()
  selected: number[] = new ObservedArray<number>()
  range: TextCascadePickerRangeContent[] = new ObservedArray<TextCascadePickerRangeContent>()
}

@Observed
export class ObservedTextCascadePickerRangeContent implements TextCascadePickerRangeContent {
  text: string
  children: TextCascadePickerRangeContent[]

  constructor(text: string = '') {
    this.text = text
    this.children = new ObservedArray<TextCascadePickerRangeContent>()
  }
}

let multiSelectorPickerDialogController: CustomDialogController | null = null
const multiSelectorPickerState = new MultiSelectorPickerState()

function initControllerOnce(event: MultiSelectorPickerEvent): CustomDialogController {
  if (multiSelectorPickerDialogController) {
    return multiSelectorPickerDialogController
  }

  multiSelectorPickerDialogController = new CustomDialogController({
    builder: MultiSelectorPicker({
      range: multiSelectorPickerState.range,
      value: multiSelectorPickerState.value,
      selected: multiSelectorPickerState.selected,
      controller: multiSelectorPickerDialogController!,
      onChange: event.onChange,
      onAccept: event.onAccept,
      onCancel: event.onCancel,
      onDidDisappear: event.onDidDisappear
    }),
    alignment: DialogAlignment.Center,
    backgroundColor: themeState.isDark ? pickerStyle.backgroundDarkColor : pickerStyle.backgroundColor,
    backgroundBlurStyle: BlurStyle.NONE,
    cancel: event.onDidDisappear
  })
  return multiSelectorPickerDialogController
}

class CustomMultiSelectorPickerDialog {
  open(page: object, event: MultiSelectorPickerEvent = {}) {
    initControllerOnce.bind(page)(event).open()
  }

  createObservedRange(range: string[][], selected: number[], children: TextCascadePickerRangeContent[],
    index: number = 0) {
    // 边界检查：确保 range 和 index 有效
    if (!range || range.length === 0 || index < 0 || index >= range.length) {
      console.warn(`[Picker] createObservedRange: 无效的 range 或 index. range.length=${range?.length}, index=${index}`)
      return
    }

    // 边界检查：确保当前列的数据存在
    const currentColumn = range[index]
    if (!currentColumn || currentColumn.length === 0) {
      console.warn(`[Picker] createObservedRange: 当前列数据为空. index=${index}, currentColumn.length=${currentColumn?.length}`)
      return
    }

    const len = range.length - 1
    // 边界检查：确保 selected 数组有效
    if (!selected || index >= selected.length) {
      console.warn(`[Picker] createObservedRange: selected 数组无效. index=${index}, selected.length=${selected?.length}`)
      return
    }

    const selectedIndex = selected[index]

    // 修复：使用不同的变量名避免覆盖外层的 index
    // 原问题：forEach((item, index) => {...}) 中的 index 会覆盖外层参数 index
    // 导致递归调用时使用错误的索引值（使用的是数组最后一个元素的索引，而不是列索引）
    currentColumn.forEach((item, itemIndex) => {
      children.splice(itemIndex, 1, new ObservedTextCascadePickerRangeContent(item))
    })

    // 递归处理下一列：确保索引有效且存在子节点
    if (index < len && selectedIndex >= 0 && selectedIndex < children.length && children[selectedIndex] && children[selectedIndex].children) {
      this.createObservedRange(range, selected, children[selectedIndex].children!, index + 1)
    }
  }
}

const customMultiSelectorPickerDialog = new CustomMultiSelectorPickerDialog()

// #endregion

export class PickerController {
  private instance?: PickerHarmony

  init(instance?: PickerHarmony) {
    this.instance = instance
  }

  show(): void {
    this.instance?.show()
  }

  updateRange(range: Range): void {
    this.instance?.setMultiSelectorRange(range)
  }
}

interface ICustomTextCascadePickerRangeContent extends TextCascadePickerRangeContent {
  value: number | string,
  children: ICustomTextCascadePickerRangeContent[]
}

@Component
export struct PickerHarmony {
  controller?: PickerController
  @Prop mode?: 'selector' | 'multiSelector' | 'time' | 'date' = 'selector'
  @Prop range?: Range
  @Prop realRange: TextCascadePickerRangeContent[] = []
  @Prop value?: string | number | number[]
  @Prop rangeKey?: string = ''
  @Prop start?: string = ''
  @Prop end?: string = ''
  @Prop fields?: 'year' | 'month' | 'day' = 'day'
  @Prop disabled?: boolean = false
  @State lastValue: number[] = []
  @Prop changeOrCancel: boolean = false
  onCancel?: (detail?: CustomEvent) => void = undefined
  onChange?: (detail?: CustomEvent) => void = undefined
  onColumnchange?: (detail?: CustomEvent) => void = undefined

  build() {
    Stack().onClick(() => {
      this.show()
    })
  }

  aboutToAppear(): void {
    if (this.mode == 'multiSelector') {
      if (this.range && this.range.length > 0 && !this.value) {
        this.value = Array(this.range.length).fill(0);
      }
    }
    this.controller?.init(this)
  }

  aboutToDisappear(): void {
    multiSelectorPickerDialogController = null
  }

  setMultiSelectorRange(range: Range): void {
    this.range = range
    const realRange = this.getPickerShowRange() as string[][];
    const realValue = this.getPickerShowValue(realRange) as string[]
    customMultiSelectorPickerDialog.createObservedRange(realRange, this.value as number[], multiSelectorPickerState.range);
    if (realValue) {
      realValue.forEach((v, i) => multiSelectorPickerState.value.splice(i, 1, v));
    }
    if (this.value) {
      (this.value as number[]).forEach((v, i) => multiSelectorPickerState.selected.splice(i, 1, v))
    }
  }

  getPickerShowRange(): string[] | string[][] {
    if (this.mode === 'multiSelector') {
      return (this.range as (string | object)[][]).map(column => {
        return column.map(item => {
          if (this.rangeKey) {
            return (item as object)[this.rangeKey] as string
          }
          return item + '' as string
        })
      })
    } else {
      return (this.range as (string | object)[]).map(item => {
        if (this.rangeKey) {
          return (item as object)[this.rangeKey] as string
        }
        return item + '' as string
      })
    }
  }

  getPickerShowValue(realRange: string[] | string[][]): string | string[] | undefined {
    if (!this.value) {
      return
    }
    switch (this.mode) {
      case 'multiSelector':
        return (realRange as string[][]).map((column, index) => {
          return column[(this.value as number[])[index]]
        })
      case 'selector':
      default:
        return (realRange as string[])[this.value as number]
    }
  }

  show() {
    const PickerDialogColorOptions = {
      acceptButtonStyle: {
        fontColor: pickerStyle.confirmFontColor
      },
      cancelButtonStyle: {
        fontColor: themeState.isDark ? pickerStyle.cancelFontDarkColor : pickerStyle.cancelFontColor
      },
      backgroundColor: themeState.isDark ? pickerStyle.backgroundDarkColor : pickerStyle.backgroundColor,
      backgroundBlurStyle: BlurStyle.NONE,
      textStyle: {
        color: themeState.isDark ? pickerStyle.textFontDarkColor : pickerStyle.textFontColor
      },
      disappearTextStyle: {
        color: themeState.isDark ? pickerStyle.textFontDarkColor : pickerStyle.textFontColor
      },
      selectedTextStyle: {
        color: themeState.isDark ? pickerStyle.selectedTextFontDarkColor : pickerStyle.selectedTextFontColor
      }
    } as TextPickerDialogOptions
    if (this.disabled) {
      return
    }
    this.changeOrCancel = false
    const onChange = (value: string | number | number[]) => {
      this.changeOrCancel = true
      this.onChange?.({
        detail: {
          value
        }
      })
    }
    const onCancel = () => {
      this.changeOrCancel = true
      this.onCancel?.({
        detail: {}
      })
    }
    const onDidDisappear = () => {
      if (!this.changeOrCancel) {
        this.onCancel?.({
          detail: {}
        })
      }
    }
    if (this.mode === 'date') {
      // TODO 国际化
      if (this.fields === 'year') {
        const currentYear = new Date().getFullYear()
        const startYear = this.start ? new Date(this.start).getFullYear() : currentYear - 150
        const endYear = this.end ? new Date(this.end).getFullYear() : currentYear + 150
        const range: string[] = []
        for (let i = startYear; i <= endYear; i++) {
          range.push(i.toString())
        }
        this.getUIContext().showTextPickerDialog({
          range: range.map(item => item + '年'),
          value: (this.value as string || currentYear) + '年',
          canLoop: false,
          onAccept: (e) => {
            onChange(range[e.index as number])
          },
          onCancel,
          onDidDisappear,
          acceptButtonStyle: PickerDialogColorOptions.acceptButtonStyle,
          cancelButtonStyle: PickerDialogColorOptions.cancelButtonStyle,
          backgroundColor: PickerDialogColorOptions.backgroundColor,
          backgroundBlurStyle: PickerDialogColorOptions.backgroundBlurStyle,
          textStyle: PickerDialogColorOptions.textStyle,
          disappearTextStyle: PickerDialogColorOptions.disappearTextStyle,
          selectedTextStyle: PickerDialogColorOptions.selectedTextStyle,
        })
        return
      }
      if (this.fields === 'month') {
        const currentDate = new Date()
        const startDate = this.start ? new Date(this.start) : new Date((currentDate.getFullYear() - 150) + '-01')
        const endDate = this.end ? new Date(this.end) : new Date((currentDate.getFullYear() + 150) + '-12')
        const startDateYear = startDate.getFullYear()
        const startDateMonth = startDate.getMonth() + 1
        const endDateYear = endDate.getFullYear()
        const endDateMonth = endDate.getMonth() + 1
        const realRange: ICustomTextCascadePickerRangeContent[] = []
        const tempValue: number[] = (
          this.value ? (this.value as string).split('-').map(item => parseInt(item)) :
            [currentDate.getFullYear(), currentDate.getMonth() + 1]
        )
        const selected = [0, 0]
        for (let y = startDateYear; y <= endDateYear; y++) {
          const rangeItem = {
            text: y + '年',
            value: y,
            children: [] as ICustomTextCascadePickerRangeContent[]
          } as ICustomTextCascadePickerRangeContent
          if (y === tempValue[0]) {
            selected[0] = y - startDateYear
          }
          let startMonth = 0
          for (let m = 1; m <= 12; m++) {
            if (y === startDateYear && m < startDateMonth) {
              continue
            }
            if (y === endDateYear && m > endDateMonth) {
              break
            }
            if (startMonth === 0) {
              startMonth = m
            }
            if (y === tempValue[0] && m === tempValue[1]) {
              selected[1] = m - startMonth
            }
            rangeItem.children!.push({
              text: ('' + m).padStart(2, '0') + '月',
              value: m,
              children: []
            } as ICustomTextCascadePickerRangeContent)
          }
          realRange.push(rangeItem)
        }
        this.getUIContext().showTextPickerDialog({
          range: realRange,
          selected,
          canLoop: false,
          onAccept: (e) => {
            const index = e.index as number[]
            const yearIndex = index[0]
            const monthIndex = index[1]
            const yearRangeItem = realRange[yearIndex]
            const year = yearRangeItem.value
            const month = yearRangeItem.children![monthIndex]?.value || 1
            onChange(year + '-' + ('' + month).padStart(2, '0'))
          },
          onCancel,
          onDidDisappear,
          acceptButtonStyle: PickerDialogColorOptions.acceptButtonStyle,
          cancelButtonStyle: PickerDialogColorOptions.cancelButtonStyle,
          backgroundColor: PickerDialogColorOptions.backgroundColor,
          backgroundBlurStyle: PickerDialogColorOptions.backgroundBlurStyle,
          textStyle: PickerDialogColorOptions.textStyle,
          disappearTextStyle: PickerDialogColorOptions.disappearTextStyle,
          selectedTextStyle: PickerDialogColorOptions.selectedTextStyle,
        })
        return
      }
      this.getUIContext().showDatePickerDialog({
        showTime: false,
        selected: new Date(this.value as string),
        start: new Date(this.start),
        end: new Date(this.end),
        onDateAccept: (e: Date) => {
          onChange(
            e.getFullYear().toString().padStart(2, '0') + '-' + (e.getMonth() + 1).toString().padStart(2, '0') + '-' +
            e.getDate().toString().padStart(2, '0')
          )
        },
        onCancel,
        onDidDisappear,
        acceptButtonStyle: PickerDialogColorOptions.acceptButtonStyle,
        cancelButtonStyle: PickerDialogColorOptions.cancelButtonStyle,
        backgroundColor: PickerDialogColorOptions.backgroundColor,
        backgroundBlurStyle: BlurStyle.NONE,
        textStyle: PickerDialogColorOptions.textStyle,
        disappearTextStyle: PickerDialogColorOptions.disappearTextStyle,
        selectedTextStyle: PickerDialogColorOptions.selectedTextStyle,
      })
      return
    }
    if (this.mode === 'time') {
      const selected = new Date()
      if (typeof this.value === 'string' && this.value.includes(':')) {
        const splitValue = this.value.split(':')
        selected.setHours(parseInt(splitValue[0]))
        selected.setMinutes(parseInt(splitValue[1]))
      }
      this.getUIContext().showTimePickerDialog({
        useMilitaryTime: true,
        selected,
        format: TimePickerFormat.HOUR_MINUTE,
        onAccept: (e: TimePickerResult) => {
          onChange(e.hour.toString().padStart(2, '0') + ':' + e.minute.toString().padStart(2, '0'))
        },
        onCancel,
        onDidDisappear,
        acceptButtonStyle: PickerDialogColorOptions.acceptButtonStyle,
        cancelButtonStyle: PickerDialogColorOptions.cancelButtonStyle,
        backgroundColor: PickerDialogColorOptions.backgroundColor,
        backgroundBlurStyle: PickerDialogColorOptions.backgroundBlurStyle,
        textStyle: PickerDialogColorOptions.textStyle,
        disappearTextStyle: PickerDialogColorOptions.disappearTextStyle,
        selectedTextStyle: PickerDialogColorOptions.selectedTextStyle,
      })
      return
    }
    const pickerEvents: TextPickerDialogOptions = {
      range: [],
      onAccept: (e: TextPickerResult) => {
        onChange(e.index)
      },
      onCancel,
      onDidDisappear
    }
    if (this.mode === 'multiSelector') {
      this.lastValue = (this.value || []) as number[]
      this.setMultiSelectorRange(this.range!)
      customMultiSelectorPickerDialog.open(
        nativePagesManager.pages[nativePagesManager.pages.length - 1],
        {
          onChange: (value: string[], currentValue: number[]) => {
            this.value = currentValue
            let changedColumn = 0
            let changedValue: number = 0
            for (let i = 0; i < currentValue.length; i++) {
              if (this.lastValue[i] !== currentValue[i]) {
                changedColumn = i
                changedValue = currentValue[i]
                break
              }
            }
            this.onColumnchange?.({
              detail: {
                column: changedColumn,
                value: changedValue
              }
            })
            this.lastValue = currentValue
          },
          onAccept: pickerEvents.onAccept,
          onCancel: pickerEvents.onCancel,
          onDidDisappear: pickerEvents.onDidDisappear
        } as MultiSelectorPickerEvent
      )
    } else {
      const realRange = this.getPickerShowRange()
      const realValue = this.getPickerShowValue(realRange)
      this.getUIContext().showTextPickerDialog({
        range: realRange,
        value: realValue,
        canLoop: false,
        onAccept: pickerEvents.onAccept,
        onCancel: pickerEvents.onCancel,
        onDidDisappear: pickerEvents.onDidDisappear,
        acceptButtonStyle: PickerDialogColorOptions.acceptButtonStyle,
        cancelButtonStyle: PickerDialogColorOptions.cancelButtonStyle,
        backgroundColor: PickerDialogColorOptions.backgroundColor,
        backgroundBlurStyle: PickerDialogColorOptions.backgroundBlurStyle,
        textStyle: PickerDialogColorOptions.textStyle,
        disappearTextStyle: PickerDialogColorOptions.disappearTextStyle,
        selectedTextStyle: PickerDialogColorOptions.selectedTextStyle,
      })
    }

  }
}

@CustomDialog
export struct MultiSelectorPicker {
  @Prop range: TextCascadePickerRangeContent[]
  @Prop value: string[]
  @Prop selected: number[]
  currentValue: string | string[] = []
  currentIndex: number | number[] = []
  controller: CustomDialogController
  onChange?: (value: string | string[], index: number | number[]) => void = () => {
  }
  onAccept?: (value: TextPickerResult) => void = () => {
  }
  onCancel?: () => void = () => {
  }
  onDidDisappear?: () => void = () => {
  }

  // TODO 国际化
  build() {
    Column() {
      TextPicker({ range: multiSelectorPickerState.range, /*value: this.value*/ selected: this.selected })
        .onChange((value: string | string[], index: number | number[]) => {
          this.currentValue = value
          this.currentIndex = index
          this.onChange?.(value, index)
        })
        .canLoop(false)
        .disappearTextStyle({
          color: themeState.isDark ? pickerStyle.textFontDarkColor : pickerStyle.textFontColor
        })
        .textStyle({
          color: themeState.isDark ? pickerStyle.textFontDarkColor : pickerStyle.textFontColor
        })
        .selectedTextStyle({
          color: themeState.isDark ? pickerStyle.selectedTextFontDarkColor : pickerStyle.selectedTextFontColor
        })
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceAround }) {
        Button('取消')
          .flexGrow(1)
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {
            this.onCancel?.()
            this.controller.close()
          })
          .fontColor(themeState.isDark ? pickerStyle.cancelFontDarkColor : pickerStyle.cancelFontColor)
        Divider()
          .vertical(true)
          .height(26)
        Button('确认')
          .flexGrow(1)
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {
            this.onAccept?.({ value: this.currentValue, index: this.currentIndex })
            this.controller.close()
          })
          .fontColor(pickerStyle.confirmFontColor)
      }
      .padding(15)
    }
    .backgroundColor(themeState.isDark ? pickerStyle.backgroundDarkColor : Color.Transparent)
  }
}
