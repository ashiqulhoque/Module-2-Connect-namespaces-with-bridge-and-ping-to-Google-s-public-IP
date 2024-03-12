sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install net-tools iptables tcpdump iproute2 iputils-ping  -y

sudo ip netns add red
sudo ip netns add green

# Creating veths cables
sudo ip link add veth-red type veth peer name veth-red-br
sudo ip link add veth-green type veth peer name veth-green-br

# Connecting the namespaces with cables
sudo ip link set dev veth-red netns red
sudo ip link set dev veth-green netns green

# Connecting The other end with bridge
sudo ip link set dev veth-red-br master br0
sudo ip link set dev veth-green-br master br0

sudo ip link set veth-red-br up
sudo ip link set veth-green-br up

#for red namespace
sudo ip netns exec red bash
sudo ip link set veth-red up
sudo ip link set lo up

#for green namespace
sudo ip netns exec green bash
sudo ip link set veth-green up
sudo ip link set lo up

# Adding IP to bridge (br0 interface)
sudo ip addr add 192.168.0.1/24 dev br0

# Adding IP to red namespace
sudo ip netns exec red ip addr add 192.168.0.2/24 dev veth-red
#Adding default route
sudo ip netns exec red ip route add default 192.168.0.1

# Adding IP to green namespace
sudo ip netns exec green ip addr add 192.168.0.3/24 dev veth-green
#adding default route
sudo ip netns exec green ip route add default 192.168.0.1

#ping green interface's ip from red interface
sudo ip netns exec red ping 192.168.0.3 -c 3

#ping red interface's ip from green interface
sudo ip netns exec green ping 192.168.0.2 -c 3

#from root namespace
sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT

#add SNAT rule at host side (root namespace)
sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/16  -j MASQUERADE
	
#to verify use this command
sudo iptables -t nat -L -n -v

# In red namespace
sudo ip netns exec red ping 8.8.8.8 -c 3
   
# In green namespace
sudo ip netns exec green ping 8.8.8.8 -c 3
