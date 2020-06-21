#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible.cfg

cd $SCRIPT_PATH

VAR_HOST="$1"
VAR_MYSQL_VERSION="$2"

if [ "${VAR_HOST}" == '' ] ; then
  echo "No host specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_MYSQL_VERSION}" == '' ] ; then
  echo "No MySQL version specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "$VAR_MYSQL_VERSION" -gt 0 -a "$VAR_HOST" != "" ]; then
  ### Ping host ####
  ansible -i $SCRIPT_PATH/hosts -m ping $VAR_HOST -v

  ### mysql install ####
  ansible-playbook -v -i $SCRIPT_PATH/hosts -e "{mysql_version: '$VAR_MYSQL_VERSION'}" $SCRIPT_PATH/playbook/mysql_install.yml -l $VAR_HOST
else
  echo "Sorry, this script must have 2 parameters to run. So first of all you have to fill up the first parameter with the ansible hostname and the second parameter MySQL version, please have a look at README file for futher information!"
  exit 1
fi
