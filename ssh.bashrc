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

# Create new keys 
gensshpg2() {
    (
        set -e
        if [ $# -eq 0 ]; then
            printf "You need to provide a Host\n"
            return 1
        fi
        if [ -z $SSHPG2ENCRYPTKEY ]; then
            printf "export SSHPG2ENCRYPTKEY to omit this part.\n\n"
            printf "For convenience here a list of your secret gpg keys\n\n"
            gpg --list-secret-keys --with-subkey-fingerprint --list-options no-show-unusable-subkeys
            printf "Please provide the gpgkey: "
            read -r $SSHPG2ENCRYPTKEY
        fi
        GPGDPATH=~/.ssh/gpg.d
        # Split user@host
        SSHHOST=${1#*@}
        SSHUSER=${1%@*}
        # Test if we have to lookup the User
        if [[ $SSHHOST = $SSHUSER ]]; then
            # Lookup User
            SSHEVAL=$(ssh -G $SSHHOST)
            SSHUSER=$(awk '/^user / {print $2}' <<< $SSHEVAL)
        fi
        KEYPATH=$GPGDPATH/$SSHUSER@$SSHHOST.ed25519
        if ! [ -r ${KEYPATH}.gpg ]; then
            ssh-keygen -t ed25519 -f $KEYPATH -C $SSHUSER@$SSHHOST-$USER -P ""
            gpg --batch --encrypt-files --recipient $SSHPG2ENCRYPTKEY $KEYPATH
            rm $KEYPATH
            ssh-add $KEYPATH.gpg
        else
            printf "Key $KEYPATH already exists!\n"
        fi
            printf "Pubkey for $SSHUSER@$SSHHOST:\n\n\t%s\n\n" "$(cat $KEYPATH.pub)"
    )
}

# vim:ts=4 sts=4 sw=4 et ft=bash
