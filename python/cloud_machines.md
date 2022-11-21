# Provisioning the cloud machines

This is by far not the only possible setup, but it is a possible way to
get a working cloud setup to run the tests. No automation is involved here
at the moment: it is just a bunch of commands to run on the instances,
aimed at having Python and all other tools installed and available.

## AWS

It is assumed the following AMI has been used to create the machine:
`Amazon Linux 2 Kernel 5.10 AMI 2.0.20220912.1 x86_64 HVM gp2`.

### General setup

The following and installs: git, Vegeta, docker/docker-compose and jq; and clones this repo:
([partial inspiration](https://www.cyberciti.biz/faq/how-to-install-docker-on-amazon-linux-2/))

```
sudo yum update -y

sudo yum install git -y
git clone https://github.com/feast-dev/feast-benchmarks.git

mkdir bin
curl -L -O https://github.com/tsenart/vegeta/releases/download/v12.8.4/vegeta_12.8.4_linux_386.tar.gz
mv vegeta_12.8.4_linux_386.tar.gz bin
tar -xvf bin/vegeta_12.8.4_linux_386.tar.gz -C bin

sudo yum install docker -y
sudo usermod -a -G docker ec2-user
id ec2-user
newgrp docker

wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod -v +x /usr/local/bin/docker-compose

sudo systemctl enable docker.service
sudo systemctl start docker.service

sudo yum install jq -y
```

### Python

The following enables and installs (in a virtualenv) Python 3.8, required by modern Feast,
since the machine by defaults ships with 3.7 only; and installs Feast and parquet-tools.

```
sudo yum install -y amazon-linux-extras
sudo amazon-linux-extras enable python3.8
sudo yum install python3.8 -y

pip3 install virtualenv
virtualenv -p /usr/bin/python3.8 feast38
. feast38/bin/activate

pip install "feast[redis,aws,cassandra]==0.26"
pip install parquet-tools
```

### AWS credentials

You probably want to copy your `~/.aws` folder over to the machine:

```
rsync -ravstp -e 'ssh -i keypair-used-for-aws.pem' $HOME/.aws ec2-user@$TARGET_IP:/home/ec2-user/
```

## GCP

It is assumed the machine has been created with the `Debian 10 marketplace image`.

You can use the GCP "Web console" to log on to the machine and inject your
ssh key to the `~/.ssh/authorized_keys` file on it.
Beware: there is a daemon script that periodically resets the file, so that
new connections might not work. Quick and dirty way: repeat this Web-console-based
injection. Proper way: see [here](https://cloud.google.com/compute/docs/instances/access-overview)
on how to use the machine metadata and have the daemon
provide your key to the authorized hosts.

For the following you should be logged on to the machine.

### General setup

The following and installs: git, Vegeta, docker/docker-compose, jq and rsync; and clones this repo:
([partial inspiration](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-debian-10))

```
sudo apt update
sudo apt install git -y

git clone https://github.com/feast-dev/feast-benchmarks.git

mkdir bin
curl -L -O https://github.com/tsenart/vegeta/releases/download/v12.8.4/vegeta_12.8.4_linux_386.tar.gz
mv vegeta_12.8.4_linux_386.tar.gz bin
tar -xvf bin/vegeta_12.8.4_linux_386.tar.gz -C bin
export PATH="$PATH:$HOME/bin"

sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo usermod -a -G docker `whoami`
id `whoami`
newgrp docker

sudo apt install wget -y
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod -v +x /usr/local/bin/docker-compose

sudo systemctl enable docker.service
sudo systemctl start docker.service

sudo apt install jq -y
sudo apt install rsync -y
```

### Python

Python 3.8 must be built from source `¯\_(ツ)_/¯`:

```
sudo apt update
sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev -y
curl -O https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tar.xz
tar -xf Python-3.8.2.tar.xz
cd Python-3.8.2
./configure --enable-optimizations
make -j 4
sudo make altinstall

sudo apt install python3-pip -y

pip3 install virtualenv
python3.7 -m virtualenv -p /usr/local/bin/python3.8 feast38
. feast38/bin/activate

pip install "feast[gcp]>=0.25"
pip install parquet-tools
```

### GCP credentials

Assuming your local computer is set up for GCP access and
your credentials are stored in the directory below:

```
rsync -ravstp $HOME/.config/gcloud USERNAME@TARGET_IP:/home/USERNAME/.config
```
