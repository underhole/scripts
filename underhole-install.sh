#!/usr/bin/env bash
#====================HEADER==========================================|
#AUTOR
# Jefferson 'Slackjeff' Rocha <root@slackjeff.com.br>
#
#PROGRAMA
# Configurador rede underhole.
#====================================================================|

###################################
#==========================VARS
###################################
PRG='Underhole-Install'
VERSION='1.0'

#Colors
red='\033[31;1m'
blue='\033[34;1m'
end='\033[m'

###################################
#==========================TEST
###################################
# Box de checagem se deps existem.
for check in 'ssh' 'sftp'; do
    if ! type "$check" &>/dev/null; then
        _PRINT "Parece que o $check não está instalado. ABORTANDO."
        exit 1
    fi
done

#User is root?
[[ "$UID" != "0" ]] && { _PRINT "HEY need root bro."; exit 1;}

###################################
#==========================FUNC
###################################


# Função para exibir ajuda.
_HELP()
{
	cat <<EOF
$PRG - [OPTIONS]
USAGE:

install
    Configure your underhole.
help
    Show this help and exit.

EOF
}

# Função de print.
_PRINT()
{
	echo -e "${blue}$@${end}"
	exit 1
}

# Função para instalação UNDERHOLE.
_INSTALL()
{
  echo -e "##### $PRG INSTALL #####\n"
  # User add bro
 	read -p 'NAME OF YOUR HOLE: ' username
 	[[ -z "$username" ]] && { _PRINT '$username NULL. ABORTED.'; exit 1;}
 	read -p "CONFIRM ${username}? [Y/n]" confirm
  confirm="${confirm:=y}" # Auto enter ;)
  confirm="${confirm,,}"  # Lowercase
  [[ "$confirm" != 'y' ]] && exit 0 # Bye bye!.
  local homeuser="/home/${username}"
  useradd -m -d "$homeuser" "$username"
  echo -e "${red}===> Insert SECURE PASS for YOUR HOLE.${end}\n"
  # Change password
  passwd "$username" || return 1

  # Usuário root é o dono de tudo ;)
  if [[ -d "$homeuser" ]]; then
      chown -R root:root "$homeuser" || return 1
      chmod 755 "$homeuser" || return 1
  else
    	_PRINT "Your HOME ${homeuser} is NULL..."
  fi

    #+++++++++++++++++++++++
    #   Configuração SSH
    #+++++++++++++++++++++++
 echo -e "${red}===> Send CONFIGURE for ssh config...${end}\n"
 local sshd_config='/etc/ssh/sshd_config'
 [[ ! -e "$sshd_config" ]] && { _PRINT "$sshd_config dont exist. ABORTED.";exit 1;}
 # Enviando para arquivo de configuração sshd
 cat <<EOF >> "$sshd_config"

##########################
# SFTP UNDERHOLE CONFIG
##########################
Match User ${username}
ForceCommand internal-sftp
PasswordAuthentication yes
ChrootDirectory /home/${username}
PermitTunnel no
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
EOF

    # Desmarcando opções uteis para
    # segurança do servidor.
    sed -i 's@#Subsystem.*sftp.*@Subsystem   sftp    /usr/libexec/sftp-server@' "$sshd_config" || exit 1
    sed -i 's@#Protocol 2@Protocol 2@' "$sshd_config" || exit 1
    sed -i 's@#PermitRootLogin.*@PermitRootLogin no@' "$sshd_config" || exit 1
    local osrelease='/etc/os-release'
    if [[ -e "${osrelease}" ]]; then
        local distro="$(grep -E '^(NAME|name)' /etc/os-release | cut -d '=' -f '2')"
        distro="${distro//\"/}" # Troque " por nada.
        if [[ "$distro" =~ (S|s)lackware ]]; then
            /etc/rc.d/rc.sshd stop
            /etc/rc.d/rc.sshd start
        else
	          systemctl restart sshd
	      fi
    else
        _PRINT "Please restart your ${red}ssh server${end}"
    fi
    echo "ssh server ok!"
    return 0
}

###################################
#==========================MAIN
###################################

case $1 in
    install)
        _INSTALL || exit 1
    ;;
    help)
    	_HELP
    ;;
    *) _HELP
    ;;
esac
