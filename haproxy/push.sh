export IP=13.77.144.158
scp haproxy/haproxy.cfg root@$IP:/etc/haproxy/haproxy.cfg
ssh root@$IP "/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg && service haproxy restart" 