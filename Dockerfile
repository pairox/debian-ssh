FROM debian:12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-server ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/run/sshd /root/.ssh \
 && chmod 700 /root/.ssh

# Разрешаем root и пароли (можно оставить и ключи)
RUN sed -ri 's/^#?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
 && sed -ri 's/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
 && echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config \
 && echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config

# Пароль рута пробрасываем через ENV (меняй в compose)
ENV ROOT_PASSWORD=changeme

# Энтрипоинт: ставим пароль, чиним права и запускаем sshd
RUN printf '#!/bin/sh\nset -e\nif [ -n \"$ROOT_PASSWORD\" ]; then echo \"root:$ROOT_PASSWORD\" | chpasswd; fi\nif [ -f /root/.ssh/authorized_keys ]; then chmod 600 /root/.ssh/authorized_keys; fi\nexec /usr/sbin/sshd -D -e\n' > /usr/local/bin/docker-entrypoint.sh \
 && chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 22
CMD ["/usr/local/bin/docker-entrypoint.sh"]