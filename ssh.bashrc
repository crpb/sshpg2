# Copyright © 2016 Jakub Wilk <jwilk@jwilk.net>
# Copyright © 2024 Christopher Bock <christopher@bocki.com> 
# SPDX-License-Identifier: MIT

agent=$(ssh-agent -a ~/.ssh/agent.socket 2>/dev/null) || {
    . ~/.ssh/agent.vars
}
eval "$agent" > /dev/null
cat > ~/.ssh/agent.vars <<EOF
export SSH_AUTH_SOCK=$SSH_AUTH_SOCK
export SSH_AGENT_PID=$SSH_AGENT_PID
EOF
unset agent

gensspg() {
  (
    set -e
    if [ $# -eq 0 ]; then
      printf "You need to provide a Host\n"
      return 1
    fi
    printf "For convenience here a list of your secret gpg keys\n\n"
    gpg --list-secret-keys --with-subkey-fingerprint --list-options no-show-unusable-subkeys
    printf "Please provide the gpgkey: "
    read -r GPGKEY
    #   CONFGS=( ~/.ssh/config ~gssh/*.ssh )
    GPGDPATH=~/.ssh/gpg.d
    SSHHOST=$1
    SSHEVAL=$(ssh -G $SSHHOST)
    SSHUSER=$(awk '/^user / {print $2}' <<< $SSHEVAL)
    KEYPATH=$GPGDPATH/$SSHUSER@$SSHHOST.ed25519
    ssh-keygen -t ed25519 -f $KEYPATH -C $SSHUSER@$SSHHOST-$USER -P ""
    gpg --batch --encrypt-files --recipient $GPGKEY $KEYPATH
    rm $KEYPATH
    ssh-add $KEYPATH.gpg
  )
}

# vim:ts=4 sts=4 sw=4 et ft=sh
