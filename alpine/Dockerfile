FROM alpine:latest
LABEL DockerFile_Version = alpine_1.1

RUN apk update && \
    apk upgrade

#* Install Development Tools
RUN apk add \
    gcc valgrind g++ gdb make \ 
    zsh \
    curl \
    git \
    npm \ 
    openssh \
    zsh-syntax-highlighting && \
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# dust # nicer du written in rust  

#NPM is the lightest way to install tldr. 
RUN npm install -g tldr && tldr --update

# I Dont think this volume is being used at the moment. 
VOLUME [ "/root/dev/" ] 

WORKDIR "/root/"
RUN curl -fsSL -O https://about.gitlab.com/images/press/git-cheat-sheet.pdf

# COPY .zshrc /root/
# COPY .zprofile /root/

# Open this folder on entry
WORKDIR "/root/dev"
# and use/run ZSH on entry 
ENTRYPOINT [ "zsh" ] 


#? Consider Adding a User Flow to this other than root??? 
#? Consider adding ssh, 