\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cuzexam}[2021/12/03 v1.0 An exam class for CUZ]

% 是否显示答案
\newif\ifanswer
% 是否为答题纸
\newif\ifsheet

\DeclareOption{answer}{\answertrue}
\DeclareOption{noanswer}{\answerfalse}
\DeclareOption{sheet}{\sheettrue}
\DeclareOption{nosheet}{\sheetfalse}

%其它选项
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{ctexart}}

%不可省略
\ProcessOptions

\ExecuteOptions{answer}

\LoadClass[zihao=-4,UTF8]{ctexart}

\RequirePackage[a4paper,left=30mm,right=30mm,top=25mm,bottom=25mm]{geometry}
\RequirePackage{amsmath,amssymb}
\RequirePackage{multirow}
\RequirePackage{lastpage}
\RequirePackage{fancyhdr}
\RequirePackage{comment}
% \RequirePackage{environ}
\RequirePackage{calc}
\RequirePackage{graphicx}
\graphicspath{{images}}
\RequirePackage{ifthen}
\RequirePackage[shortlabels]{enumitem}
\RequirePackage{CJKnumb}
\RequirePackage{makecell}
\RequirePackage{tabularx}
% \RequirePackage{interfaces-makecell}
% \RequirePackage{zref-lastpage}
\RequirePackage{tikz}
\RequirePackage{expl3}

\RequirePackage{hyperref}
\AtBeginDocument{%
  \hypersetup{
    pdfinfo={
      Title    = {\@title},
      Author   = {\@author},
      Subject  = {\cuz@subject},
      Keywords = {\cuz@keywords},
    },
    colorlinks = true,
    hidelinks  = true,
  }
}
\setlength{\parindent}{0em}
\setlength{\lineskiplimit}{3pt}
\setlength{\lineskip}{3pt}

\ExplSyntaxOn
% we need LaTeX counters and not expl3 ones because of tabularx two-step process
\newcounter{repeatstart}
\newcounter{repeatcurrent}
\newcounter{repeatlast}

