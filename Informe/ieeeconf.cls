\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ieeeconf}[2026/11/18 Compatibility class for local compilation]
\DeclareOption{9pt}{}
\DeclareOption{10pt}{}
\DeclareOption{onecolumn}{\PassOptionsToClass{onecolumn}{IEEEtran}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{IEEEtran}}
\ProcessOptions\relax
\LoadClass[conference]{IEEEtran}

\makeatletter
\newif\if@ieeeauthorstarted
\newif\if@ieeeaffiliationstarted
\def\@ieeeauthors{}
\def\@ieeeaffiliations{}

\newcommand{\addauthor}[2]{%
  \if@ieeeauthorstarted
    \g@addto@macro\@ieeeauthors{\and}%
  \fi
  \g@addto@macro\@ieeeauthors{\IEEEauthorblockN{#1\textsuperscript{#2}}}%
  \@ieeeauthorstartedtrue
}

\newcommand{\addaffiliation}[2]{%
  \if@ieeeaffiliationstarted
    \g@addto@macro\@ieeeaffiliations{\and}%
  \fi
  \g@addto@macro\@ieeeaffiliations{\IEEEauthorblockA{#2}}%
  \@ieeeaffiliationstartedtrue
}

\AtBeginDocument{%
  \author{\@ieeeauthors\and\@ieeeaffiliations}%
}

\newenvironment{acknowledgments}{%
  \section*{Agradecimientos}
}{}
\makeatother
