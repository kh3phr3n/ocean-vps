# List directory contents
alias ls='ls -h --color=auto'
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
alias sql='mysql --pager --auto-vertical-output'

# Cleanup utilities
alias rmclh='rm ~/.bash_history && history -cw'
alias rmpyc='find . -name "*.pyc" -type f -delete'
alias rmdss='find . -name "*.DS_Store" -type f -delete'

# Security utilities
alias rkhunter='sudo sh -c "rkhunter --propupd && rkhunter --check"'

# System utilities
alias unban-ip='fail2ban-client set sshd unbanip'
alias new-totp='google-authenticator --force --time-based --disallow-reuse --rate-time=30 --window-size=3 --rate-limit=3'
