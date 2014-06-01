#!/bin/sh
set -x
name=wavebc
dest=tmp

rm -rf $dest
mkdir $dest
cp -r fig* mov* $dest

doconce pygmentize wavebc.do.txt perldoc
mv -f wavebc.do.txt.html $dest

# Sphinx
themes="cbc fenics_minimal1"
for theme in $themes; do
doconce format sphinx $name
doconce sphinx_dir author='H. P. Langtangen' theme=$theme dirname=sphinx-$theme $name
doconce split_rst $name
python automake_sphinx.py
mv -f sphinx-$theme $dest
done


# HTML
doconce format html $name --html_output=${name}_blueish --html_style=blueish
doconce format html $name --html_output=${name}_bloodish --html_style=bloodish
doconce format html $name --html_output=${name}_solarized --html_style=solarized
doconce split_html ${name}_solarized
doconce format html $name --html_output=${name}_cyborg --html_style=bootswatch_cyborg --pygments_html_style=monokai --keep_pygments_html_bg --html_code_style=inherit --html_pre_style=inherit
doconce split_html ${name}_cyborg
doconce format html $name --html_output=${name}_journal --html_style=bootswatch_journal
doconce split_html ${name}_journal

mv -f *.html ._*.html $dest

# PDF
doconce format pdflatex $name --device=paper
doconce ptex2tex $name envir=minted  # use more printer friendly verb envir!
pdflatex -shell-escape $name
makeindex $name
pdflatex -shell-escape $name
mv -f $name.pdf $dest/${name}_4print.pdf

doconce format pdflatex $name --device=screen
doconce ptex2tex $name envir=minted
pdflatex -shell-escape $name
makeindex $name
pdflatex -shell-escape $name
mv -f $name.pdf $dest/${name}.pdf

# Can now publish $dest directory
cp -r $dest/*.html $dest/._*.html $dest/*.pdf $dest/*-wavebc $dest/sphinx-* ../../pub/
