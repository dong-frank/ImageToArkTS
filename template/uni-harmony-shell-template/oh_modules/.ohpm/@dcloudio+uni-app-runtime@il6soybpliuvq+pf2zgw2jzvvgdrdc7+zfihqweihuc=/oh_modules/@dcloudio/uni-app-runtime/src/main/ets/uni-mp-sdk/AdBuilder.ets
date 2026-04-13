import { defineNativeEmbed } from './sdk'
import { NodeRenderType } from '@kit.ArkUI'
import { NativeEmbedBuilderOptions } from './types'
import { Ad, CustomEvent, setAdServer } from './components/Ad'

export {
  setAdServer
}

interface AdBuilderOptions extends NativeEmbedBuilderOptions {
  adpid: string
  disabled?: boolean
  click: number
  on?: Map<'load' | 'close' | 'error' | 'click' | 'adOpen' | 'adClick' | 'resize', (detail?: CustomEvent) => void>
}

@Builder
function AdBuilder(options: AdBuilderOptions) {
  Ad({
    adpid: options.adpid,
    onLoad: options.on?.get('load'),
    onClose: options.on?.get('close'),
    onError: options.on?.get('error'),
    onResize: options.on?.get('resize'),
  }).position({
    x: options.x,
    y: options.y,
  }).width(options.width).height(options.height ? options.height : 300)
}

defineNativeEmbed('ad', {
  builder: AdBuilder,
  nodeRenderType: NodeRenderType.RENDER_TYPE_DISPLAY
})
