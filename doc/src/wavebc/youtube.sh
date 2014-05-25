#!/bin/sh
set -x
prog=~/vc/animate/doc/src/animate/src-animate/youtube-upload
dest=hpl@simula.no
pw="bla-bla"
kw="partial differential equations, boundary conditions"
desc="Solution of the linear wave equation with reflecting (Neumann) boundary conditions, d/dx=0, at each end. "

python $prog --email=$dest --password=$pw --title="Demo of reflecting boundary conditions; C=0.5" --description="$desc Courant number 0.5 (implies significant numerical inaccuracy)." --category=Education --keywords="$kw" experiments/gaussian_Nx50_C0.5_un0/movie.flv

