#!/bin/bash
function ohpm_install() {     
    cd $1              # $1：函数第一个参数, 必须是路径     
    ohpm install --all # 安装所有依赖
}

npm config set registry https://repo.huaweicloud.com/repository/npm/
npm config set "@ohos:registry" https://repo.harmonyos.com/npm/

PROJECT_PATH=${1:-output}  # 接收第一个参数作为工程路径，未传递则默认为 output

ohpm_install "${PROJECT_PATH}"


# 根据业务情况，执行相应的构建命令, 示例如下
# clean工程
hvigorw clean --no-daemon
# 构建Hap, 生成产物：${PROJECT_PATH}/{moduleName}/build/{productName}/outputs/{targetName}/xxx.hap
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon