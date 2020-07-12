FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNLEVEL=1

RUN echo exit 0 > /usr/sbin/policy-rc.d && \
	chmod +x /usr/sbin/policy-rc.d

RUN apt update && \
	apt install -y --no-install-recommends rsyslog && \
	rm -rf /var/lib/apt/lists/*

COPY rsyslog.conf /etc/rsyslog.conf
RUN service rsyslog start

RUN echo lists.example.com > /etc/mailname

RUN apt update && \
	apt install -yq --no-install-recommends perl \
	nginx \
	spawn-fcgi \
	doc-base \
	locales \
	logrotate \
	procps \
	libdb5.1 \
	procmail \
	sasl2-bin \
	postfix \
	sympa && \
	rm -rf /var/lib/apt/lists/*

COPY rsyslog.d /etc/rsyslog.d

COPY sympa.conf.template /etc/sympa/sympa/sympa.conf.template

COPY main.cf.template /etc/postfix/main.cf.template
COPY master.cf /etc/postfix/master.cf

COPY entrypoint.sh /root/entrypoint.sh
RUN chmod 0744 /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]

RUN mkdir -p /etc/mail/sympa && \
	mkdir -p /var/spool/sympa && \
	mkdir -p /etc/sympa/robots && \
	chown -R sympa:sympa /var/spool/sympa \
	/etc/mail/sympa \
	/var/spool/sympa \
	/var/lib/sympa \
	/etc/sympa/robots

COPY list_aliases.tt2 /etc/sympa/list_aliases.tt2
COPY transport.sympa.template /etc/sympa/transport.sympa.template
COPY virtual.sympa.template /etc/sympa/virtual.sympa.template
COPY robot.conf.template /etc/sympa/robot.conf.template
COPY nginx.conf.template /etc/nginx/site.conf.template

COPY wwsympa /etc/init.d/wwsympa
RUN chmod +x /etc/init.d/wwsympa

RUN touch /etc/sympa/transport.sympa \
	/etc/sympa/virtual.sympa \
	/etc/sympa/sympa_transport && \
	chmod 0640 /etc/sympa/sympa_transport && \
	chown sympa:sympa /etc/sympa/sympa_transport \
		/etc/sympa/*.sympa

RUN postmap hash:/etc/sympa/transport.sympa && \
	postmap hash:/etc/sympa/virtual.sympa

EXPOSE 25 80 465

VOLUME /var/lib/sympa \
	/var/spool/sympa \
	/etc/sympa/robots

ENV DOMAINS="localhost"
