# List directory contents
alias ls='ls -hG'
alias ll='ls -l'
alias la='ll -a'

# Interactive mode
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Fundamentals
alias :='cd ..'
alias sudo='sudo '

# Network utilities
alias onl='ping -c 10 1.1.1.1'

# Webdev utilities
alias sf='php bin/console'
alias sft='php bin/phpunit'
alias sql='mysql --pager --auto-vertical-output'

# System packages
alias audit-system='pkg audit -F'
alias update-system='freebsd-update fetch install'

# Cleanup utilities
alias rmclh='rm ~/.bash_history && history -cw'
alias rmpyc='find . -name "*.pyc" -type f -delete'
alias rmdss='find . -name "*.DS_Store" -type f -delete'

