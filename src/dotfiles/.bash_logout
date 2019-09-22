FILES=('.lesshst' '.viminfo' '.wget-hsts')
# Delete all files on logout
for file in ${FILES[@]}; do test -e $file && rm $file; done

