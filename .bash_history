ps -ef
docker-machine ls
docker-machine ssh sulzamnew
docker-machine create --driver virtualbox sulzam_Master
docker-machine create --driver virtualbox sulMaster
docker-machine env sulMaster
eval $(docker-machine env sulMaster)
ls -la
docker-machine ls
docker-machine ssh sulMaster
exit
docker-machine ssh sulzamnew
exit
docker-machine create --driver virtualbox sulzamson
docker-machine env sulzamson
eval $(docker-machine env sulzamson)
docker-machine ssh sulzamson
exit
tmux attach -t 2
tmux attach -t sulzamson
tmux ls
exit
pwd
cd /
pwd
ls -la
pwd
vimrc* 
ls vimrc*
ls vim*
dockermachine ssh Master
docker-machine ssh Master
docker-machine ls
ping 192.168.99.102
docker-machine ls
docker-machine ssh sulMaster
tmux attach -t sulzamson
tmux attach -t 2
docker-machine ssh sulzamnew
whatc free -m
wathc free -m
sudo apt install watch
procps free -m
watch free -m
docker-machine ssh sulzamson
ls -la
pwd
]ls -la 
,pwd
pwd
conan
hostname
b
echo "off"
hostname
::
pwd
ls -la
pwd
]ls -la 
pwd
ls -la
pwd
]ls -la 
adduser sulfog sudo
sudo adduser sulfog sudo
exit
ping 10.0.2.5
ifconfig eth0
ifconfig eth1
ifconfig
docker network ls
tmux attach-session -t sulzamsul
ip addr
sudo vim /etc/apt/sources.list
pwd
cd /etc/apt/
ls -la
vim sources.list
sudo apt install vim
ls -la
vim sources.list
sudo vim sources.list
sudo apt-get update
cd /home/sulfog/
sudo apt-get install jq
echo '{ "name":"John", "age":31, "city":"New York" }' | jq .
docker service inspect --format '{{json .Endpoint.VirtualIPs}}' nginx | jq '.'
docker swarm join --token SWMTKN-1-0up29idvpo6fcr17sqepsdm1qzlc4u91ae17x4ba7s946lscoi-7da9o687wuge7stronvcr1tro 192.168.99.101:2377
docker service inspect --format '{{json .Endpoint.VirtualIPs}}' nginx | jq '.'
docker container ls --filter 'label=com.docker.swarm.service.name=lynx' -q
ip addr
docker container exec f729bcf88bd2 lynx -dump 192.168.15.21
docker container exec 13df5e2e3ab8 lynx -dump 192.168.15.21
docker container exec 13df5e2e3ab8 lynx -dump 192.168.99.1
docker container exec 13df5e2e3ab8 lynx -dump 192.168.99.7/24
docker container ls --filter 'label=com.docker.swarm.service.name=lynx' -q
docker container exec 13df5e2e3ab8 lynx -dump 192.168.99.7
docker container run --rm --network nginx nbrown/nwutils dig nginx
ocker container exec 13df5e2e3ab8 lynx -dump nginx
docker container exec 13df5e2e3ab8 lynx -dump nginx
docker ps
for i in {1..8}; do docker container exec f729bcf88bd2 lynx -dump nginx | grep 'IP Address'; done
IP Address: 192.168.35.3:80
IP Address: 192.168.35.6:80
IP Address: 192.168.35.4:80
IP Address: 192.168.35.5:80
IP Address: 192.168.35.3:80
IP Address: 192.168.35.6:80
IP Address: 192.168.35.4:80
IP Address: 192.168.35.5:80
Notice how the requests are distributed by IPVS in round robin manner, to each of the nginx service’s tasks. Let’s remove the services:
$ docker service rm nginx lynx
nginx
lynx
We’ve looked at how Swarm services can be consumed from within a cluster, and we’ll now move on to see how services are consumed from outside the cluster.
External Service Consumption
Routing Mesh
A microservice running in a Swarm Mode cluster makes itself available to consumers external to the cluster through the publication of a port. Similar to the way that an individual container publishes its service using a runtime config option to the docker container run command, a service can be created specifying a port to publish, using the --publish config option. A shortened version, -p, can also be used.
The syntax for defining a port also has a short and long form. The following definitions are equivalent: -p 80:80 and --publish published=80,target=80,protocol=tcp,mode=ingress.
Whichever syntax form we use, when a service’s port is published, it’s published on every node in the cluster. Swarm then makes use of its ‘routing mesh’ in order to route external service requests to the tasks that constitute the service. The diagram below depicts the relationship between the various components:
Routing Mesh
The routing mesh comprises an overlay network, called ingress, netfilter rules and IPVS. Traffic destined for a service can arrive at any cluster node, on the published port, and may originate from an external load balancer. Through a combination of the netfilter rules and IPVS load balancing via the service’s virtual IP, traffic is routed through the ingress network to a service task. This applies, even if the service request arrives on a node which is not running a service task.
Let’s re-create our nginx service, but this time we’ll publish a service port, and then consume the service from outside the cluster. We’ll publish the port, and mount the /etc/hostname file from each cluster node into the container of a corresponding scheduled task, which will appear in the served content. This will help us to see which task is serving each request. We’ll also limit the number of replicas to three, so that we can demonstrate that the cluster node without a task can still receive and service our request:
$ docker service create --detach=false --name nginx --network nginx --publish published=8080,target=80 --mount type=bind,src=/etc/hostname,dst=/etc/docker-hostname,ro --replicas 3 nbrown/nginxhello
eg3wfh346mpo4hyu5wtxutykz
overall progress: 3 out of 3 tasks 
1/3: running   [==================================================>] 
2/3: running   [==================================================>] 
3/3: running   [==================================================>] 
verify: Waiting 1 seconds to verify that tasks are stable...
Let’s determine which of our cluster nodes is running service tasks:
$ docker service ps --format 'table {{.ID}}\t{{.Name}}\t{{.Node}}\t{{.CurrentState}}' nginx
ID                  NAME                NODE                CURRENT STATE
hdgwo2xzmscx        nginx.1             node-03             Running 21 minutes ago
ufs80r1lrihe        nginx.2             node-04             Running 21 minutes ago
de08mumqc9vh        nginx.3             node-02             Running 21 minutes ago
In this case, it’s node-01 that does not have a task for the service.
If you’re following this tutorial using Amazon Web Services, then you’ll need to ensure that the security group you’re using for this exercise, allows ingress through port 8080 from the IP address you are using. If you’re not familiar with how to do this, the first article in this series showed how to do this. We can then point a web browser at the public IP address of any of our cluster nodes, to consume our nginx service. If you’ve created your cluster using Docker Machine, as detailed in the first article, we can easily retrieve the required public IP address for each node:
$ for i in {1..4}; do echo -n "node-0$i: "; docker-machine ip node-0$i; done
node-01: 35.176.22.179
node-02: 52.56.216.120
node-03: 35.176.40.60
node-04: 35.176.7.56
In turn, point your web browser at each node (e.g. 35.176.40.60:8080), and notice how IPVS load balances requests across the tasks for the service. You’ll also notice that the IP address of the serving container is no longer from the nginx network; it’s associated with the ingress network. Be sure to try addressing the node without an nginx service task, and you should have your request served from a task running on one of the other nodes.
Host Mode
Sometimes, there may be a need to bypass Swarm’s routing mesh, and this is possible by specifying mode=host as part of the --publish config option. In this scenario, a task’s port is mapped directly to the node’s port, and service requests directed to that node will be served by the associated task. This is particularly useful if a home-grown routing mesh is required, in place of the one provided by Swarm.
Load Balancing
A final thought should be given over to the load balancing capabilities used by Swarm Mode clusters. IPVS load balancing is based on layer 4 (transport layer) of the OSI model, and routes traffic based on IP addresses, ports and protocols. Whilst IPVS is very fast, as it’s implemented in the Linux kernel, it may not suit all scenarios. Layer 7 (application layer) load balancing is inherently more flexible, but is not provided as part of the Swarm implementation in the Docker Community Edition. Layer 7 load balancing can be implemented as a Swarm service, however, and numerous solutions abound: Docker’s HTTP Routing Mesh, and Traefik, to name just a couple.
Deploying Dockerized Applications with Semaphore
To continuously deploy your project to Docker Swarm, you can use Semaphore’s hosted continuous integration and deployment service. Semaphore’s native Docker platform comes with the complete Docker CLI preinstalled and has full layer caching for tagged Docker images. Take a look at our other Docker tutorials for more information on deploying with Semaphore.
Conclusion
This tutorial has provided an overview of how Docker Swarm makes services available for consumption, both internally and externally. Networking, in general, as well as service discovery techniques, make an enormous topic. We haven’t covered every fine-grained detail, but this tutorial has provided some insight into:
In the next tutorial, we’ll explore how services running in a Swarm cluster can be updated in flight.
If you have any questions and/or comments, feel free to leave them in the section below.
Read next:
for i in {1..8}; do docker container exec 13df5e2e3ab8 lynx -dump nginx | grep 'IP Address'; done
for i in {1..8}; do docker container exec 13df5e2e3ab8 lynx -dump nginx | grep 'IP Address';
for i in {1..8}; do docker container exec 13df5e2e3ab8 lynx -dump nginx | grep 'IP Address'; done
docker service rm nginx lynx
docker ps
docker container run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
docker ip addr
docker ps
docker rm afbea8a9c18c
docker container stop afbea8a9c18c
docker container rm afbea8a9c18c
docker images
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_dat
docker container run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_dat portainer/portainer
IP ADDR
ip addr
sudo apt-get install tmux
tmux
tmus ls
tmux ls
tmux attach -t 0
tmux ls
tmux attach-session -t 0
tmux attach-session -t 1
pwd
cd /
ls -la
vim
cd /etc/
ls -la
cd vim/
ls -la
vim vimrc
sudo vim vimrc
cd /home/sulfog/
tmux
ls -la
sudo mkdir meucontainer
cd meucontainer/
vim Dockerfile
sudo vim Dockerfile
sudo vim Dockerfile 
docker ps
clear
docker ps -a
docker pull jacksonpires/ubuntu-rails-ssh
clear
docker container ls
docker ps
ls -la
clear
docker images
docker run -d -p -v $(pwd):/projects --name railscontainer jacksonpires/ubuntu-rails-ssh
docker run -d -P -v $(pwd):/projects --name railscontainer jacksonpires/ubuntu-rails-ssh
clear
docker ps
docker port railscontainer
clear
ssh app@localhost -P :32769
ssh app@localhost -p 32769
clear
ruby -v
git --version
irb
sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates
sudo apt-get install -y postfix
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee
git init
/etc/gitlab/gitlab.rb
pwd
cd /etc/gitlab/
cd /
pwd
ls -la
cd etc/
ls
ls *git
ls *g
clear
cd /home/sulfog/
sudo apt-get install -y postfix
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
sudo EXTERNAL_URL="https://gitlab.com" apt-get install gitlab-ee
sudo EXTERNAL_URL="https://localhost/" apt-get install gitlab-ee
cd /etc/apt/sources.list.d/
ls -la
vim gitlab_gitlab-ee.list 
cd /home/sulfog/
sudo EXTERNAL_URL="https://packages.gitlab.com/gitlab/gitlab-ee/linuxmint/" apt-get install gitlab-ee
gitlabctl reconfigure
gitlab-ctl reconfigure
gitlab -v
sudo apt install ruby-gitlab
gitlab-ctl reconfigure
gitlab -v
sudo apt install gitlab-cli
sudo apt-get update
gitlab
gitlab-ctl reconfigure
docker swarm leave
clear
docker compose ls
docker-compose ps
sudo apt install docker-compose
clear
docker-compose -version
docker --version
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl && mv kubectl /usr/local/bin/
sudo chmod +x kubectl && mv kubectl /usr/local/bin/
cd Downloads/
ls
sudo su
cd /home/sulfog/
clear
exit
docker-machine ssh sulzamson
docker-machine ls
clear
docker swarm ls
clear
docker ls
docker ps -a
clear
docker node ls
clear
docker machine ls
docker-machine ls
docker node ls
clear
docker-machine ssh sulzamnew
docker-machine ssh master
doker-machine ssh sulMaster
ssh docker-machine sulMaster
docker info
Let’s determine which of our cluster nodes is running service tasks:
docker info
docker-machine create -d virtualbox     --swarm     --swarm-master     --swarm-discovery token://<token>     --swarm-strategy binpack     --swarm-opt heartbeat=5s     upbeat
docker-machine ssh sulMaster
docker ps
ps -a
docker ps
docker port 12aed978fb10 
ip addr
service virtualbox status
docker --version
docker ps
docker-machine --version
iptables
iptables -h
ip addr
ip addr eth0
ifconfig eth0
ip addr "eth0"
ip a
docker ps -a
docker port 12aed978fb10
docker-machine create --driver virtualbox master
docker-machine env master
sudo eval $(docker-machine env master)
sudo docker eval $(docker-machine env master)
docker-machine env master
eval $(docker-machine env master)
ls -la
docker-machine ls
docker-machine start sulzamnew
docker-machine env sulzamnew
eval $(docker-machine env sulzamnew)
docker-machine start sulzamson
docker-machine env
docker-machine env sulzamson
eval $(docker-machine env sulzamson)
docker-machine ls
docker-machine start sulMaster
docker-machine env sulMaster
eval $(docker-machine sulMaster)
docker-machine ls
tmux
exit
docker-machine ssh dev00
docker-machine ssh dev02
docker-machine ssh dev01
docker-machine ssh devAA
docker-machine ssh devAC
docker-machine ssh devAB
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
docker ps
docker container stop portainer
docker run -d -p 8000:8000 -p 9000:9000 --name=portainerr --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
sudo apt-install pgadmin
docker pull dpage/pgadmin4
docker ps
docker run -p 80:80     -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com'     -e 'PGADMIN_DEFAULT_PASSWORD=SuperSecret' docker run -p 80:80-e 'PGADMIN_DEFAULT_EMAIL=sulzam@gmail.com' -e 'PGADMIN_DEFAULT_PASSWORD=segredO' docker run -ti -p 80:80 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SuperSegredO' \
docker run -ti -p 80:80 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SuperSegredO' \
docker images
docker run -ti -p 80:80 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SuperSegredO' /dpage/pgadmin4 
docker run -p 80:80 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SuperSegredO' /dpage/pgadmin4 
docker run -p 80:80 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SuperSegredO' dpage/pgadmin4 
docker run -ti -p 80:80 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SegredO' dpage/pgadmin4 
docker run -ti -p 80:80 5432:5432 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SegredO' dpage/pgadmin4 
docker run -ti -p 5432:5432 -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com' -e 'PGADMIN_DEFAULT_PASSWORD=SegredO' dpage/pgadmin4 
docker -v
docker-machine create --driver virtualbox dev01
docker-machine create --driver virtualbox dev02
docker
docker-machine ls
docker-machine rm master
docker-machine rm sulMaster
docker-machune ls
docker-machine ls
docker-machine rmnsulzamnew
docker-machine rm sulzamnew
docker-machine rm sulzamnew -f
docker-machine rm sulzamson -f
docker-machine rm sulMaster -f
docker-machine ls
docker-machine rm dev02 -f
clear
docker-machine create --driver virtualbox dev00
docker-machine create --driver virtualbox dev02
clear
docker-machine ls
tmux
docker-machine kill dev00
docker-machine kill dev01
docker-machine kill dev02
docker-machine ls
docker-machine rm dev00
docker-machine rm dev01
docker-machine rm dev02
docker-machine status
clear
docker-machine create --driver virtualbox devAA
docker-machine regenerate-certs [devAA]
docker-machine ls
docker-machine rm devAA -f
docker ps
clear
docker-machine create --driver virtualbox devAA
docker-machine env devAA
eval $(docker-machine env devAA)
clear
docker-machine create --driver virtualbox devAB
docker-machine env devAB
eval $(docker-machine env devAB)
clear
docker-machine create --driver virtualbox devAC
docker-machine env devAC
eval $(docker-machine env devAC)
clear
docker-machine ls
clear
tmux
docker-machine ls
docker-machine prune -f
docker-machine rm devAA
docker-machine rm devAb -f
docker-machine rm devAB -f
docker-machine rm devAC -f
clear
docker run -ti --name devAA debian
pwd
docker --version
docker ps
clear
exit
docker-machine ls
eval $(docker-machine dev00)
eval $(docker-machine dev01)
docker-machine --help
exit
sudo add-apt-repository ppa:dyatlov-igor/sierra-theme
sudo apt update
sudo apt install sierra-gtk-theme       # point releases
clear
sudo apt install sierra-gtk-theme-git   # git master branch
clear
pwd
cd /
pwd
ls -la
cd etc/
ls -la
exit
sudo apt-get install gtk2-engines-murrine gtk2-engines-pixbuf
flatpak install flathub org.gtk.Gtk3theme.High-Sierra
exit
docker --version
docker-compose --version
clear
docker attach -ti devAA
docker attach --help
docker attach --detach-keys string devAA
docker container start devAA
docker attach --detach-keys string devAA
docker attach devAA
docker info
docker ps -a
clear
docker container strat devAA
docker container start devAA
docker container attach devAA
docker images
docker ps -a
docker container devAA start
docker container start devAA, devAB, devAC
docker container start devAA
docker container attach devAA
clear
docker container ls
docker exec -it devAB /bin/bash
docker container attach devAA/bin/bash
docker container attach devA
docker ps
docker exec -it devAA /bin/bash
clear
docker exec -it devAC /bin/bash
clear
docker ps -a
node -version
sudo apt install nodejs
clear
npm init -y
sudo apt install npm
clear
npm init -y
sudo npm init -y
touch index.js
sudo su
docker --version
docker run -ti --name devAA debian
docker run -ti --name devAB debian
docker run -ti --name devAC debian
docker ps
docker container ls
docker images ls
clear
docker ps -a
docker rm --force devAC
docker rm --force devAB
docker rm --force devAA
docker images ls
clear
docker run --publish 8000:8080 --detach --name devAA debian
docker images
clear
docker run --publish 8000:8081 --detach --name devAA debian
docker rm --force devAA
docker run --publish 8000:8081 --detach --name devAA debian
docker rm --force devAA
docker run --publish 8900:8081 --detach --name devAA debian
docker run --publish 8900:8082 --detach --name devAB debian
docker run --publish 8900:8083 --detach --name devAC debian
clear
docker images ls
docker ps -a
clear
docker container exec [OPTIONS] CONTAINER COMMAND [ARG...]
docker container exec -ti -d --name devAA
docker container exec -ti -d devAA
docker container attach devAA
docker container start devAA
tmux
docker container start devAA
docker container attach devAA
docker container ps
docker images ls
docker images
clear
docker ps -a
clear
docker container start
docker container start --help
docker container start -i -t -a devAA
docker container start -i -a devAA
docker container start -i -a devAB
docker container start -i -a devAC
docker ps -a
clear
docker container ls
docker images ls
clear
docker ps
docker ps -a
clear
docker start  `docker ps -q -l`devAA
docker prune devAA
docker container prune devAA
docker container prune -f
docker ps -a
clear
docker container run -i -d --name devAA ubuntu
docker container attach -i devAA
docker run -it --name devAB ubuntu /bin/bash
docker run -it --name devAC ubuntu /bin/bash
docker ps -a
clear
tmux
clear
docker ps -a
docker container exec -ti -d devAA
docker container exec -i -d devAA/bin/bash
docker container exec -it devAA/bin/bash
docker exec -it devAA/bin/bash
clear
docker exec -it devAB /bin/bash/
docker exec -it devAB /bin/bash
clear
docker ps -a
docker port 204d30e1c1de
docker port 09ba902b1842
docker port 12aed978fb10
docker port 9c9439f3e099
docker rmi 12aed978fb10 -f
docker rm 12aed978fb10 -f
docker rm 9c9439f3e099 -f
clear
docker image
docker images
docker prune
docker container prune
clear
docker ps -a
docker container rm devAA devAB devAC
docker container rm devAA devAB devAC --force
clear
docker-machine --version
clear
service virtualbos status
service virtualbox status
sudo servie virtualbox start
uname -a
ps -ef
clear
docker-machine create --driver virtualbox devAA
docker-machine env devAA
eval $(docker-machine env devAA)
docker-machine ls
docker-machine create --driver virtualbox devAB
docker-machine env devAB
eval $(docker-machine env devAB)
docker-machine create --driver virtualbox devAC
run: docker-machine env devAC
docker-machine env devAC
eval $(docker-machine env devAC)
clear
code .
apt-get update
sudo apt-get update
clear
code .
cd Downloads/
ls -la
sudo chmodm +x code_1.48.0-1597304990_amd64.deb 
sudo chmod +x code_1.48.0-1597304990_amd64.deb 
sudo apt install ./code_1.48.0-1597384990_amd64.deb
sudo dpkg -i code_1.48.0-1597304990_amd64.deb
sudo apt-get install -f
clear
cd ..
pwd
ls -la
clear
docker-machine ls
sudo mkdir dockernode
cd dockernode
ls
code .
sudo code .
cd ..
sudo code . --user-data -dir /dockernode
/dockernode/code .
ls
cd dockernode/code .
code ./dockernode/
sudo code --user-data-dir="~/.vscode-root"
cd dockernode/
clear
code .
sudo code --user-data-dir="~/.vscode-root"
clear
docker-compose up
docker-compose -v
docker-compose up
docker images
sudo docker-compose up
docker ps -a
sudo su
ls -la
code .
docker build -t sulzam/dockernode .
pwd
docker -v
clear
docker build -t zamp23/dockernode .
cd ..
pwd
ls -la
cd dockerfiles/
ls -la
touch Dockerfile
sudo adduser sulfog
sudo usermod -aG sudo sulfog
ls -la
touch Dockerfile
clear
touch /home/sulfog/dockerfiles/Dockerfile
clear
sudo touch Dockerfile
sudo vim Dockerfile 
ls -la
sudo vim index.js
sudo vim .dockerignore
sudo vim package.json
cd ..
cd dockernode
ls -la
cd ..
cd dockerfiles
sudo mkdir node_modules
cd node_modules/
cd /home/sulfog/dockernode/node_modules/
cp *.* home/sulfog/dockerfiles/node_modules/
ls
cd home/sulfog/
pwd
cd /home/sulfog/
ls -la
pwd
cd dockerfiles
ls 
cd node_modules/
cd dockernode/node_modules/
pwd
cd /home/sulfog/dockernode/
cd node_modules/
cp *.* home/sulfog/dockerfiles/node_modules/
cd..
cd /home/sulfog/
pwd
cd dockerfile
cd dockerfiles
clear
ls -la
sudo docker build -t zampa/dockerfiles .
clear
sudo npm init -y
npm install express
npm-debug.log
cd /home/sulfog/dockernode/
ls -la
cd ..
exit
docker -v
docker-compose -v
docker build -t sulfog/dockernode .
docker run -p 3000:3000 -d sulfog/dockernode
clear
docker ps
npm install nodemon
docker-compose up
yarn add dotenv
yarn -v
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install yarn
clear
yarn add dotenv
yarn
yarn sequelize db:migrate
clear
yarn sequelize db:migrate
docker ps
cd ~
ls 
pwd
clear
docker run --name database -e POSTGRES_PASSWORD=0aaaa8128ed46bae6c4eb7cb30020e36 -p 5432:5432 --restart always -d postgres
docker ps
su deploy
sudo su
git clone https://github.com/rocketseat-content/masterclass-nodejs-sql.git  deploynode
ls -la
cd deploynode
ls 
clear 
code .
LS -LA
ls -la
git login
git --help
clear
docker ps
ls -la
yarn sequelize db:migrate
yarn
git remote -y
git remote -v
git remote add deploy https://github.com/sulfog/nodedeploy.git
git push deploy master
git add.
git push deploy master
git st
git status
git add src/config/.env.example
git commit -m
git commit -m,
git commit -m "Setup deployment config"
git push
git push deploy master
git remote -v
git remote set-url origin git@github.com:sulfog/nodedeploy.git
git remote -v
ssh-keygen
cd ..
pwd
ls -la
cd .ssh/
ls -la
cat id_rsa.pub
cd ..
pwd
code .
clear
code .
exit
docker-machine --version
docker-machine create --driver virtualbox novozam
docker-machine env novozam
eval $(docker-machine env novozam)
clear
docker machine ls
docker ps
docker-machine ls
docker-machine ssh novozam
clear
apt upgrade
uname -a
uname -r
apt upgrade
clear
docker-machine create --driver virtualbox denovo
docker-machine env denovo
eval $(docker-machine env denovo)
clear
nodejs -v
ls -la
cd .ssh
ls -la
cd ..
clear
adduser deploy
sudo su
clear
sudo su
ls -la
chown -R sulfog:sulfog dockerfiles/
sudo su
curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
nodejs -v
sudo apt-get install -y nodejs
clear
npm -v
node -v
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install yarn
clear
yaer -v
clear yarm -v
clear
yarn -v
sudo su
exit
pwd
code .
exit
ls -al ~/.ssh
ssh-keygen -t rsa -b 4096 -C "sulzam@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/SHA256:2p2Xo4FrtjLhqEp/Hu3aazlcpev27vuvKHuqggtKmeg sulzam@gmail.com
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
ssh root@165.232.50.40
ssh deploy@165.232.50.40
ssh root@165.232.50.40
ssh deploy@165.232.50.40
ssh root@165.232.50.40
exit
pwd
cd ..
ls -la
cd sulfog/.ssh/
ls ĺa
ls -la
cat id_rsa.pub
clear
cd ..
pwd
exit
pwd
cd .ssh/
ls -la
cat id_rsa
cd ..
clear
exit
code .
exit
dotenv -v
yarn add dotenv
clear
yarn
yarn sequelize db:migrate
dotenv --v
clear
dotenv -v
clear
yarn add dotenv
clear
yarn sequelize db:migrate
clear
yarn sequelize db:migrate
clear
yarn
docker ps
usermod -aG docker sulzam
clear
yarn
yarn sequelize db:migrate
yarn
git remote -v
git commit -m "Novosetup deployment config"
git push deploy master
clear
git remote -v
yarn add dotenv
sequelize db:migrate
yarn sequelize db:migrate
docker ps
docker exec -it newdatabase /bin/bash
docker ps
sudo docker rm database -f
sudo docker rm newdatabase -f
docker ps
docker images
clear
exit
code .
sudo yum install openssh-clients
yarn install openssh-clients
yarn add openssh-clients
openssh -v
sudo apt install openssh-clients
clear
sudo apt-get install openssh-client
clear
sudo apt-get install openssh-server
clear
code --folder-uri "vscode-remote://ssh root@165.232.50.40/code/deploynode"
ssh sulfog@165.232.50.40
ssh root@165.232.50.40
ssh-add
ssh-add -l
stat --format '%a' id_rsa
pwd
cd .ssh/
stat --format '%a' id_rsa
stat --format '%a' id_rsa.pub
cd ..
ssh root@165.232.50.40
cd .ssh/
chmod 600 ~/.ssh/id_rsa
stat --format '%a' id_rsa
stat --format '%a' id_rsa.pub
ssh sulfog@165.232.50.40
cd ..
clear
ssh-add
ssh-copy-id sulfog@165.232.50.40
ssh sulfog@165.232.50.40
ssh-keygen
cat ~/.ssh/id_rsa.pub
clear
ssh root@165.232.50.40
ssh sulfog@165.232.50.40
ssh root@165.232.50.40
clear
ls -la
cd deploynode/
ls -la
cat env
code .
git remote -v
git commit -m "Setup deployment config"
git push deploy master
git commit -m "Setup deployment config"
git push deploy master
ssh deploy@165.232.50.40
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
paulo
docker exec -it database /bin/bash
which psql
psql
docker exec -it database /bin/bash
clear
docker ps
psql -h localhost -p 49153 -d docker -U docker --password
psql -h localhost -p 5432 -d docker -U docker --password
psql -h localhost -p 49153 -d docker -U docker --password
docker ps -a
psql -h localhost -p 5432 -d docker -U postgres --SegredO23
clear
docker exec -it database /bin/bash
psql -h localhost -p 49153 -d docker -U docker --password
psql -h localhost -p 5432 -d database -U postgres --password SegredO23
docker -v
ls -la
cd ..
pwd
ls -la
docker ps
docker exec -it database /bin/bash
clear
ls -la
cd deploynode/
ls -la
cd /home/sulfog/
pwd
ls -la
cd meucontainer/
ls -la
docker --version
docker-compose -v
node -v
clear
vim Dockerfile
ls -la
rename Dockerfile oldDockerfile
sudo rena Dockerfile OldDockerfile
sudo rename Dockerfile OldDockerfile
cd ..
ls -la
pwd
cd meucontainer/
ls -la
sudo rm Dockerfile 
ls -la
vim Dockerfile
ls 
sudo vim Dockerfile
ls -la
docker build -t eg_postgresql .
docker ps
docker images
docker run --rm -P --name pg_test eg_postgresql
clear
docker run --rm -t -i --link pg_test:pg eg_postgresql bash
docker ps
docker run --rm -P --name pg_test eg_postgresql
psql -h localhost -p 49153 -d docker -U docker --password
docker ps
clear
docker build -t eg_postgresql .
docker images ls
docker ps
docker images
docker run -d --name newposte eg_postgresql
docker ps
docker exec -it newposte /bin/bash
cd /etc/postgresql/9.3/main/
docker exec -it newposte /bin/bash
docker exec -it newposte bash
ls -la
vim Dockerfile 
sudo vim Dockerfile 
clear
docker images
docker rmi eg_postgresql -f
docker rmi 7f4c2e2683dc -f
docker rm eg_postgresql -f
docker ps
docker rm -f 4575b4cce418
docker rmi 7f4c2e2683dc -f
docker ps
docker images
clear
docker build -t eg_postgresql .
clear
docker images
docker run -d --name newposte 0a1f43a84428
docker ps
docker exec -it newposte bash
docker ps -a
docker rm newposte -f
docker ps
clear
docker run --name newdatabase -e POSTGRES_PASSWORD=6a19356c1a37120e82582361e9b488a3 -P 5432:5432 --restart always -d postgres
docker run --name newdatabase -e POSTGRES_PASSWORD=6a19356c1a37120e82582361e9b488a3 -p 5432:5432 --restart always -d postgres
docker run --name newdatabase -e POSTGRES_PASSWORD=6a19356c1a37120e82582361e9b488a3 -p 15432:5432 --restart always -d postgres
docker rm -f newdatabase
docker run --name newdatabase -e POSTGRES_PASSWORD=6a19356c1a37120e82582361e9b488a3 -p 15432:5432 --restart always -d postgres
docker ps
docker exec -it newdatabase /bin/bash
cd ..
pwd
clear
ssh deploy@165.232.50.40
clear
ls -la
cd deploynode/
ls -la
pwd
cd ..
ls -la
cd meucontainer/
ls -la
cd ..
ls -la
cd deploynode/
ls -la
cp env ./.env
ls -la
cp env ./.env.example
ls -la
sudo vim .env
sudo vim .env.example
code .
docker exec -it nodedeploy /bin/bash
docker ps
docker exec -it database /bin/bash
sudo su
docker ps -a
docker run --help
docker ps
docker exec -it newdatabase /bin/bash
clear
yarn sequelize db:migrate
yarn
code .
ssh deploy@165.232.50.40
clear
code .
docker ps
ssh deploy@165.232.50.40
clear
docker ps
docker exec -it database /bin/bash
clear
ls -la
cd ..
pwd
ls -la
cd /
pwd
ls -la
cd tmp/
ls 
mkdir sqlnode
cd sqlnode/
clear
yarn init -y
yarn add express pg pg-hstore sequelize
node -v
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
command -v nvm
nvm install 10.10.0
yarn add express pg pg-hstore sequelize
yarn add sequelize-cli -D
code .
yarn dev
docker ps
wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && sudo bash install.sh
curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add
sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
sudo apt install pgadmin4
sudo apt install pgadmin4-desktop
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
docker ps
psql
clear
docker ps
docker exec -it database /bin/bash
clear
ls -la
cd /home/sulfog/
psql
su postgres
sudo rm /etc/apt/preferences.d/nosnap.pref
sudo apt update
sudo apt install snapd
sudo snap install postbird
Postbird
cd postbird
ls -la
pwd
show postbird
sudo apt install mailutils-mh
pwd
ls -la
cd ..
ls -la
cd ..
pwd
ls -la
cd etc/
ls -la
cd ..
pwd
cd home/sulfog/
git clone git@github.com:Paxa/postbird.git
sudo git clone git@github.com:Paxa/postbird.git
cd postbird/
ls -la
pwd
cd /tmp/
ls
cd sqlnode/
ls -la
yarn
postbird .
cd /snap/bin/
postbird .
ls -la
./postbird
ls -la
sudo su
yarn sequelize db:create
yarn sequelize db create
yarn sequelize db:create
yarn sequelize migration:create --name=create-users
clear
yarn sequelize db:migrate
postbird .
yarn dist
postbird .
vim /etc/profile
export PATH=$PATH:/snap/bin/postbird
postbird .
vim /etc/profile
sudo vim /etc/profile
postbird
reboot
psql
su postgres
adduser sudo sulzam
sudo su
./postbird
psql
su sulzam
yarn dev
rs
yarn dev
ls -la
cd /snap/bin/
./postbird
su sulzam
yarn add nodemon -D
yarn dev
yarn add --dev
clear
yarn dev
yarn install
yarn add --dev.
nodemon src/server.js
nodemon -v
yarn add nodemon
yarn
yarn dev
nodemon src/server.js
yarn add dev
yarn dev
yarn run server.js
yarn run dev
yarn run --dev
yarn dev
yarn run dev
yarn add nodemon
yarn dev
clear
yarn dev
clear
yarn dev
clear
yarn dev
clear
yarn dev
clear
yarn dev
clear
yarn dev
clear
yarn dev
pwd
cd /snap/bin/.postbird
cd /snap/bin/
ls -la
postbird
exit
node -v
npm -v
postbird
pwd
docker ps
psql
su sulzam
cd /home/sulfog/
pwd
sudo ln -s /snap/bin/postbird /usr/bin/postbird
postbird
dpkg -l | grep postgres
sudo apt-get --purge remove postgresql postgresql-doc postgresql-common
sudo apt-get --purge remove postgresql postgresql-10 postgresql-client-10 postgressql-client-common postgresql-common
dpkg -l | grep postgres
sudo apt-get --purge remove postgresql postgresql-10 postgresql-client-10 postgressql-client-common postgresql-common
sudo apt-get --purge remove postgresql postgresql-10 postgresql-client-10 postgresql-client-common postgresql-common
reboot
pwd
ls -la
cd meucontainer/
ls
sudo mkdir PosgreSQL
exit
yarn add nodemon -D
postbird
docker ps
docker images
ls -la
cd deploynode/
ls
ls -la
cd ..
ls -la
cd meucontainer/
ls -la
vim Dockerfile 
sudo vim Dockerfile 
docker pull dpage/pgadmin4
docker pull postgres
docker network create --driver bridge postgres-network
docker network ls
docker run --name sul-postgres --network=postgres-network -e "POSTGRES_PASSWORD=vivo5509" -p 5432:5432 -v /home/sulfog/meucontainer/PostgreSQL:/var/lib/postgresql/data -d postgres
docker ps
docker run --name sul-pgadmin --network=postgres-network -p 15432:80 -e "PGADMIN_DEFAULT_EMAIL=sulzam@gmail.com" -e "PGADMIN_DEFAULT_PASSWORD=PgAdmin5509" -d dpage/pgadmin4
docker ps
cd ..
cd Downloads/
ls -la
chmod +x google-chrome-stable_current_amd64.deb
ls -la
sudo dpkg -i google-chrome-stable_current_amd64.deb
cd ..
cd tmp
pwd
cd \
cd /
pwd
cd tmp/
ls -la
sudo mkdir sqlnode
cd sqlnode/
yarn init -y
yarn add express pg pg-hstore sequelize
yarn
yarn add sequelize-cli -D
yarn sequelize -help
yarn sequelize -h
yarn sequelize --h
ls -la
yarn init -y
sudo yarn init -y
sudo yarn add express pg pg-hstore sequelize
ls -la
code .
sudo su
sudo code .
--sulfog-data-dir=path
--user-data-dir=path
sudo code . --user-data-dir='.'
docker ps
cd cd /home/sulfog/Downloads/
cd /home/sulfog/Downloads/
ls -la
chmod +x Insomnia.Designer-2020.3.3.deb
ls -la
chmod +x Insomnia.Core-2020.3.3.deb
sudo snap install Insomnia.Core-2020.3.3.deb
sudo snap install Insomnia.Core-2020.3.3
sudo snap install Insomnia.Core
sudo snap install Insomnia
sudo dpkg -i Insomnia.Core-2020.3.3.deb
chmod +x Insomnia.Core-2020.3.3.deb
ls -la
sudo dpkg -i Insomnia.Core-2020.3.3.deb
sudo rm Insomia.*
sudo rm Insomnia.Core-2020.3.3.deb
sudo rm Insomnia.Des*.deb
ls -la
yarn snap
ls -la
chmod +x Insomnia.Core-2020.3.3.deb
ls -la
sudo dpkg -i Insomnia.Core-2020.3.3.deb
cd /
pwd
cd opt/
ls -la
cd Insomnia/
ls -la
mkdir chrome-sandbox
sudo mkdir chrome-sandbox
cd /home/sulfog/Downloads/
sudo dpkg -i Insomnia.Core-2020.3.3.deb
Insomnia .
echo  "deb https://dl.bintray.com/getinsomnia/Insomnia /"     | sudo tee -a /etc/apt/sources.list.d/insomnia.list
wget --quiet -O - https://insomnia.rest/keys/debian-public.key.asc     | sudo apt-key add -
sudo apt-get update
sudo apt-get install insônia
sudo apt-get install Insomnia
sudo apt-get install Insomnia.Core-2020.3.3
systemctl restart snapd.service
service snapd status
sudo snap install insônia
ps -ef
ls -la
cd /home/sulfog/
ls -la
cd /tmp/
ls -la
cd sqlnode/
ls -la
inso lint spec
inso executar teste
insomnia
insomia
insomnia .
sudo insomnia .
yarn dev
yarn add nodemon
yarn dev
pgadmin4
clear
yarn sequelize db:create
yarn sequelize migration:create --name=create-users
yarn sequelize db:migrate
yarn sequelize db:migration:undo
yarn sequelize db:migrate:undo
yarn sequelize migrate:create --name=add-age-field-to-users
yarn sequelize migration:create --name=add-age-field-to-users
yarn sequelize db:migrate
yarn sequelize db:migrate:undo
yarn sequelize migration:create --name=create-addresses
yarn sequelize db:migrate

