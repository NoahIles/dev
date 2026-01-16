
# Copy Fish Config 
echo "Running Shared scripts"

# Fish 
cp -r $PARENT_DIR/env/fish/* $HOME/.config/fish/
echo "source $HOME/.config/fish/essentials.fish" >> $HOME/.config/fish/config.fish
# Fisher
#fisher


