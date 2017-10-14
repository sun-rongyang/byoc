#!/bin/bash 
#######################################################################
#                  SEND EMAIL TO A (LIST OF) USER(S)                  #
#######################################################################
# usage: . send_mail.sh TO[user list] MESSAGE[file] [SUBJECT]
# bash >= 4.3

## Variables
# Some global variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_LIB_DIR="${PROJECT_ROOT_DIR}/lib"
PROJECT_ETC_DIR="${PROJECT_ROOT_DIR}/etc"
YAML_INTERPRETER="${PROJECT_LIB_DIR}/yaml_interpreter.py"
SEND_MAIL_APP="${PROJECT_LIB_DIR}/send_email.py"
CLUSTER_CONFIG_FILE="${PROJECT_ETC_DIR}/cluster.yaml"
MailServer="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} MailServer)"
MailPassword="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} MailPassword)"
MailAddress="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} MailAddress)"
MailDefaultSubject="$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} MailDefaultSubject)"
# use printf to save \n in a bash variable: printf -v var "string\nwith\n\n"
printf -v MailSignature "$(python ${YAML_INTERPRETER} ${CLUSTER_CONFIG_FILE} MailSignature)"
FROM="${MailAddress}"
# Arguments
if [[ -f $1 ]]; then
    TO_FILE_NAME="$(IFS='/' read -r -a array <<< "$1" && echo ${array[-1]})"
    TO="$(cd "$(dirname "$1")" && pwd)/${TO_FILE_NAME}"
else
    TO="$1"
fi
if [[ -f $2 ]]; then
    MESSAGE_FILE_NAME="$(IFS='/' read -r -a array <<< "$2" && echo ${array[-1]})"
    MESSAGE="$(cd "$(dirname "$2")" && pwd)/${MESSAGE_FILE_NAME}"
else
    #MESSAGE="$2"
    printf -v MESSAGE "$2"
fi
if [[ $3 == "" ]]; then
    SUBJECT="${MailDefaultSubject}"
else
    SUBJECT="${MailDefaultSubject}: $3"
fi

## Program begin
if [[ -f ${TO} ]]; then
    while IFS=" " read -ra userinfo
    do
        useremail=${userinfo[1]}
        python ${SEND_MAIL_APP} ${MailServer} "${MailPassword}" ${FROM} ${useremail} "${MESSAGE}" "${SUBJECT}" "${MailSignature}"
    done < "${TO}"
else
    python ${SEND_MAIL_APP} ${MailServer} "${MailPassword}" ${FROM} ${TO} "${MESSAGE}" "${SUBJECT}" "${MailSignature}"
fi

exit
