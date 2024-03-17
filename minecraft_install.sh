#Specify the interpreter
#!/usr/bin/bash
#Update
sudo yum update -y
#Install packages and EPEL repository
sudo yum install -y nano java-17-openjdk open-vm-tools curl wget unzip grep openssl git python3 pip libcurl
sudo pip3 install requests bs4
sudo dnf install -y epel-release
sudo dnf install -y screen ufw cockpit
sudo systemctl enable --now ufw.service
sleep 5
sudo systemctl enable --now cockpit.socket
sudo systemctl restart cockpit
sleep 5
#Exception firewall rules for Java version
sudo ufw allow 25565/tcp
#Exception firewall rules for Bedrock version
sudo ufw allow 19132/udp
#Create directory data at /
sudo mkdir /data
#Extract folder
sudo tar -xvf minecraft_bedrock_updater.tar /data
#Delete archive
sudo rm -f minecraft_bedrock_updater.tar
#Create user mcserver
sudo useradd -m mcserver
#Allow access and edit
sudo usermod -a -G mcserver $USER
#Creating service file
sudo touch /etc/systemd/system/mcbedrock.service
#Change directory
cd /etc/systemd/system/
#Insert text
sudo tee > mcbedrock.service << 'EOF'
[Unit]
Description=Minecraft Bedrock Server
Wants=network-online.target
After=network-online.target

[Service]
Type=forking
User=mcserver
Group=mcserver
ExecStart=/usr/bin/bash /data/minecraft_bedrock_updater/updater/start_server.sh
ExecStop=/usr/bin/bash /data/minecraft_bedrock_updater/updater/stop_server.sh
WorkingDirectory=/data/minecraft_bedrock_updater/running/
Restart=always
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
EOF

#Change permission
chown -R mcserver: /data/minecraft_bedrock_updater/

#Enable service
systemctl enable mcbedrock

#Install - update minecraft
python3 ./updater/mcserver_autoupdater.py

#Set automatic scheduling for update
cat <<EOF | crontab -
0 5 * * * /usr/bin/python3 /data/minecraft_bedrock_updater/updater/mcserver_autoupdater.py > /data/minecraft_bedrock_updater/updater/cron.log
EOF
#Restart cron service
service crond reload
