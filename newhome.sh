# Initalize home directory in attached volume
cp -rT /etc/skel .
echo 'PATH="$PATH:/usr/local/bundle/bin"' >> .profile
# And install SpaceVim!
curl -sLf https://spacevim.org/install.sh | bash
