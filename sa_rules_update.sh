#!/bin/bash
#
# versao 1.0
#
# INFORMAÇÕES
#   sa_rules_update.sh
#
# DESCRICAO
#   Atualiza regras de anti-spam dos servidores de E-mail
#
# NOTA
#   Testado e desenvolvido no Centos 6,7,8(stream)
#
#  DESENVOLVIDO_POR
#  Jeferson Zacarias Sens       -        jefersonz.sens@gmail.com
#
#########################################################################################################################################

# Variaveis
rules='
Hardtec_subject.cf
Hardtec_body.cf
Hardtec_from.cf
Hardtec_whitelist.cf
'
log="/var/log/spamrule.log"
paramwget=" --directory-prefix=/tmp/ -q --no-check-certificate"
getfile="/usr/bin/wget"

#Função responsavel pelo Log
Func.Log(){
    if [ -z "$1" ]; then
        cat
    else
        printf '%s\n' "$@"
    fi | tee -a "$log"
}

Func.Restart(){
    service mailscanner restart
    restart=$?

    if [ $restart != 0 ]; then
            service MailScanner restart
    fi
    Func.Remove
}

#Função responsavel por limpar os arquivos baixados
Func.Remove() {
    for rule in $rules; do
    echo "Removendo arquivo temporario $rule"
    rm -rfv /tmp/$rule
    done
    return 1
}

#Função responsavel por checar os arquivos Baixados
Func.Copy() {
    for rule in $rules; do
        cp -f /tmp/"$rule" /etc/mail/spamassassin/"$rule"
    done
    Func.Restart
}

#Função responsavel por comparar os arquivos baixados com os atualmente ultilizados
Func.Comp() {
    for rule in $rules; do
    echo "$rule"
        if  ! diff --brief /tmp/$rule /etc/mail/spamassassin/$rule >/dev/null; then
            Func.Copy
            return 1
        fi
    done
        Func.Remove
}

#Função responsavel por efetuar a checagem da existencia dos arquivos
Func.Check() {
    for rule in $rules; do
    if [ -f "/etc/mail/spamassassin/$rule" ]; then
        echo "O arquivo $rule existe."
    else
        echo "O arquivo $rule não existe, criando o arquivo"
        echo ""
        touch /etc/mail/spamassassin/$rule
        echo "Arquivo $rule criado."
    fi
    done
    Func.Comp
}

#Função Inicial!
Func.Init(){
    echo ""
    if [ -f "$getfile" ]; then
    echo ''
    else
        yum install wget -y
    fi
    echo "Iniciando atualização das regras anti-spam"
    echo ""
    for rule in $rules; do
    echo "Iniciando download do arquivo de regras $rule"
    wget $paramwget https://raw.githubusercontent.com/Crusher131/sa-hardtec-cf/main/$rule
    echo "Download finalizado"
    done
    Func.Check
}

#Função do crontab
Func.Cron(){
    if [ -f "/scripts/sa_rules_update.sh" ]; then
    echo ""
    else
        touch /scripts/sa_rules_update.sh
    fi
    wget $paramwget https://raw.githubusercontent.com/Crusher131/sa-hardtec-cf/main/sa_rules_update.sh
    if  ! grep -F "30 * * * * root /scripts/sa_rules_update.sh >/dev/null 2>&1" /etc/crontab; then
        echo "30 * * * * root /scripts/sa_rules_update.sh >/dev/null 2>&1" >> /etc/crontab

    fi
        if ! grep -F "30 20 * * * root /scripts/sa_rules_update.sh >/dev/null 2>&1" /etc/crontab; then
            echo ""
        else
            sed -i '/30 20 .* root \/scripts\/sa_rules_update.sh.*/d' /etc/crontab
    fi
    if  ! diff --brief /tmp/sa_rules_update.sh /scripts/sa_rules_update.sh >/dev/null; then
        cp -f /tmp/sa_rules_update.sh /scripts/sa_rules_update.sh
        chmod +x /scripts/sa_rules_update.sh
    fi
    rm -rfv /tmp/sa_rules_update.sh
    for rule in $rules; do
        echo "Removendo arquivo temporario $rule"
        rm -f /tmp/$rule
        echo "Download finalizado"
    done
Func.Init
}

Func.Cron 2>&1 | Func.Log "$@"
