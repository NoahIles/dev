
# Copy Fish Config 
echo "Running Shared scripts"

# Fish 
cp -r $PARENT_DIR/env/fish/* $HOME/.config/fish/
echo "source $HOME/.config/fish/essentials.fish" >> $HOME/.config/fish/config.fish
# Fisher
#fisher
# cp -r $PARENT_DIR/env/fish/* $HOME/.config/fish/
# echo "source $HOME/.config/fish/essentials.fish" >> $HOME/.config/fish/config.fish

if command -v fish ; then 
  # Install fisher 
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  #fish -c "fisher install"
else
  echo "Fish not installed rerun script with fish on path"
fi


