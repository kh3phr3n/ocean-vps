# Environment variables
export PAGER='less'
export VISUAL='vim'
export EDITOR='vim'
export HISTCONTROL='erasedups'

# Run ssh-agent
[[ -d ~/.ssh ]] && eval $(ssh-agent)

# Load ~/.bashrc
[[ -f ~/.bashrc ]] && source ~/.bashrc

