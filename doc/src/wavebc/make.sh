#!/bin/bash
set -x
name=wavebc
dest=tmp

function system {
  "$@"
  if [ $? -ne 0 ]; then
    echo "make.sh: unsuccessful command $@"
    echo "abort!"
    exit 1
  fi
}

rm -rf $dest
mkdir $dest
cp -r fig* mov* $dest

system doconce pygmentize wavebc.do.txt perldoc
mv -f wavebc.do.txt.html $dest

# Sphinx
themes="cbc fenics_minimal1"
for theme in $themes; do
system doconce format sphinx $name
system doconce sphinx_dir copyright='H. P. Langtangen' theme=$theme dirname=sphinx-$theme $name
system doconce split_rst $name
system python automake_sphinx.py
mv -f sphinx-$theme $dest
done


# HTML
system doconce format html $name --html_output=${name}_blueish --html_style=blueish
system doconce format html $name --html_output=${name}_bloodish --html_style=bloodish
system doconce format html $name --html_output=${name}_solarized --html_style=solarized3
system doconce split_html ${name}_solarized
system doconce format html $name --html_output=${name}_cyborg --html_style=bootswatch_cyborg --pygments_html_style=monokai --keep_pygments_html_bg --html_code_style=inherit --html_pre_style=inherit
system doconce split_html ${name}_cyborg
system doconce format html $name --html_output=${name}_journal --html_style=bootswatch_journal
system doconce split_html ${name}_journal

mv -f *.html ._*.html $dest

# PDF
system doconce format pdflatex $name --device=paper
system doconce ptex2tex $name envir=minted  # use more printer friendly verb envir!
system pdflatex -shell-escape $name
makeindex $name
pdflatex -shell-escape $name
mv -f $name.pdf $dest/${name}_4print.pdf

system doconce format pdflatex $name --device=screen
system doconce ptex2tex $name envir=minted
system pdflatex -shell-escape $name
makeindex $name
pdflatex -shell-escape $name
mv -f $name.pdf $dest/${name}.pdf

# IPython notebooks
# Video encoding of the particular format, Image object for figures
system doconce format ipynb $name --ipynb_movie=local --ipynb_figure=Image
# More general HTML handling of ogg, webm, and mp4 alternatives
cp $name.ipynb ${name}_video_encoding.ipynb
# Notebook version with URL for movies and images to be display
# at nbviewer
system doconce format ipynb $name --ipynb_figure=md --ipynb_movie=local --figure_prefix=https://raw.githubusercontent.com/hplgit/wavebc/master/doc/src/wavebc/ --movie_prefix=https://raw.githubusercontent.com/hplgit/wavebc/master/doc/src/wavebc/
cp $name.ipynb ${name}_4nbviewer.ipynb
# Rich HTML code for displaying movies
system doconce format ipynb $name # default: --ipynb_figure=md --ipynb_movie=HTML
mv -f *.ipynb ipynb-${name}-src.tar.gz $dest

# Can now publish $dest directory
doconce format html index
cp index.html ../../pub
cd $dest
dest=../../../pub
cp -r *.html ._*.html *.pdf *-wavebc sphinx-* *.ipynb ipynb*.tar.gz $dest
cd $dest
git add .
