# 交互式答题系统使用指南

## 概述

这是一个为 Hugo 博客设计的交互式在线答题系统，可以将 Markdown 中的考题转换为具有交互功能的在线考试题。每个题目都支持：
- 选择答案并提交
- 自动判断对错
- 显示正确答案
- 每个选项的详细解释

## 文件结构

```
blog/
├── layouts/
│   └── shortcodes/
│       ├── quiz.html          # 答题容器 shortcode
│       └── quizoption.html    # 选项 shortcode
├── static/
│   ├── css/
│   │   └── quiz.css           # 答题系统样式
│   └── js/
│       └── quiz.js            # 答题系统交互逻辑
└── layouts/
    └── _default/
        └── baseof.html        # 覆盖模板，引入 CSS/JS
```

## 使用方法

### 基本语法

在 Markdown 文件中使用以下语法创建题目：

```markdown
{{< quiz id="quiz-1" question="你的题目内容" correct="A" >}}
{{< quizoption value="A" explanation="选项A的解释说明" >}}
选项A的内容
{{< /quizoption >}}
{{< quizoption value="B" explanation="选项B的解释说明" >}}
选项B的内容
{{< /quizoption >}}
{{< quizoption value="C" explanation="选项C的解释说明" >}}
选项C的内容
{{< /quizoption >}}
{{< quizoption value="D" explanation="选项D的解释说明" >}}
选项D的内容
{{< /quizoption >}}
{{< /quiz >}}
```

### 参数说明

#### quiz shortcode

- `id`（必需）：题目的唯一标识符，建议使用有意义的名称，如 `quiz-java-1`
- `question`（必需）：题目的完整内容
- `correct`（必需）：正确答案，值为 `A`、`B`、`C` 或 `D`

#### quizoption shortcode

- `value`（必需）：选项值，通常为 `A`、`B`、`C`、`D`
- `explanation`（可选但推荐）：该选项的详细解释说明

### 完整示例

```markdown
{{< quiz id="java-basic-1" question="Java 中局部变量的描述，哪项正确？" correct="C" >}}
{{< quizoption value="A" explanation="错误：局部变量不能使用访问修饰符（public/private/protected），它们只在方法或代码块内部可见。" >}}
局部变量可以使用 `public/private` 修饰。
{{< /quizoption >}}
{{< quizoption value="B" explanation="错误：局部变量存储在栈（Stack）中，而不是堆（Heap）。堆用于存储对象实例。" >}}
局部变量存储在堆（Heap）。
{{< /quizoption >}}
{{< quizoption value="C" explanation="正确：局部变量在使用前必须初始化，否则编译器会报错。这与实例变量不同，实例变量有默认值。" >}}
局部变量在定义时必须初始化，否则编译失败。
{{< /quizoption >}}
{{< quizoption value="D" explanation="错误：局部变量没有默认值，必须显式初始化。只有实例变量和类变量才有默认值。" >}}
局部变量具有默认值，例如引用类型默认为 `null`。
{{< /quizoption >}}
{{< /quiz >}}
```

## 功能特性

### 1. 提交答案
- 用户选择一个选项后，点击"提交答案"按钮
- 系统自动判断对错
- 正确选项显示绿色边框和背景
- 错误选项（如果被选中）显示红色边框和背景
- 显示结果提示信息

### 2. 查看答案
- 点击"查看答案"按钮可以直接查看正确答案
- 显示所有选项的详细解释
- 无需选择即可查看完整解析

### 3. 重置
- 点击"重置"按钮可以清除所有选择
- 恢复题目到初始状态
- 可以重新答题

### 4. 自动标记
- 提交后自动标记正确和错误的选项
- 使用颜色区分：绿色表示正确，红色表示错误

### 5. 详细解释
- 显示选中选项的解释（如果答错）
- 显示正确答案的解释
- 查看答案时显示所有选项的解释

## 样式定制

如果需要自定义样式，可以修改 `static/css/quiz.css` 文件。主要样式类包括：

- `.quiz-container`：答题容器
- `.quiz-question`：题目区域
- `.quiz-option`：选项区域
- `.quiz-option.correct`：正确答案样式
- `.quiz-option.incorrect`：错误答案样式
- `.quiz-result`：结果显示区域
- `.quiz-explanation`：解释说明区域

## 注意事项

1. **唯一 ID**：每个题目的 `id` 必须在同一页面中唯一
2. **正确答案匹配**：`correct` 参数的值必须与某个 `quizoption` 的 `value` 匹配
3. **解释说明**：虽然 `explanation` 是可选的，但强烈建议为每个选项提供解释，这样用户可以更好地理解知识点
4. **Markdown 支持**：选项内容支持 Markdown 语法，可以使用代码、加粗、链接等格式
5. **响应式设计**：答题系统已经适配移动端，在手机上也能正常使用

## 转换现有题目

如果你已经有格式化的题目（如列表形式），可以按照以下步骤转换：

1. 提取题目内容作为 `question` 参数
2. 将每个选项转换为 `quizoption` shortcode
3. 为每个选项添加 `explanation` 参数
4. 确定正确答案并设置 `correct` 参数
5. 为题目设置唯一的 `id`

## 示例文档

查看 `content/编程语言/编程语言-在线答题示例.md` 获取更多使用示例。

## 技术实现

- **前端框架**：纯 JavaScript，无依赖
- **样式**：CSS3，支持响应式设计
- **Hugo 版本**：兼容 Hugo 0.60+ 版本
- **浏览器支持**：现代浏览器（Chrome, Firefox, Safari, Edge）

## 问题反馈

如果遇到问题或有改进建议，请检查：
1. Hugo shortcode 语法是否正确
2. CSS 和 JS 文件是否正确加载
3. 浏览器控制台是否有错误信息

