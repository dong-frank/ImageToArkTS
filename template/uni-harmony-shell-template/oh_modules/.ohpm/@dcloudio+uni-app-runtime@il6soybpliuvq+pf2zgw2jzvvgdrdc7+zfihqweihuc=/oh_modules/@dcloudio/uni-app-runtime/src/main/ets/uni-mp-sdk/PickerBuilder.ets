import { defineNativeEmbed } from './sdk'
import { PickerHarmony, PickerController } from './components/Picker'
import { NodeRenderType } from '@kit.ArkUI'
import { NativeEmbedBuilderOptions } from './types'

interface PickerBuilderOptions extends NativeEmbedBuilderOptions {
  controller: PickerController
  range: string[] | string[][]
  value: string | number | number[]
  rangeKey?: string
  start?: string
  end?: string
  fields?: 'year' | 'month' | 'day',
  disabled?: boolean
  mode?: 'selector' | 'multiSelector' | 'time' | 'date'
  click: number
  on?: Map<'cancel' | 'change' | 'columnchange', () => void>
}

@Builder
function PickerBuilder(options: PickerBuilderOptions) {
  PickerHarmony({
    controller: options.controller,
    range: options.range,
    value: options.value,
    rangeKey: options.rangeKey,
    start: options.start,
    end: options.end,
    fields: options.fields,
    disabled: options.disabled,
    mode: options.mode,
    onCancel: options.on?.get('cancel'),
    onChange: options.on?.get('change'),
    onColumnchange: options.on?.get('columnchange'),
  }).position({
    x: options.x,
    y: options.y,
  }).width(options.width).height(options.height).visibility(options.visibility)
}

defineNativeEmbed('picker', {
  builder: PickerBuilder,
  controller: PickerController,
  nodeRenderType: NodeRenderType.RENDER_TYPE_TEXTURE
})
