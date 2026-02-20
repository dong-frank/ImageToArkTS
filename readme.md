## Demo运行

1.  conda env create -f environment.yml

2.  conda activate ui2code

3.  在 .env 中填入 qwen api key
4.  python architect_node.py 进行目前到architect的测试 

## 核心功能

### input processor

* 遍历文件夹，构建树型结构（示例见input_bundle.json）

### architect node

* 分析UI代码，产出 json tree（示例见architect_test_output.json）
* 根据父子文件夹，强制识别跳转按钮（prompt强制要求）

### coding node

* 构建RAG，根据json的组件从RAG中获取相关代码
* 以json的组件和RAG相关向量作为提示词，生成code
* 每次只生成一个页面的代码防止上下文过长
* 测试代码，直到编译通过（白盒测试）

### review node

* 黑盒测试，不碰代码
* 检查功能实现完备性
* 待定：**是否加入review之后的修改功能**

