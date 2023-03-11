
# Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

conda install numpy scipy pandas
conda install ipython jupyter

pip install scikit-optimize
pip install seaborn toolz
pip install trash-cli

# dua cli
curl -LSfs https://raw.githubusercontent.com/Byron/dua-cli/master/ci/install.sh | \
    sh -s -- --git Byron/dua-cli --crate dua --tag v2.17.4

# # Fzf
# git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
# ~/.fzf/install

# # Autojump
# git clone git://github.com/wting/autojump.git
# cd autojump && ./install.py


# Up arrow searches through partial matches
echo '
set completion-ignore-case On
set show-all-if-ambiguous on
"\e[A": history-search-backward
"\e[B": history-search-forward
' >> ~/.inputrc


# Julia
export PYTHON=`which python`
# install julia somehow
#  add Glob JLD DataStructures Printf PyCall LatinHypercubeSampling Parameters Distributions JSON CSV DataFrames DataFramesMeta

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install pipe-rename
cargo install ouch