# cuzexam

浙江传媒学院LaTeX试卷模板，一般可用于笔试类其中或期末考试。

## 特点

- 支持判断、选择、填空、简答、计算、证明等多种题型；
- 选择题目前只支持四个选项，可按内容自动排列：
    - 四个选项占一行；
    - 四个选项分两行，每行两个；
    - 四个选项分别各占一行，共四行；
- 一套模板支持四种输出：试卷、答题纸、参考答案、带参考答案的试卷等，可通过选项切换，方便快捷；
- 可自动生成大题统计分数表格：
    - 目前尚无法自动判断大题数目，须手工输入。

## 用法

- 可参考`demo.tex`文件中的写法；
- **强烈建议**：将该模板导入在线LaTeX系统（如[overleaf](https://www.overleaf.com/)、[texpage](https://www.texpage.com/)等）中运行，只是须注意选择`xelatex`编译器进行编译；
- 若确需在本地编译，则建议采用TeX Live编译套件，同样应使用`xelatex`编译器进行编译。

### 选项

当使用`cuzexam`模板时，可选的选项包括：`answer`与`sheet`：

- 若选项为空（即不加任何选项），则可生成常规试卷；
- 若选项为`answer`，则可生成带有参考答案的试卷（一般无需此形式）；
- 若选项为`sheet`，则可生成答题纸；
- 若选项为`answer, sheet`，则可生成参考答案。

### 常用环境与命令

- `problem`环境：用于描述题干，仅当不存在`sheet`选项时显示；
- `sheetcontents`环境：用于显示答题纸或参考答案中特有的内容，仅当存在`sheet`选项时显示；
- `solution`环境：用于显示计算题或简答题的参考答案，以`解`字样开头、`□`符号结尾，仅当存在`answer`选项时出现；
- `proof`环境：用于显示证明题的参考答案，以`证明`字样开头、`□`符号结尾，仅当存在`answer`选项时出现；
- `studentanswer`环境：用于在试卷中留出适当空隙，以便学生作答，空隙宽度可指定，亦可另起一页；
- `\makepart`命令：用于表示大题开始，左侧为该大题总分数表格，右侧为该大题要求；
- `\pickout`命令：用于表示判断或选择题的答案占位符，以中括号`[ ]`为标志，当输出为普通试卷时中括号内为空，否则可在中括号内直接显示参考答案；
    - 若为判断题，可在该命令内加入`\yes`或`\no`命令分别表示正确或错误；
    - 若为选择题，可直接在该命令内写如`A`、`B`、`C`或`D`；
- `\fillindex`命令：用于表示填空题的答案占位符，以下划线为标志，当输出为普通试卷时下划线上显示空格序号，否则在下划线上直接显示参考答案；
- `\fillinx`命令：与`\fillindex`命令功能相同，但可指定下划线宽度。