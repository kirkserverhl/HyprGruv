#!/bin/bash

PACKAGES1=(
  python-ansicolor python-anytree python-btrees python-cairo python-click-help-colors python-click-didyoumean python-click-completion python-click-command-tree python-click-plugins python-cmake-build-extension python-cmd2 python-colorcet python-colorclass python-colored-traceback python-coloredlogs python-colorlog python-colorthief python-colour python-commentjson python-cooldict python-cpplint python-cppy python-cppyy python-crayons  python-crazy-complete python-cssbeautifier python-csscompressor python-cssselect python-cssselect2 python-daiquiri  python-darkdetect python-dasbus  python-easyprocess python-emoji python2 python2-colorama python2-setuptools python2-py-pretty python2-colorpy kvantum-qt4–git python2-graphviz python2-pillow python-yaml python-colorsysplus python-uv python-vapory python-colorpicker  python-django-colorfield python-colorful python-neotermcolor python-nerd-color python-print-color python-pygments-ansi-color  python-termcolor python-xtermcolor python2-pyfiglet python2-wxpython3)

yay -S --noconfirm "${PACKAGES1[@]}"
