import { UTSJSONObject } from '../uts-polyfill'
import { getType, isPlainObject } from './utils/index'
const OriginalJSON = JSON

function createUTSJSONObject(obj: Record<string, any>) {
  const result = new globalThis.UTSJSONObject({}) as Record<string, any>
  for (const key in obj) {
    const value = obj[key]
    if (isPlainObject(value)) {
      result[key] = createUTSJSONObject(value)
    } else if (getType(value) === 'array') {
      result[key] = value.map((item: any): any => {
        if (isPlainObject(item) as boolean) {
          return createUTSJSONObject(item)
        } else {
          return item
        }
      })
    } else {
      result[key] = value
    }
  }
  return result
}

function parseObjectOrArray(object: any) {
  const objectType = getType(object)
  if (object === null || (objectType !== 'object' && objectType !== 'array')) {
    return object
  }
  if (objectType === 'array') {
    return object.map((value: any) => {
      return parseObjectOrArray(value)
    })
  } else if (objectType === 'object') {
    return createUTSJSONObject(object)
  }
  return object
}

const UTSJSON = {
  parse<T = UTSJSONObject>(
    text: string,
    reviver?: (this: any, key: string, value: any) => any,
  ): T | null {
    try {
      const parseResult = OriginalJSON.parse(text, reviver)
      return parseObjectOrArray(parseResult)
    } catch (error) {
      console.error(error)
      return null
    }
  },
  parseArray<T = Object | null | undefined>(text: string): Array<T> | null {
    try {
      const parseResult = OriginalJSON.parse(text)
      if (Array.isArray(parseResult)) {
        return parseObjectOrArray(parseResult)
      }
      return null
    } catch (error) {
      console.error(error)
      return null
    }
  },
  parseObject<T = UTSJSONObject>(text: string): T | null {
    try {
      const parseResult = OriginalJSON.parse(text)
      if (Array.isArray(parseResult)) {
        return null
      }
      return parseObjectOrArray(parseResult)
    } catch (error) {
      console.error(error)
      return null
    }
  },
  stringify: (value: any) => {
    return OriginalJSON.stringify(value)
  },
}

export { UTSJSON }
