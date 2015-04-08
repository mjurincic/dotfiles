# Install oh my zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

mkdir -p ~/.zfunctions
ln -s $PWD/zsh/pure/pure.zsh ~/.zfunctions/prompt_pure_setup
