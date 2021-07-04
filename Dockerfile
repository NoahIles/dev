FROM debian:latest
LABEL DockerFile_Version = debian_0.3

RUN echo 'deb http://deb.debian.org/debian testing main' >> /etc/apt/sources.list

RUN apt update -y && \
    apt upgrade -y

#* Install Development Tools
RUN apt install --no-install-recommends -y \
    valgrind g++ gdb \
    make clang cppcheck \
    zsh \
    git \
    curl \
    tldr && \
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Update tldr
RUN mkdir -p /root/.local/share/tldr
# RUN tldr --update

RUN chsh -s /bin/zsh

# I Dont think this volume is being used at the moment. 
# VOLUME [ "/root/dev/" ] 

# WORKDIR "/root/"
# RUN curl -fsSL -O https://about.gitlab.com/images/press/git-cheat-sheet
# Open this folder on entry
WORKDIR "/root/dev"
# and use/run ZSH on entry 
ENTRYPOINT [ "zsh" ] 
#? Consider Adding a User Flow to this other than root??? 