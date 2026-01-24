#!/bin/bash
set -eux

TOMCAT_VERSION=9.0.87
TOMCAT_USER=tomcat
TOMCAT_DIR=/opt/tomcat

# Install dependencies
apt-get update
apt-get install -y openjdk-17-jdk curl

# Create tomcat user
id ${TOMCAT_USER} &>/dev/null || useradd -r -m -U -d ${TOMCAT_DIR} -s /bin/false ${TOMCAT_USER}

# Download & install Tomcat
mkdir -p ${TOMCAT_DIR}
cd /tmp

curl -fLO https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
tar xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz

rm -rf ${TOMCAT_DIR:?}/*
mv apache-tomcat-${TOMCAT_VERSION}/* ${TOMCAT_DIR}/

chown -R ${TOMCAT_USER}:${TOMCAT_USER} ${TOMCAT_DIR}
chmod +x ${TOMCAT_DIR}/bin/*.sh

# systemd service
cat <<EOF >/etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat
After=network.target

[Service]
Type=forking
User=${TOMCAT_USER}
Group=${TOMCAT_USER}
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_HOME=${TOMCAT_DIR}
Environment=CATALINA_BASE=${TOMCAT_DIR}
ExecStart=${TOMCAT_DIR}/bin/startup.sh
ExecStop=${TOMCAT_DIR}/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat
