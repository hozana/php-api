#!/bin/sh

echo 'Install and upgrade composer'

CURRENT_UID=$(id -u)
if [ "$CURRENT_UID" -ne 0 ]; then
    echo "You must be root to run this script"
    exit 1
fi

if [ -f /usr/local/bin/composer ]; then
    echo "Composer is already installed, I will only self-update"
else
    EXPECTED_SIGNATURE=$(curl -s -L https://composer.github.io/installer.sig)
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    RESULT=$?
    rm composer-setup.php

    chmod +x composer.phar
    mv composer.phar /usr/local/bin/composer

    mkdir -p /.composer || true
    chmod -R 777 /.composer
fi

/usr/local/bin/composer self-update --stable --no-interaction --clean-backups

exit $RESULT
