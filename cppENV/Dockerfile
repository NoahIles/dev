# Debian CPP Development environment 
# Updated 17 September 2021 by Noah Iles
# Developed for use in a vscode docker devcontainer Optimized for arm64
FROM debian:latest
LABEL DockerFile.Version=debian_1.1
ENV userFolder="/root"
#* Add Latest Version of CPP tools to sources 
RUN echo 'deb http://deb.debian.org/debian testing main' >> /etc/apt/sources.list
#* Update && Install everything Everything
RUN apt update -y && \
    apt upgrade -y
#* Install Development Tools
RUN apt install --no-install-recommends -y \
    valgrind g++ gdb \
    make clang cppcheck \
    curl zsh git tldr
RUN apt install --no-install-recommends -y  \
    ca-certificates clangd-9 \
    bear ssh
#* Oh-my-ZSH: Plugin Manager
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN chsh -s /bin/zsh
#* Installs ZSH syntax highlighting
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $userFolder/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
#* Install Zsh jump for moving around directories faster
RUN git clone https://github.com/agkozak/zsh-z $userFolder/.oh-my-zsh/plugins/zsh-z
#* Install Shell theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $userFolder/.oh-my-zsh/custom/themes/powerlevel10k

#* Update tldr: short cli usage examples
RUN mkdir -p ${userFolder}/.local/share/tldr
RUN tldr --update
#* Misc directories for volume's
RUN mkdir -p ${userFolder}/.vscode-server/extensions
RUN touch ${userFolder}/.zsh_history
#* Default CPP formatting config 
RUN echo "BasedOnStyle: Google\nColumnLimit: 0" > ${userFolder}/.clang-format

COPY .zshrc ${userFolder}/
COPY .p10k.zsh ${userFolder}/
# COPY /Users/nislander/.p10k /root/ #//! Idk why this doesn't work

WORKDIR "${userFolder}/dev"
ENTRYPOINT [ "zsh" ] 
