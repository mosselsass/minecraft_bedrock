#Specify the interpreter
#!/usr/bin/bash
#Update
sudo yum update -y
#Install packages and EPEL repository
sudo yum install -y nano java-17-openjdk open-vm-tools curl wget unzip grep openssl git python3 pip libcurl
sudo pip3 install requests bs4
sudo dnf install -y epel-release
sudo dnf install -y screen cockpit
sudo systemctl enable --now cockpit.socket
sudo systemctl restart cockpit
#Exception firewall rules for Java version
sudo firewall-cmd --zone=public --add-port 25565/tcp --permanent
#Exception firewall rules for Bedrock version
sudo firewall-cmd --zone=public --add-port 19132/udp --permanent
#Restart firewall
sudo systemctl restart firewalld
#Create directory data at /
sudo mkdir /data
#Extract folder
sudo tar -xvf minecraft_bedrock_updater.tar -C /data
#Delete archive
sudo rm -f minecraft_bedrock_updater.tar
#Create user mcserver
sudo useradd -m mcserver
sudo usermod -aG wheel mcserver
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
SuccessExitStatus=0 1
WorkingDirectory=/data/minecraft_bedrock_updater/updater
ExecStart=/usr/bin/bash /data/minecraft_bedrock_updater/updater ./start_server.sh >/dev/null 2>&1 &
ExecStop=/usr/bin/bash /data/minecraft_bedrock_updater/updater ./stop_server.sh >/dev/null 2>&1 &
WorkingDirectory=/data/minecraft_bedrock_updater/running/
Restart=always
RestartSec=10
TimeoutStartSec=600
Killmode=process

[Install]
WantedBy=multi-user.target
EOF

#Change permission
sudo chmod +x /data/minecraft_bedrock_updater/updater/start_server.sh
sudo chmod +x /data/minecraft_bedrock_updater/updater/stop_server.sh
sudo chown -R mcserver: /data/minecraft_bedrock_updater/

#Enable service
sudo systemctl enable mcbedrock

#Install - update minecraft
cd /data/minecraft_bedrock_updater/
sudo python3 ./updater/mcserver_autoupdater.py

#Set automatic scheduling for update
cat <<EOF | crontab -
0 5 * * * /usr/bin/python3 /data/minecraft_bedrock_updater/updater/mcserver_autoupdater.py > /data/minecraft_bedrock_updater/updater/cron.log
EOF
#Restart cron service
sudo service crond reload
#Stop minecraft bedrock
sudo systemctl stop mcbedrock
sudo systemctl status mcbedrock
#Creating service file
sudo touch /home/nqe/minecraft_bedrock/parameters.sh
#Change directory
cd /home/nqe/minecraft_bedrock/
#Insert text
sudo tee > parameters.sh << 'EOF'
#!/bin/bash
read -p "Enter your server name : " servername
sed -i '1s/.*/server-name='$servername'/' /data/minecraft_bedrock_updater/running/server.properties

read -p "Enter the type of game mode --> Choose the number corresponding to the desired mode : survival=1, creative=2, adventure=3 : " gamemode
if [ $gamemode -eq 1 ];
then
	sed -i '5s/.*/gamemode=survival/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $gamemode -eq 2 ];
then
	sed -i '5s/.*/gamemode=creative/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $gamemode -eq 3 ];
then
	sed -i '5s/.*/gamemode=adventure/' /data/minecraft_bedrock_updater/running/server.properties
else
	echo "Default : gamemode=survival"
fi

read -p "Force game mode --> Choose the number corresponding to the desired mode : true=1 or false=2 : " forcegamemode
if [ $forcegamemode -eq 1 ];
then
	sed -i '9s/.*/force-gamemode=true/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $forcegamemode -eq 2 ];
then
	sed -i '9s/.*/force-gamemode=false/' /data/minecraft_bedrock_updater/running/server.properties
else
	echo "Default : force-gamemode=false"
fi

read -p "Set difficulty --> Choose the number corresponding to the desired mode : peaceful=1, easy=2, normal=3, hard=4 : " difficulty
if [ $difficulty -eq 1 ];
then
	sed -i '19s/.*/difficulty=peaceful/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $difficulty -eq 2 ];
then
	sed -i '19s/.*/difficulty=easy/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $difficulty -eq 3 ];
then
	sed -i '19s/.*/difficulty=normal/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $difficulty -eq 4 ];
then
	sed -i '19s/.*/difficulty=hard/' /data/minecraft_bedrock_updater/running/server.properties
else
	echo "Default : difficulty=easy"
fi

read -p "Allow cheat --> Choose the number corresponding to the desired mode : true=1 or false=2 : " allowcheats
if [ $allowcheats -eq 1 ];
then
	sed -i '23s/.*/allow-cheats=true/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $allowcheats -eq 2 ];
then
	sed -i '23/.*/allow-cheats=false/' /data/minecraft_bedrock_updater/running/server.properties
else
	echo "Default : allow-cheats=false"
fi

read -p "Allow list --> Choose the number corresponding to the desired mode : true=1 or false=2 : " allowlist
if [ $allowlist -eq 1 ];
then
	sed -i '37s/.*/allow-list=true/' /data/minecraft_bedrock_updater/running/server.properties
elif [ $allowlist -eq 2 ];
then
	sed -i '37/.*/allow-list=false/' /data/minecraft_bedrock_updater/running/server.properties
else
	echo "Default : allow-list=false"
fi

read -p "Enter your Xbox gamername : " gamername
sudo sed -i '1s/.*/[{"ignoresPlayerLimit":false,"name":tempname,"xuid":""}]/' /data/minecraft_bedrock_updater/running/allowlist.json
sudo sed -i -e 's/tempname/'$gamername'/g' /data/minecraft_bedrock_updater/running/allowlist.json
sudo sed -i '1s/.*/[{"permission": "operator","name": "tempname","xuid":""}]/' /data/minecraft_bedrock_updater/running/permissions.json
sudo sed -i -e 's/tempname/'$gamername'/g' /data/minecraft_bedrock_updater/running/permissions.json
EOF

#Change permission
sudo chmod +x parameters.sh

#Setup parameters
sudo -s ./parameters.sh

#Start server
sudo systemctl start mcbedrock