\NewDocumentCommand{\repeatcell}{mm}
 {% #1 = number of repeats
  % #2 = key-value pairs
  \cuz_repeatcell:nn { #1 } { #2 }
 }

\tl_new:N \l__cuz_repeatcells_body_tl

\keys_define:nn { cuz/repeatcells }
 {
  text .code:n = \cs_gset_protected:Nn \__cuz_repeatcell_text:n { #1 },
  start .code:n = \setcounter{repeatstart}{#1},
 }

\cs_new_protected:Nn \cuz_repeatcell:nn
 {
  \keys_set:nn { cuz/repeatcells } { #2 }
  \tl_clear:N \l__cuz_repeatcells_body_tl
  \int_step_inline:nnn
   { \value{repeatstart} + 1 }
   { \value{repeatstart} + #1 }
   {
    \tl_put_right:Nx \l__cuz_repeatcells_body_tl
     {
      \int_compare:nF { ##1 = \value{repeatstart} + 1 } { & }
      \__cuz_repeatcell_text:n { ##1 }
     }
   }
  \tl_use:N \l__cuz_repeatcells_body_tl
  \setcounter{repeatlast} { \int_eval:n { \value{repeatstart} + #1 } }
 }

\NewExpandableDocumentCommand{\lastvalue}{}{\int_eval:n { \value{repeatlast} } }

\AtBeginEnvironment{tabularx}{\setcounter{repeatstart}{0}}

\ExplSyntaxOff

\newcommand{\cuzsubject}[1]{\def\cuz@subject{#1}}
\newcommand{\cuzkeywords}[1]{\def\cuz@keywords{#1}}
\newcommand{\cuzacademicyear}[1]{\def\cuz@academicyear{#1}}
\newcommand{\cuzsemester}[1]{\def\cuz@semester{#1}}
\newcommand{\cuzcourse}[1]{\def\cuz@course{#1}}
\newcommand{\cuzlecturers}[1]{\def\cuz@lecturers{#1}}
\newcommand{\cuzexamstage}[1]{\def\cuz@examstage{#1}}
\newcommand{\cuzexamtype}[1]{\def\cuz@examtype{#1}}
\newcommand{\cuzpapertype}[1]{\def\cuz@papertype{#1}}
\newcommand{\cuznumberparts}[1]{\setcounter{cuz@numberparts}{#1}}

\newcommand{\underspace}[1]{\underline{\hspace{#1}}}

\newcounter{cuz@numberparts}

% 计分表制作
\newcommand{\cuz@scoretable}{
    \newcounter{cuz@numbercolumns}
    \setcounter{cuz@numbercolumns}{\value{cuz@numberparts}+3}
  \begin{tabularx}{\textwidth}{|c|X|c|*{\thecuz@numberparts}{X<{\centering}|}}
    \hline
        \multirow{3}{*}{\textbf{总分}} 
        & \multirow{2}{*}{}
        & \textbf{题号}
        & \repeatcell{\value{cuz@numberparts}}{text=\textbf{\CJKnumber{##1}}}
    \\
    \cline{3-\thecuz@numbercolumns}
    & & \multirow{2}{*}{\textbf{题分}}
    & \eline{\value{cuz@numberparts}}
    \\
    & & & \eline{\value{cuz@numberparts}}
    \\
    \hline
  \end{tabularx}
}

\newcommand{\cuz@titleending}{
    \ifanswer
        ~\cuz@papertype~卷参考答案
    \else
        \ifsheet
            ~\cuz@papertype~卷答题纸
        \else
            ~\cuz@papertype~卷
        \fi
    \fi
}

% 试卷头制作
\newcommand{\makehead}{
  \begin{center}
    \parbox{\textwidth}{\centering \zihao{4} \heiti \bfseries 浙江传媒学院《\cuz@course》\cuz@examstage（\cuz@examtype）\cuz@titleending
    }\\
    \vspace{1em}
    \underline{\quad\cuz@academicyear\quad}学年\quad 第\underline{~\cuz@semester~}学期
    \quad 任课教师\underline{\quad\cuz@lecturers\quad}\\
    \vspace{1em}
    \hrulefill~学院~\hrulefill~班~\quad~姓名~\hrulefill~学号~\hrulefill
    \vspace{0.5em}
    \ifanswer\else
        \ifthenelse{\thecuz@numberparts=0}{}{\cuz@scoretable}
    \fi
    \vspace{-2ex}
  \end{center}
}

\newcommand{\cuz@footnotetext}{《\cuz@course》\cuz@examstage（\cuz@examtype）\cuz@titleending \quad 第~\thepage~页/共~\pageref{LastPage}~页}

% 去掉页眉下划线
\renewcommand{\headrulewidth}{0pt}
% 装订线页眉外侧超宽6em
\fancyheadoffset[L]{6em}
\fancyhf{}
\pagestyle{fancy}
\cfoot{\small\cuz@footnotetext}
\lhead{
  \ifthenelse{\isodd{\thepage}}{
    \cuz@gutter
  }{}
}

\newcommand{\cuz@gutter}{
  \begin{tikzpicture}[remember picture,overlay,very thick,font=\bfseries\zihao{-3}]
    \path (current page.south west) +(2.5cm,1cm)  coordinate (a);
    \path (current page.north west) +(2.5cm,-1cm) coordinate (b);
    \node[text width=1em, xshift=1.5cm] at (current page.west) {
        装\\
        \vspace{10ex}
        订\\
        \vspace{10ex}
        区
    };
    \draw[dashed] (a) -- (b);
  \end{tikzpicture}
}

\newcounter{problem}
\newcounter{ifillin}

\newcommand{\makepart}[2]{
  \setcounter{problem}{0}
  \setcounter{ifillin}{0}
  \stepcounter{section}
  \vspace{1ex}
  \begin{tabular}{|r|r}
    \cline{1-1}
      \multicolumn{1}{|c|}{\hfill 得 \hfill 分 \hfill~}
      & \multicolumn{1}{c}{\multirow{2}[3]{*}{\textbf{\Chinese{section}、#1}(#2)}}
      \\
    \cline{1-1}
      \parbox{\textwidth}{\vspace{6ex}}
      & \\
    \cline{1-1}
  \end{tabular}
  \vspace{1ex}
}

\newcommand{\answer}[1]{
  \ifanswer{#1}\else\hphantom{#1}\fi
}

\newcommand{\yes}{$\checkmark$}
\newcommand{\no}{$\times$}

\newcommand{\fillin}[1]{
  \underline{\hspace{0.5em}\answer{#1}\hspace{0.5em}}
}

\newcommand{\fillinx}[2]{
  \underline{\makebox[#1\textwidth][l]{\answer{#2}}}
}

\newcommand{\fillindex}[1]{
    \stepcounter{ifillin}
    \underline{\hspace{0.5em}\ifanswer{#1}\else{(\arabic{ifillin})}\fi\hspace{0.5em}}
}

\newcommand{\pickout}[1]{
  \hfill[\makebox[1.5em]{\answer{#1~}}]
}

\newcommand{\pickoutx}[1]{
  \rule{0pt}{6ex}\raisebox{1.5ex}{\answer{#1~}}
}

\newcommand{\ignorepars}{\@ifnextchar\par{\expandafter\ignorepars\@gobble}{}}

\newenvironment{problemreal}{
    \stepcounter{problem}
    \arabic{problem}.\ignorespaces
}{\ifsheet\else\bigskip\fi\par}
\newenvironment{solutionreal}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi
    \textsf{解}\quad\ignorepars
}{\ifanswer\hfill\ensuremath{\square}\fi\par}
\newenvironment{proofreal}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi
    \textsf{证明}\quad\ignorepars
}{\ifanswer\hfill\ensuremath{\square}\bigskip\fi\par}
\newenvironment{analysisreal}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi
    \textsf{解析}\quad\ignorepars
}{\ifanswer\hfill\ensuremath{\square}\bigskip\fi\par}

\newenvironment{problem}{\problemreal}{\endproblemreal}
\newenvironment{solution}{\solutionreal}{\endsolutionreal}
\newenvironment{proof}{\proofreal}{\endproofreal}
\newenvironment{analysis}{\analysisreal}{\endanalysisreal}
\newenvironment{extracomment}{}{}
\newenvironment{sheetcontents}{}{}
\newenvironment{studentanswer}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi \\
}{}

% 增加只在试卷里面换页的命令
\newcommand{\cuznewpage}{\ifanswer\else\newpage\fi}
\newcommand{\cuzvfill}{\ifanswer\else\vfill\fi}
\newcommand{\cuzvempty}[1]{\ifanswer\else\vspace*{#1}\fi}

\AtBeginDocument{
    \ifanswer
        \excludecomment{extracomment}
        \excludecomment{studentanswer}
    \else
        \excludecomment{solution}
        \excludecomment{proof}
        \excludecomment{analysis}
    \fi
    \ifsheet
        \excludecomment{problem}
        \excludecomment{extracomment}
    \else
        \excludecomment{sheetcontents}
        \excludecomment{studentanswer}
    \fi
}

\newlength{\xxla}
\newlength{\xxlb}
\newlength{\xxlc}
\newlength{\xxld}
\newlength{\lhalf}
\newlength{\lquarter}
\newlength{\lmax}

\newcommand{\options}[4]{
    \par
  \settowidth{\xxla}{(A)~#1~}
  \settowidth{\xxlb}{(B)~#2~}
  \settowidth{\xxlc}{(C)~#3~}
  \settowidth{\xxld}{(D)~#4~}

  \ifthenelse{\lengthtest{\xxla>\xxlb}}{\setlength{\lmax}{\xxla}}{\setlength{\lmax}{\xxlb}}
  \ifthenelse{\lengthtest{\xxlc>\lmax}}{\setlength{\lmax}{\xxlc}}{}
  \ifthenelse{\lengthtest{\xxld>\lmax}}{\setlength{\lmax}{\xxld}}{}
  \setlength{\lhalf}{0.5\linewidth}
  \setlength{\lquarter}{0.25\linewidth}
  \ifthenelse{\lengthtest{\lmax>\lhalf}}{
    \begin{enumerate}[label=(\Alph*),parsep=0ex,itemsep=0ex,leftmargin=2em, topsep=0ex]
      \item #1
      \item #2
      \item #3
      \item #4
    \end{enumerate}
  }{
    \ifthenelse{\lengthtest{\lmax>\lquarter}}{
      \makebox[\lhalf][l]{(A)~#1~}%
      \makebox[\lhalf][l]{(B)~#2~}\\%
      \makebox[\lhalf][l]{(C)~#3~}%
      \makebox[\lhalf][l]{(D)~#4~}\\%
      \vspace{-3ex}
    }{
      \makebox[\lquarter][l]{(A)~#1~}%
      \makebox[\lquarter][l]{(B)~#2~}%
      \makebox[\lquarter][l]{(C)~#3~}%
      \makebox[\lquarter][l]{(D)~#4~}%
    }
  }
}

% 修改列表间距
\setitemize[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setenumerate[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setdescription{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}

% 代码设置
\RequirePackage{minted,relsize}
\usemintedstyle{bw}
\setminted{%
    autogobble,% automatically remove the spaces to the left of the code
    % linenos=true,% show line numbers
    fontsize={\smaller[1]},% smaller font size
    % escapeinside=@@,% insert latex code between @ and @
    % frame=lines,% frame styles: none or lines
    % numbers=both,% show line numbers on: left, right, both or none
    mathescape=true,% insert math code
}%
\setmintedinline{%
    fontsize={\smaller[1]},
}%
% \setmonofont{Fira Code}

% 数学公式均为行间形式
\everymath{\displaystyle}

% 调整fancyvrb环境与正文的间距，用于调整默认minted环境与正文的间距
\newlength{\fancyvrbtopsep}
\newlength{\fancyvrbpartopsep}
\FV@AddToHook{\FV@ListParameterHook}{\topsep=\fancyvrbtopsep\partopsep=\fancyvrbpartopsep}
\setlength{\fancyvrbtopsep}{0.5ex}
\setlength{\fancyvrbpartopsep}{0.5ex}