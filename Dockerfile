FROM alpine:latest
LABEL DockerFile_Version = 0.3.1

RUN apk update && \
    apk upgrade

#* Install Development Tools
RUN apk add \
    gcc valgrind g++ gdb \ 
    zsh \
    curl \
    git \
    npm \ 
    # dust # nicer du written in rust  
    make && \
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#NPM is the lightest way to install tldr. 
RUN npm install -g tldr && tldr --update

# #Powershell Stuff
# RUN apk add --no-cache \
#     ca-certificates \
#     less \
#     ncurses-terminfo-base \
#     krb5-libs \
#     libgcc \
#     libintl \
#     libssl1.1 \
#     libstdc++ \
#     tzdata \
#     userspace-rcu \
#     zlib \
#     icu-libs \
#     lttng-ust && \
#     curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/powershell-7.1.3-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz

# RUN mkdir -p /opt/microsoft/powershell/7 && \ 
#     tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
#     chmod +x /opt/microsoft/powershell/7/pwsh && \
#     ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# I Dont think this volume is being used at the moment. 
VOLUME [ "/root/dev/" ] 

WORKDIR "/root/"
RUN curl -fsSL -O https://about.gitlab.com/images/press/git-cheat-sheet.pdf
# Open this folder on entry
WORKDIR "/root/dev"
# and use/run ZSH on entry 
ENTRYPOINT [ "zsh" ] 


#? Consider Adding a User Flow to this other than root??? 
#? Consider adding ssh, 