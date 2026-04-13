# @dcloudio/uni-app-runtime

[uni-app](https://uniapp.dcloud.net.cn/) 运行时环境，用于支持 uni-app 在 HarmonyOS Next 上运行。

## 安装

```bash
ohpm install @dcloudio/uni-app-runtime
```

## 使用

### 初始化

```typescript
interface IInitConfig {
  debug?: boolean
}
function init(ability: UIAbility, stage: window.WindowStage, config?: IInitConfig)
```

#### 示例代码
```typescript
import window from '@ohos.window'
import { init } from '@dcloudio/uni-app-runtime'

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    init(this, windowStage, {
      debug: true
    })
  }
}
```

### 获取运行目录

```typescript
function getUniMPRunPath(appId: string): string
```

### 判断应用是否已释放到运行目录

```typescript
function isExistsUniMP(appId: string): boolean
````

### 释放 wgt 包到运行目录

```typescript
type ReleaseWgtToRunPathCallback = (code: 1 | -1, error?: Error) => void
function releaseWgtToRunPath(appId: string, wgtPath: string, callback: ReleaseWgtToRunPathCallback)
````

### 启动应用

```typescript
interface ICapsuleStyle {
  backgroundColor?: string
  textColor?: string
  heightlightColor?: string
  borderColor?: string
}

interface ICapsuleMenuActionSheetItem {
  id: string
  title: string
}

interface IOpenUniMPConfig {
  showCapsuleButton?: boolean
  capsuleMenuActionSheetItems?: ICapsuleMenuActionSheetItem[]
  capsuleButtonStyle?: ICapsuleStyle
  redirectPath?: string
  /**
   * @deprecated
   */
  arguments?: Record<string, unknown> | string
  extraData?: Record<string, unknown>
}

export interface IUniMP {
  appId: string
  hide(): void
  show(): void
  close(): void
  sendUniMPEvent: (event: string, data: ESObject) => void
  on(event: 'uniMPEvent', callback: (event: string, data: ESObject, notify: (...args: ESObject[]) => void) => void): void
  on(event: 'menuItemClick', callback: (id: string) => void): void
  on(event: 'close' | 'show' | 'hide', callback: () => void): void
  off(name: string, callback: Function): void
}

function openUniMP(appId: string, config?: IOpenUniMPConfig): UniMP
```

#### 示例代码

```typescript
import { openUniMP } from '@dcloudio/uni-app-runtime'
interface UniMP {
  on(event: 'menuItemClick', callback: (id: string) => void): void
}

const app = openUniMP('HBuilder', {
  capsuleMenuActionSheetItems: [
    {
      id: '1',
      title: 'test'
    }
  ]
}) as UniMP
app.on('menuItemClick', (id: string) => {
  console.log('menuItemClick', id)
})
```

#### 小程序和宿主通讯

```js
// 小程序监听宿主消息
uni.onNativeEventReceive((event, data) => {
    console.log(`小程序收到宿主消息，事件：${event}，消息：${JSON.stringify(data)}`);
})

// 小程序向宿主发送消息
uni.sendNativeEvent(
    event,
    data,
    (...args) => {
        console.log(`宿主处理完成并返回如下信息：${JSON.stringify(args)}`)
    }
)
```

```typescript
// const mp = openUniMP(...)
// 宿主监听小程序消息
mp.on('uniMPEvent', (event, data, notify) => {
    console.log(`宿主收到小程序消息，事件：${event}，消息：${JSON.stringify(data)}`);
    notify('宿主成功接收小程序消息')
})

// 宿主向小程序发送消息
mp.sendUniMPEvent(event, data)
```

### 定义原生嵌入组件

```typescript
export interface NativeEmbedEvent {
  detail: object
}

export interface NativeEmbedBuilderOptions {
  width: number
  height: number
  on?: Map<string, (event?: NativeEmbedEvent) => void>
}

export interface DefineNativeEmbedOptions<T extends NativeEmbedBuilderOptions = NativeEmbedBuilderOptions> {
  builder: (options: T) => void
}

export declare function defineNativeEmbed<T extends NativeEmbedBuilderOptions = NativeEmbedBuilderOptions>(
  tag: string,
  options: DefineNativeEmbedOptions<T>
): void
```

#### 示例代码

```ets
import { NativeEmbedBuilderOptions, defineNativeEmbed } from "@dcloudio/uni-app-runtime"

interface ButtonBuilderOptions extends NativeEmbedBuilderOptions {
  label: string
}

interface ButtonClickEventDetail {
  text: string
}


@Component
struct ButtonComponent {
  @Prop label: string
  onButtonClick?: Function

  build() {
    Button(this.label)
      .width('100%')
      .height('100%')
      .onClick(() => {
        if (this.onButtonClick) {
          const detail = {
            text: 'test'
          } as ButtonClickEventDetail
          this.onButtonClick({
            detail
          })
        }
      })
  }
}

@Builder
function ButtonBuilder(options: ButtonBuilderOptions) {
  ButtonComponent({
    label: options.label,
    onButtonClick: options?.on?.get('click')
  })
    .width(options.width)
    .height(options.height)
}

defineNativeEmbed('button', {
  builder: ButtonBuilder
})
```

```vue
<template>
    <embed class="native-button" tag="button" :options="options" @click="onClick"></embed>
</template>

<script>
    export default {
        data() {
            return {
                options: {
                    label: 'hello'
                }
            }
        },
        methods: {
            onClick(e) {
                console.log('onClick', e.detail.text)
            }
        }
    }
</script>

<style scoped>
    .native-button {
        display: block;
        width: 200px;
        height: 50px;
        margin: 10px auto;
    }
</style>
```