yarn sequelize db:migrate
insomnia .
insomnia
yarn sequelize migration:create --name=create-techs
yarn sequelize migration:create --name=create-user_techs
yarn sequelize db:migrate
insomnia .
Insomnia
insomnia .
pgadmin4
yarn dev
insomnia .
Insomnia .
yarn sequelize db:migrate
yarn
yarn sequelize db:migrete
yarn sequelize db:create
yarn sequelize db:migrate
yarn sequelize db:create
yarn add express pg pg-hstore sequelize
cd ..
cd /
pwd
cd tmp/
ls -la
cd sql*
ls *sql*
ls -la
cd /
ls -la
cd /home/sulfog/
pwd
ls -la
cd /deploynode/
cd deploynode/
ls -la
yarn sequelize db:create
yarn sequelize db:migrate
yarn sequelize db:create
yarn dev
yarn sequelize db:create
yarn sequelize db:migrate
yarn sequelize db:create
yarn sequelize migration:create --name=create-users
yarn sequelize db:migrate
yarn sequelize db:create
nodemon
yarn sequelize dev
rs
yarn init
yarn add express pg pg-hstore sequelize
yarn add sequelize-cli -D
yarn sequelize --help
yarn add nodemon -D
yarn dev
npm start
docker ps
pwd
cd /tmp/
ls -la
cd /home/sulfog/
ls -la
cd /dockerfiles/
clear
pwd
ls -la
cd dockerfiiles/
ls -la
vim Docker-Compose/
rm *.*
sudo rm Docker-Compose/
cd ..
rmdir dockerfiiles/
cd dockerfiiles/
ls -la
sudo rm Docker-Compose/
cd Docker-Compose/
ls -la
cd PostgreSQL/
sudo cd PostgreSQL/
ls -la
cd PostgreSQL/
sudo su
ls -la
cd ..
pwd
cd ..
pwd
ls -la
docker ps
cd sulfog@acer:~/deploynode$ 
pwd
cd deploy
cd deploynode/
yarn 
yarn sequelize db:migrate
docker ps
yarn sequelize db:migrate
yarn sequelize db:create
yarn sequelize db:migrate
cd ..
ls -la
pwd
cd dockerfiles/
ls -la
vim Dockerfile 
docker ps
docker stop dockerfiles_sul-postgres-compose_1
docker rm dockerfiles_sul-postgres-compose_1
docker ps
docker run --name PSQL_bridge -e POSTGRES_PASSWORD=postgres -p 3333:5432 -d postgres
docker ps
docker images
docker run --name PSQL_bridge -e POSTGRES_PASSWORD=postgres -p 15432:5432 -d postgres
docker ps -a
docker network
docker network ls
docker ps -a
docker network myfirststack_postgres-compose-network ip
docker inspect myfirststack_postgres-compose-network | grep IP
docker inspect myfirststack_postgres-compose-network | grep IP address
docker inspect myfirststack_postgres-compose-network | grep ip
docker inspect myfirststack_postgres-compose-network | grep IP
docker inspect myfirststack_postgres-compose-network | grep IP a
docker inspect myfirststack_postgres-compose-network
cd ..
pwd
ls -la
cd deploynode/
ls -la
yarn
yarn sequelize db:create
node -v
node
docker ps
exit
ls -la
cd tmp/
pwd
cd /
ls -la
cd tmp/
ls -la
cd ..
cd home/sulfog/
ls -la
cd deploynode/
ls -la
code .
docker ps
cd /home/sulfog/
docker ps
cd Downloads/
ls -la
cd ..
Insomnia .
ls -la
cd .conf
cd .config
ls -la
cd Insomnia/
ls -la
cd ..
ls -la
cd deploynode/
ls -la
cd ..
ls -la
cd dockerfiles/
ls -la
vim Dockerfile 
touch docker-compose.yml
vim docker-compose.yml 
docker-compose up -d
docker ps
docker network ls
docker ps
docker exec -ti docker_sul-postges /bin/bash
docker exec -ti docker_sul-postges_1 /bin/bash
docker exec -ti dockerfiles_sul-postges_1 /bin/bash
docker exec -ti dockerfiles_sul-postgres_1 /bin/bash
ls -la
docker ps
docker stop cbd705877900
docker rm cbd705877900 -f
docker ps
docker-compose up -d 
vim docker-compose.yml 
docker-compose up -d 
docker ps
docker network ls
vim docker-compose.yml 
docker inspect postgresqlpgadmin4dockercomposenew_postgres-compose-network | grep IP
docker inspect postgresqlpgadmin4dockercomposenew_postgres-compose-network | grep ip
docker ps
docker inspect dockerfiles_sul-postgres-compose_1
docker run --rm -it --name psqlsul governmentpaas/psql sh -c "psql -h 172.23.0.2 -U postgres --password"
docker ps
docker exec -it dockerfiles_sul-postgres-compose_1
docker exec -it dockerfiles_sul-postgres-compose_1 /bin/bash
ls -la
vim docker-compose.yml 
docker service status
service postgresql status
ps -ef
docker ps
docker port be4b42a01823
ls -la
cd /deploynode/
pwd
cd ..
ls -la
cd deploynode/
ls -la
yarn
yarn sequelize db:migrate
cd etc/
cd /etc/
ls -la
vim hosts
cd ..
pwd
cd home/sulfog/deploynode/
ls -la
insomnia .
code .
exit
pwd
sudo mkdir serie-node
cd serie-node/
node -v
npm init -y
clear
sudo npm init -y
sudo su
npm init -y
cd /home/
ls
su sulzam
exit
ls
ls -la
node -v
npm -v
cd /home/sulfog/serie-node/
ls -la
cd Github/
ls -la
cd masterclass-nodejs/
ls -la
vim .gitignore 
exit
cd ..
pwd
cd Downloads/
ls -la
chmod +x node-v12.18.3-linux-x64
ls -la
cd ~
pwd
cd ../ ../
cd ../
pwd
cd ../
pwd
ls -la
cd bin/
ls -la
cd /home/sulfog/Downloads/
ls -la
cd ..
sudo snap install node --classic
npm --version
cd serie-node/
npm init -y
sudo npm init -y
ls -la
sudo mkdir Github
cd Github/
mkdir masterclass-nodejs
sudo mkdir masterclass-nodejs
cd masterclass-nodejs/
git init
gitlogin
git login
git --help
git status
sudo git init
touch .gitignore
sudo touch .gitignore
vim .gitignore
sudo vim .gitignore
git add .
sudo git add .
ls -la
sudo su
exit
pwd
cd serie-node/
npm -v
clear
npm init -y
sudo npm init -y
sudo su
exit
cd etc/
cd /
cd etc/
ls
vim sudoers
sudo su
exit
pwd
node stats.js
node -v
clear
node stats.js
node stats.js 
git add .
git commit -m "end-stats"
nodemon server.js
node
node
npm start
git add.
npm run api
rs
npm run api
ls -la
cd meucontainer/
ls -la
docker ps
cd posgreSQL
cd PosgreSQL/
ls -la
cd ..
cd PostgreSQL/
ls -la
cd PostgreSQL/
sudo su
code .
git clone https://github.com/sulfog/masterclass-nodejs.git
cd ..
git clone https://github.com/sulfog/masterclass-nodejs.git
cd ..
pwd
git clone https://github.com/sulfog/masterclass-nodejs.git
ls -la
cd masterclass-nodejs/
ls -ls
code .
cd ..
ls -la
cd masterclass-nodejs/
ls -la
pwd
cd ..
pwd
ls -la
cd masterclass-nodejs/
ls -la
cd .git/
ls
ls -la
cd ..
ls -la
node -v
node
code .
ls -la
cd ..
rm -ra masterclass-nodejs/
rm --help
ls -la
rm -rf masterclass-nodejs/
ls -la
mkdir Github
cd Github/
git clone https://github.com/sulfog/youtube-masterclass-nodejs.git
ls -la
cd youtube-masterclass-nodejs/
ls -la
code .
node
git add .
git commit -m "end logger"
git push
git commit -m "end logger"
clear
ls -la
cd http/
ls -la
code .
node
node server.js
npm i nodemon -D
git add .
git commit -m "add http"
git log
git add .
git commit -m "add api"
git lg
git log
cd /home/sulfog/
pwd
mkdir introjavascript
cd introjavascript/
code .
pwd
git add .
sudo su
yarn start
nodemon
yard start
yarn start
groups
cd sulfog/
pwd
cd desareact/
ls -la
cd algashopping/
code .
ls -la /Users/lera/.config/yarn/global/node_modules/.yarn*
ls -la /Users/.config/yarn/global/node_modules/.yarn*
ls -la /.config/yarn/global/node_modules/.yarn*
yarn add nodemon
node -v
ls -la
cd src/
ls -la
rm App.test.js 
sudo rm App.test.js -f
ls -la
cd ..
code .
sudo rm App.js serviceworker.js setuTests.js
ls -la
cd src/
ls -la
sudo rm App.js serviceWorker.js setupTests.js 
ls -la
cd ..
code .
yarn start
ls -la
cd public/
ls -la
cd ..
ls -la
netstat -tulnp | grep <port no>
ls -la
sudo rm *.* 
ls -la
sudo rm .*
sudo rm *.
sudo rm .gitignore
ls -la
cd ..
sudo rm algashopping -fr
ls -la
cd ..
pwd
ls -la
sudo rm desareact -fr
ls -la
node -v
yarn -v
yarn create react-app algashopping
ls -la
sudo yarn create react-app algashopping
yarn start
ls -la
cd algashopping/
ls -la
yarn start
code .
ls -la
code .
cd ..
code .
cd algashopping/
yarn start
sudo chown -R sulfog /algashopping/
ls
sudo chown -R sulfog /algashopping
sudo chown -R sulfog ./algashopping
cd algashopping/
code .
git -v
git --version
cd ..
pwd
cd /
cd etc/
ls -la
vim sysctl.conf
sudo vim sysctl.conf
cat /proc/sys/fs/inotify/max_user_watches
sudo sysctl -p
sudo apt-get update
sudo apt-get upgrade
add-apt-repository ppa:git-core/ppa # apt update; apt install git
sudo add-apt-repository ppa:git-core/ppa # apt update; apt install git
cd algashopping/
yarn add styled-components
sudo yarn add styled-components
npm install styled-component
yarn add styled-component
yarn
node --version
yarn add node-10.13.0
styled-component -v
react --version
react -v
yarn add styled-components
sudo apt-get purge nodejs && sudo apt-get autoremove && sudo apt-get autoclean
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.35.3/install.sh | bash
exit
ls -la
code .
yarn start
cd ..
ls -la
cd ..
cd Downloads/
ls -la
cd ..
ls -la
sudo rm algashopping -rf
ls -la
cd Downloads/
ls -la
mv algashopping-live-03 /..
sudo mv algashopping-live-03 ../
cd ..
ls la
ls -la
cd algashopping-live-03/
ls -la
yarn start
sudo yarn start
npm start
code .
cd ..
sudo rena algashopping-live-03 algashopping
sudo rename algashopping-live-03 algashopping
cd algashopping-live-03/
yarn
sudo yarn 
yarn start
exit
cd Downloads/
ls -la
sudo chmod +x algashoppin-live-03.zip
sudo chmod +x algashopping-live-03.zip
ls -la
sudo unzip algashopping-live-03.zip
exit
nvm list
nvm ls-remote
nvm ls-remote | tail -n9
nvm install 14.10.1
nvm use 14.10.1
nvm alias default 14.10.1
node -v
npm install -g npm
yarn global bin
env | grep PATH
npm i -g yarn
yarn global add yarn
npm rm -g yarn
cd algashopping/
yarn add styled-components
exit
cd algashopping/
yarn start
sudo yarn start
exit
