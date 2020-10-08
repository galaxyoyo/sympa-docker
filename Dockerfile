FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNLEVEL=1
ENV PERL_MM_USE_DEFAULT=1

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

RUN cpan install SOAP::Lite

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
COPY trusted_applications.conf.template /etc/sympa/trusted_applications.conf.template
COPY nginx.conf.template /etc/nginx/site.conf.template

RUN mkdir /etc/sympa/transport && \
	touch /etc/sympa/transport/sympa_transport && \
	ln -s /etc/sympa/transport/sympa_transport /etc/sympa/sympa_transport

COPY wwsympa /etc/init.d/wwsympa
RUN chmod +x /etc/init.d/wwsympa

COPY sympasoap /etc/init.d/sympasoap
RUN chmod +x /etc/init.d/sympasoap

RUN touch /etc/sympa/transport.sympa \
	/etc/sympa/virtual.sympa && \
	chown sympa:sympa /etc/sympa/*.sympa

RUN postmap hash:/etc/sympa/transport.sympa && \
	postmap hash:/etc/sympa/virtual.sympa

COPY whitelist-1.1/custom_actions /etc/sympa/custom_actions
COPY whitelist-1.1/scenari /etc/sympa/scenari
COPY whitelist-1.1/web_tt2 /etc/sympa/web_tt2
RUN touch /etc/sympa/search_filters/whitelist.txt /etc/sympa/search_filters/modlist.txt
RUN chown -R sympa:sympa /etc/sympa

EXPOSE 25 80 465

VOLUME /var/lib/sympa \
	/var/spool/sympa \
	/etc/sympa/robots \
	/etc/sympa/transport \
	/etc/sympa/trusted_applications

ENV DOMAINS="localhost"
