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
        \RequirePackage{xhfill}
        \RequirePackage{booktabs}
        \RequirePackage{subcaption}
        \RequirePackage{wrapfig}
        \RequirePackage{multicol}

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

        \RequirePackage{ifplatform}
        \iflinux
            \setCJKmainfont{AdobeSongStd-Light}[%
                AutoFakeBold=4,
                ItalicFont=AdobeKaitiStd-Regular,
            ]
            \setCJKsansfont{AdobeHeitiStd-Regular}[%
                AutoFakeBold=4,
            ]%
            \setCJKmonofont{AdobeFangsongStd-Regular}[%
                AutoFakeBold=4,
            ]%
        \fi

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

        \prop_new:N \g__cuz_answers_prop
        \prop_new:N \g__cuz_answer_last_keys_prop
        \prop_new:N \g__cuz_answer_lists_prop
        \prop_new:N \g__cuz_answer_counts_prop
        \prop_new:N \g__cuz_answer_ref_indices_prop
        \seq_new:N \l__cuz_answer_key_parts_seq
        \clist_new:N \l__cuz_answer_keys_clist
        \tl_new:N \l__cuz_answer_prefix_tl
        \tl_new:N \l__cuz_answer_key_tl
        \tl_new:N \l__cuz_answer_list_tl
        \tl_new:N \l__cuz_answer_row_tl
        \tl_new:N \l__cuz_answer_table_tl
        \int_new:N \l__cuz_answer_count_int
        \int_new:N \l__cuz_answer_ref_index_int
        \int_new:N \l__cuz_answer_total_int

        \msg_new:nnn { cuzexam } { duplicate-answer-key }
        { Answer~key~'#1'~is~already~defined.\\Use~a~unique~key~for~\string\cuzanswerdef. }

        \msg_new:nnn { cuzexam } { undefined-answer-key }
        { Answer~key~'#1'~is~undefined.\\Define~it~first~with~\string\cuzanswerdef. }

        \msg_new:nnn { cuzexam } { answer-prefix-exhausted }
        { Answer~prefix~'#1'~has~no~more~stored~answers~to~reference.\\Define~another~answer~or~use~an~explicit~key. }

        \cs_new_protected:Nn \cuz_answer_set_prefix:n
        {
            \seq_set_split:Nnn \l__cuz_answer_key_parts_seq { : } { #1 }
            \seq_pop_left:NN \l__cuz_answer_key_parts_seq \l__cuz_answer_prefix_tl
        }

        \cs_new_protected:Nn \cuz_answer_append_key:nn
        {
            \prop_get:NnNTF \g__cuz_answer_lists_prop { #1 } \l__cuz_answer_list_tl
            {
                \prop_gput:Nnx \g__cuz_answer_lists_prop { #1 }
                { \l__cuz_answer_list_tl , #2 }
            }
            {
                \prop_gput:Nnn \g__cuz_answer_lists_prop { #1 } { #2 }
            }
            \prop_gput:Nnn \g__cuz_answer_last_keys_prop { #1 } { #2 }
        }

        \cs_new_protected:Nn \cuz_answer_update_count_from_key:nn
        {
            \seq_set_split:Nnn \l__cuz_answer_key_parts_seq { : } { #2 }
            \seq_pop_left:NN \l__cuz_answer_key_parts_seq \l_tmpa_tl
            \seq_if_empty:NF \l__cuz_answer_key_parts_seq
            {
                \tl_set:Nx \l_tmpb_tl { \seq_item:Nn \l__cuz_answer_key_parts_seq { 1 } }
                \regex_match:nnTF { \A\d+\Z } { \l_tmpb_tl }
                {
                    \prop_get:NnNTF \g__cuz_answer_counts_prop { #1 } \l_tmpc_tl
                    {
                        \int_set:Nn \l__cuz_answer_count_int
                        { \int_max:nn { \l_tmpb_tl } { \l_tmpc_tl } }
                    }
                    {
                        \int_set:Nn \l__cuz_answer_count_int { \l_tmpb_tl }
                    }
                    \prop_gput:Nnx \g__cuz_answer_counts_prop { #1 }
                    { \int_use:N \l__cuz_answer_count_int }
                }
                { }
            }
        }

        \cs_new_protected:Nn \cuz_answer_register:nnn
        {
            \prop_if_in:NnTF \g__cuz_answers_prop { #2 }
            { \msg_error:nnn { cuzexam } { duplicate-answer-key } { #2 } }
            {
                \prop_gput:Nnn \g__cuz_answers_prop { #2 } { #3 }
                \cuz_answer_append_key:nn { #1 } { #2 }
                \cuz_answer_update_count_from_key:nn { #1 } { #2 }
            }
        }

        \cs_generate_variant:Nn \cuz_answer_register:nnn { Vnn, nVn }
        \cs_generate_variant:Nn \prop_item:Nn { NV }

        \cs_new_protected:Nn \cuz_answer_def:nn
        {
            \tl_if_in:nnTF { #1 } { : }
            {
                \cuz_answer_set_prefix:n { #1 }
                \cuz_answer_register:Vnn \l__cuz_answer_prefix_tl { #1 } { #2 }
            }
            {
                \prop_get:NnNTF \g__cuz_answer_counts_prop { #1 } \l_tmpa_tl
                { \int_set:Nn \l__cuz_answer_count_int { \l_tmpa_tl + 1 } }
                { \int_set:Nn \l__cuz_answer_count_int { 1 } }
                \prop_gput:Nnx \g__cuz_answer_counts_prop { #1 }
                { \int_use:N \l__cuz_answer_count_int }
                \tl_set:Nx \l__cuz_answer_key_tl
                { #1 : \int_use:N \l__cuz_answer_count_int }
                \cuz_answer_register:nVn { #1 } \l__cuz_answer_key_tl { #2 }
            }
        }

        \cs_new_protected:Nn \cuz_answer_get_list:n
        {
            \prop_get:NnNTF \g__cuz_answer_lists_prop { #1 } \l__cuz_answer_list_tl
            { \clist_set:NV \l__cuz_answer_keys_clist \l__cuz_answer_list_tl }
            { \msg_error:nnn { cuzexam } { undefined-answer-key } { #1 } }
        }

        \cs_new:Nn \cuz_answer_value_from_list_index:n
        {
            \tl_set:Nx \l__cuz_answer_key_tl
            { \clist_item:Nn \l__cuz_answer_keys_clist { #1 } }
            \prop_item:NV \g__cuz_answers_prop \l__cuz_answer_key_tl
        }

        \cs_new_protected:Nn \cuz_answer_ref:n
        {
            \prop_if_in:NnTF \g__cuz_answers_prop { #1 }
            { \prop_item:Nn \g__cuz_answers_prop { #1 } }
            {
                \prop_if_in:NnTF \g__cuz_answer_lists_prop { #1 }
                {
                    \cuz_answer_get_list:n { #1 }
                    \prop_get:NnNTF \g__cuz_answer_ref_indices_prop { #1 } \l_tmpa_tl
                    { \int_set:Nn \l__cuz_answer_ref_index_int { \l_tmpa_tl + 1 } }
                    { \int_set:Nn \l__cuz_answer_ref_index_int { 1 } }
                    \int_compare:nNnTF
                    { \l__cuz_answer_ref_index_int } > { \clist_count:N \l__cuz_answer_keys_clist }
                    { \msg_error:nnn { cuzexam } { answer-prefix-exhausted } { #1 } }
                    {
                        \prop_gput:Nnx \g__cuz_answer_ref_indices_prop { #1 }
                        { \int_use:N \l__cuz_answer_ref_index_int }
                        \cuz_answer_value_from_list_index:n { \l__cuz_answer_ref_index_int }
                    }
                }
                { \msg_error:nnn { cuzexam } { undefined-answer-key } { #1 } }
            }
        }

        \cs_new_protected:Nn \cuz_pickout_table_head:nnn
        {
            \tl_clear:N \l__cuz_answer_row_tl
            \int_step_inline:nn { #2 }
            {
                \int_compare:nF { ##1 = 1 }
                { \tl_put_right:Nn \l__cuz_answer_row_tl { & } }
                \int_compare:nNnTF { #1 + ##1 - 1 } > { #3 }
                { }
                {
                    \tl_put_right:Nx \l__cuz_answer_row_tl
                    { \exp_not:N \CJKnumber { \int_eval:n { #1 + ##1 - 1 } } }
                }
            }
        }

        \cs_new_protected:Nn \cuz_pickout_table_body:nnn
        {
            \tl_clear:N \l__cuz_answer_row_tl
            \int_step_inline:nn { #2 }
            {
                \int_compare:nF { ##1 = 1 }
                { \tl_put_right:Nn \l__cuz_answer_row_tl { & } }
                \int_compare:nNnTF { #1 + ##1 - 1 } > { #3 }
                { }
                {
                    \tl_put_right:Nx \l__cuz_answer_row_tl
                    {
                        \exp_not:N \pickoutxref
                        {
                            \clist_item:Nn \l__cuz_answer_keys_clist
                            { \int_eval:n { #1 + ##1 - 1 } }
                        }
                    }
                }
            }
        }

        \cs_new_protected:Nn \cuz_makepickouttable:nn
        {
            \cuz_answer_get_list:n { #2 }
            \int_set:Nn \l__cuz_answer_total_int { \clist_count:N \l__cuz_answer_keys_clist }
            \tl_clear:N \l__cuz_answer_table_tl
            \int_step_inline:nnnn { 1 } { #1 } { \l__cuz_answer_total_int }
            {
                \cuz_pickout_table_head:nnn { ##1 } { #1 } { \l__cuz_answer_total_int }
                \tl_put_right:Nx \l__cuz_answer_table_tl
                {
                    \exp_not:N \hline
                    \exp_not:V \l__cuz_answer_row_tl
                    \exp_not:N \\
                    \exp_not:N \hline
                }
                \cuz_pickout_table_body:nnn { ##1 } { #1 } { \l__cuz_answer_total_int }
                \tl_put_right:Nx \l__cuz_answer_table_tl
                {
                    \exp_not:V \l__cuz_answer_row_tl
                    \exp_not:N \\
                }
            }
            \tl_put_right:Nn \l__cuz_answer_table_tl { \hline }
            \begin{tabularx}{\textwidth}{|*{#1}{X<{\centering}|}}
                \tl_use:N \l__cuz_answer_table_tl
            \end{tabularx}
        }

        \cs_new_protected:Nn \cuz_makefillinlist:nn
        {
            \cuz_answer_get_list:n { #2 }
            \int_compare:nNnTF { #1 } > { 1 }
            { \begin{multicols}{#1} }
            { }
            \begin{enumerate}[label=(\arabic*)]
                \int_step_inline:nn { \clist_count:N \l__cuz_answer_keys_clist }
                {
                    \item \underline{\makebox[\linewidth][l]{\answer{\cuz_answer_value_from_list_index:n { ##1 }}}}
                }
            \end{enumerate}
            \int_compare:nNnTF { #1 } > { 1 }
            { \end{multicols} }
            { }
        }

        \NewDocumentCommand{\cuzanswerdef}{mm}
        { \cuz_answer_def:nn { #1 } { #2 } }

        \NewDocumentCommand{\cuzanswerref}{m}
        { \cuz_answer_ref:n { #1 } }

        \NewDocumentCommand{\makepickouttable}{mm}
        { \cuz_makepickouttable:nn { #1 } { #2 } }

        \NewDocumentCommand{\makefillinlist}{mm}
        { \cuz_makefillinlist:nn { #1 } { #2 } }

        \ExplSyntaxOff

        \newcommand{\cuzsubject}[1]{\def\cuz@subject{#1}}
        \newcommand{\cuzkeywords}[1]{\def\cuz@keywords{#1}}
        \newcommand{\cuzacademicyear}[1]{\def\cuz@academicyear{#1}}
        \newcommand{\cuzsemester}[1]{\def\cuz@semester{#1}}
        \newcommand{\cuzcourse}[1]{\def\cuz@course{#1}}
        \newcommand{\cuzlecturers}[1]{\def\cuz@lecturers{#1}}
        \newcommand{\cuzexamstage}[1]{\def\cuz@examstage{#1}}
        \newcommand{\cuzexamtype}[1]{\def\cuz@examtype{#1}}
        \newcommand{\cuzpapertype}[1]{\def\cuz@papertype{(#1)}}
        \providecommand{\cuz@totalparts}{0}
        \newcommand{\cuznumberparts}[1]{\gdef\cuz@totalparts{#1}}

        \newcommand{\underspace}[1]{\underline{\hspace{#1}}}

        \newcounter{cuz@scoretableparts}
        \newcounter{cuz@detectedparts}

        % 计分表制作
        \newcommand{\cuz@scoretable}{
            \newcounter{cuz@numbercolumns}
            \setcounter{cuz@numbercolumns}{\value{cuz@scoretableparts}+3}
            \begin{tabularx}{\textwidth}{|c|X|c|*{\thecuz@scoretableparts}{X<{\centering}|}}
                \hline
                \multirow{3}{*}{总分}
                 & \multirow{2}{*}{}
                 & 题号
                 & \repeatcell{\value{cuz@scoretableparts}}{text=\CJKnumber{##1}}
                \\
                \cline{3-\thecuz@numbercolumns}
                 &                                                            & \multirow{2}{*}{题分}
                 & \eline{\value{cuz@scoretableparts}}
                \\
                 &                                                            &                     & \eline{\value{cuz@scoretableparts}}
                \\
                \hline
            \end{tabularx}
        }

        \newcommand{\cuz@titleending}{
            \ifanswer
                ~\cuz@papertype~卷参考答案
            \else
                \ifsheet
                    ~\cuz@papertype~卷答卷
                \else
                    ~\cuz@papertype~卷
                \fi
            \fi
        }

        % 试卷头制作
        \newcommand{\makehead}{
            \begin{center}
                \parbox{\textwidth}{\centering \zihao{4} \heiti \bfseries 浙江传媒学院《\cuz@course》\cuz@examstage\cuz@examtype\cuz@titleending
                }\\
                \vspace{1em}
                \underline{\quad\cuz@academicyear\quad}学年\quad 第\underline{~\cuz@semester~}学期
                \quad 任课教师\underline{\quad\cuz@lecturers\quad}\\
                \vspace{.5em}
                \ifanswer\else%
                    \strut\xrfill[-0.5ex]{0.5pt}~学院~\xrfill[-0.5ex]{0.5pt}~班
                    ~\quad~姓名~\xrfill[-0.5ex]{0.5pt}~学号
                    ~\xrfill[-0.5ex]{0.5pt}
                    \vspace{.5em}
                    \ifnum\value{cuz@scoretableparts}>0\relax
                        \cuz@scoretable
                    \fi
                \fi
                \vspace{-2ex}
            \end{center}
        }

        \newcommand{\cuz@footnotetext}{《\cuz@course》\cuz@examstage\cuz@examtype\cuz@titleending \quad 第~\thepage~页，共~\pageref{LastPage}~页}

        % 去掉页眉下划线
        \renewcommand{\headrulewidth}{0pt}
        % 装订线页眉外侧超宽6em
        \fancyheadoffset[L]{6em}
        \fancyhf{}
        \pagestyle{fancy}
        \cfoot{\zihao{-5}\cuz@footnotetext}
        \lhead{
            \ifthenelse{\isodd{\thepage}}{
                \cuz@gutter
            }{}
        }

        \newcommand{\cuz@gutter}{
            \begin{tikzpicture}[remember picture,overlay,very thick,font=\zihao{-3}]
                \path (current page.south west) +(2.5cm,2.5cm)  coordinate (a);
                \path (current page.north west) +(2.5cm,-2.5cm) coordinate (b);
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
            \stepcounter{cuz@detectedparts}
            \setcounter{problem}{0}
            \setcounter{ifillin}{0}
            \stepcounter{section}
            \vspace{-1ex}
            \ifsheet
                \ifanswer
                    \vspace*{2ex}
                    {\zihao{4}\bfseries\heiti{\Chinese{section}、#1}(#2)}
                \else
                    \begin{tabularx}{\textwidth}{@{}Xr}
                        \cline{2-2}
                        \multirow[b]{2}{=}[-1.3ex]{\zihao{4}\heiti{\Chinese{section}、#1}(#2)}
                         & \multicolumn{1}{|c|}{\hfill 得 \hfill 分 \hfill~}
                        \\
                        \cline{2-2}
                         & \multicolumn{1}{|c|}{\parbox{\textwidth}{\vspace{5ex}}}
                        \\
                        \cline{2-2}
                    \end{tabularx}
                \fi
            \else
                \vspace*{2ex}
                {\zihao{4}\bfseries\heiti{\Chinese{section}、#1}(#2)}
            \fi
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
    \hspace*{-1em}\underline{\hspace{0.5em}\ifanswer{#1}\else{(\arabic{ifillin})}\fi\hspace{0.5em}}\hspace*{-.5em}
}

\newcommand{\fillinref}[1]{
    \fillin{\cuzanswerref{#1}}
}

\newcommand{\fillinxref}[2]{
    \fillinx{#1}{\cuzanswerref{#2}}
}

\newcommand{\fillindexref}[1]{
    \fillindex{\cuzanswerref{#1}}
}

\newcommand{\pickout}[1]{
    ~\strut~\hfill(\makebox[1.5em]{\answer{#1~}})\par
}

\newcommand{\pickoutx}[1]{
    \rule{0pt}{6ex}\raisebox{1.5ex}{\answer{#1~}}
}

\newcommand{\pickoutref}[1]{
    \pickout{\cuzanswerref{#1}}
}

\newcommand{\pickoutxref}[1]{
    \pickoutx{\cuzanswerref{#1}}
}

\newcommand{\ignorepars}{\@ifnextchar\par{\expandafter\ignorepars\@gobble}{}}

\newenvironment{problemreal}{
    \stepcounter{problem}
    \arabic{problem}.\ignorespaces
}{\par\ifsheet\else\fi}
\newenvironment{solutionreal}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi
    \textsf{解答}\quad\ignorepars
}{
    % \ifanswer\strut\hfill\ensuremath{\square}\else\par\fi
}
\newenvironment{proofreal}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi
    \textsf{证明}\quad\ignorepars
}{\ifanswer\strut\hfill\ensuremath{\square}\else\par\fi}
\newenvironment{analysisreal}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi
    \textsf{解析}\quad\ignorepars
}{\ifanswer\strut\hfill\ensuremath{\square}\else\par\fi}

\newenvironment{problem}{\problemreal}{\endproblemreal}
\newenvironment{problemx}{\problemreal}{\endproblemreal}
\newenvironment{solution}{\solutionreal}{\endsolutionreal}
\newenvironment{solutionx}{
    \textsf{解答}\quad\ignorepars
}{\ifanswer\strut\hfill\ensuremath{\square}\else\par\fi}
\newenvironment{proof}{\proofreal}{\endproofreal}
\newenvironment{analysis}{\analysisreal}{\endanalysisreal}
\newenvironment{extracomment}{
    \zihao{4}\heiti
}{}
\newenvironment{sheetcontents}{}{}
\newenvironment{studentanswer}{
    \ifsheet
        \stepcounter{problem}
        \arabic{problem}\quad
    \fi\par
}{}
\newenvironment{studentanswerx}{
    \par
}{}

% 增加只在试卷里面换页的命令
\newcommand{\cuznewpage}{\ifanswer\else\newpage\fi}
\newcommand{\cuzvfill}{\ifanswer\else\vfill\fi}
\newcommand{\cuzvempty}[1]{\ifanswer\else\vspace*{#1}\fi}

\AtBeginDocument{
    \setcounter{cuz@scoretableparts}{\cuz@totalparts}
    \ifanswer
        \excludecomment{extracomment}
        \excludecomment{studentanswer}
        \excludecomment{studentanswerx}
    \else
        \excludecomment{solution}
        \excludecomment{solutionx}
        \excludecomment{proof}
        \excludecomment{analysis}
    \fi
    \ifsheet
        \excludecomment{problem}
        \excludecomment{extracomment}
    \else
        \excludecomment{sheetcontents}
        \excludecomment{studentanswer}
        \excludecomment{studentanswerx}
    \fi
}

\AtEndDocument{
    \immediate\write\@auxout{%
        \string\gdef\string\cuz@totalparts{\arabic{cuz@detectedparts}}%
    }
    \ifnum\value{cuz@scoretableparts}=\value{cuz@detectedparts}\relax
    \else
        \ClassWarningNoLine{cuzexam}{Detected \arabic{cuz@detectedparts} parts. Rerun to update the header score table}%
    \fi
}

\newlength{\xxla}
\newlength{\xxlb}
\newlength{\xxlc}
\newlength{\xxld}
\newlength{\lhalf}
\newlength{\lquarter}
\newlength{\lmax}
\newlength{\lpadding}
\setlength{\lpadding}{0.1em}

\newcommand{\options}[4]{
    \settowidth{\xxla}{A.~#1~}
    \settowidth{\xxlb}{B.~#2~}
    \settowidth{\xxlc}{C.~#3~}
    \settowidth{\xxld}{D.~#4~}
    \ifthenelse{\lengthtest{\xxla>\xxlb}}{\setlength{\lmax}{\xxla}}{\setlength{\lmax}{\xxlb}}
    \ifthenelse{\lengthtest{\xxlc>\lmax}}{\setlength{\lmax}{\xxlc}}{}
    \ifthenelse{\lengthtest{\xxld>\lmax}}{\setlength{\lmax}{\xxld}}{}
    \setlength{\lhalf}{0.5\linewidth}
    \setlength{\lquarter}{0.25\linewidth}
    \ifthenelse{\lengthtest{\lmax>\lhalf}}{
        \begin{enumerate}[
                label=\Alph*.,
                labelsep=0.4em,
                parsep=0ex,
                itemsep=0ex,
                leftmargin=1.5em,
                topsep=0ex
            ]
            \item #1
            \item #2
            \item #3
            \item #4
        \end{enumerate}
        % \hspace{\lpadding}\makebox[\lhalf][l]{A.~#1~}\par%
        % \hspace{\lpadding}\makebox[\lhalf][l]{B.~#2~}\par%
        % \hspace{\lpadding}\makebox[\lhalf][l]{C.~#3~}\par%
        % \hspace{\lpadding}\makebox[\lhalf][l]{D.~#4~}\par%
    }{
        \ifthenelse{\lengthtest{\lmax>\lquarter}}{
            \hspace{\lpadding}\makebox[\lhalf][l]{A.~#1~}%
            \makebox[\lhalf][l]{B.~#2~}\par%
            \hspace{\lpadding}\makebox[\lhalf][l]{C.~#3~}%
            \makebox[\lhalf][l]{D.~#4~}\par%
        }{
            \hspace{\lpadding}\makebox[\lquarter][l]{A.~#1~}%
            \makebox[\lquarter][l]{B.~#2~}%
            \makebox[\lquarter][l]{C.~#3~}%
            \makebox[\lquarter][l]{D.~#4~}\par%
        }
    }
}

% 修改列表间距
\setitemize[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setenumerate[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setdescription{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}

% 代码设置
\RequirePackage{minted,relsize}
\usemintedstyle{colorful}
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
\newmintinline{c}{fontsize=\relscale{.95}}
\newminted{c}{escapeinside=@@,frame=single}
\newmintinline{cpp}{fontsize=\relscale{.95}}
\newminted{cpp}{escapeinside=@@,frame=single}
\newmintinline{java}{fontsize=\relscale{.95}}
\newminted{java}{escapeinside=@@,frame=single}
\newmintinline{python}{fontsize=\relscale{.95}}
\newminted{python}{escapeinside=@@,frame=single}
% \setmonofont{Fira Code}

% 数学公式均为行间形式
\everymath{\displaystyle}

% 调整fancyvrb环境与正文的间距，用于调整默认minted环境与正文的间距
\newlength{\fancyvrbtopsep}
\newlength{\fancyvrbpartopsep}
\FV@AddToHook{\FV@ListParameterHook}{\topsep=\fancyvrbtopsep\partopsep=\fancyvrbpartopsep}
\setlength{\fancyvrbtopsep}{0.5ex}
\setlength{\fancyvrbpartopsep}{0.5ex}

\usetikzlibrary{%
    intersections,
    through,
    shapes.geometric,
    shapes.multipart,
    shapes.misc,
    positioning,
    calc,
    arrows,
    graphs,
    math
}

\tikzstyle{terminal} = [
rounded rectangle, thick,
% font = \ttfamily\footnotesize,
draw = black!80,
text = black!80,
text height = 1.6ex,
text depth = .2ex,
]%
\tikzstyle{nonterminal} = [
rectangle, thick,
% font = \ttfamily\footnotesize,
draw = black!80,
text = black!80,
text height = 1.6ex,
text depth = .2ex,
]%
\tikzstyle{comment box} = [
rectangle, very thin,
fill = white,
font = \ttfamily\footnotesize,
text = black!70,
text height = 1.4ex, text depth = .25ex
]%
