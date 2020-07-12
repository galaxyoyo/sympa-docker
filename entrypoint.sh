#!/bin/bash

cat /etc/sympa/sympa/sympa.conf.template | sed "s/{{MAIN_LIST_DOMAIN}}/$MAIN_LIST_DOMAIN/g" | sed "s/{{LISTMASTERS}}/$LISTMASTERS/g" | sed "s/{{DB_TYPE}}/$DB_TYPE/g" | sed "s/{{DB_NAME}}/$DB_NAME/g" | sed "s/{{DB_HOST}}/$DB_HOST/g" | sed "s/{{DB_PORT}}/$DB_PORT/g" | sed "s/{{DB_USER}}/$DB_USER/g" | sed "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" > /etc/sympa/sympa/sympa.conf
rm /etc/postfix/main.cf && cat /etc/postfix/main.cf.template | sed "s/{{MAIN_LIST_DOMAIN}}/$MAIN_LIST_DOMAIN/g" > /etc/postfix/main.cf

[[ -d /var/lib/sympa/bounce ]] || mkdir -p /var/lib/sympa/bounce

chown -R sympa:sympa /etc/sympa/sympa_transport \
	/var/spool/sympa \
	/var/lib/sympa

LIST_DOMAINS=$(echo $DOMAINS | tr ";" "\n")
[[ ! -f /etc/sympa/transport.sympa ]] || rm /etc/sympa/transport.sympa
[[ ! -f /etc/sympa/virtual.sympa ]] || rm /etc/sympa/virtual.sympa
touch /etc/sympa/transport.sympa /etc/sympa/virtual.sympa
rm /etc/nginx/sites-available/*
rm /etc/nginx/sites-enabled/*

for domain in $LIST_DOMAINS
do
	echo "Adding domain $domain..."
	[[ -d /etc/sympa/$domain ]] || mkdir -m 0755 /etc/sympa/$domain
	[[ -f /etc/sympa/robots/$domain.conf ]] || cat /etc/sympa/robot.conf.template | sed "s/{{MAILING_LIST_DOMAIN}}/$domain/g" > /etc/sympa/robots/$domain.conf
	[[ -f /etc/sympa/$domain/robot.conf ]] || ln -s /etc/sympa/robots/$domain.conf /etc/sympa/$domain/robot.conf
	chown -R sympa:sympa /etc/sympa/$domain /etc/sympa/robots
	[[ -d /var/lib/sympa/list_data/$domain ]] || mkdir -m 0750 -p /var/lib/sympa/list_data/$domain
	chown -R sympa:sympa /var/lib/sympa/list_data/$domain
	cat /etc/sympa/transport.sympa.template | sed "s/{{MAILING_LIST_DOMAIN}}/$domain/g" >> /etc/sympa/transport.sympa
	cat /etc/sympa/virtual.sympa.template | sed "s/{{MAILING_LIST_DOMAIN}}/$domain/g" >> /etc/sympa/virtual.sympa
	cat /etc/nginx/site.conf.template | sed "s/{{MAILING_LIST_DOMAIN}}/$domain/g" > /etc/nginx/sites-available/$domain
	ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain
	echo "Domain $domain added!"
done

chown -R www-data:www-data /etc/nginx/sites-available /etc/nginx/sites-enabled

service rsyslog restart
service postfix restart

postmap hash:/etc/sympa/transport.sympa
postmap hash:/etc/sympa/virtual.sympa
service postfix reload

/usr/lib/sympa/bin/sympa.pl --health_check
/usr/lib/sympa/bin/sympa_newaliases.pl
service sympa restart
service wwsympa restart

nginx -g "daemon off;"
