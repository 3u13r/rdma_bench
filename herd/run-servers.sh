# A function to echo in blue color
function blue() {
	es=`tput setaf 4`
	ee=`tput sgr0`
	echo "${es}$1${ee}"
}

export HRD_REGISTRY_IP="10.1.1.3"
export MLX5_SINGLE_THREADED=1
export MLX4_SINGLE_THREADED=1


bash -c "echo kernel.shmmax = 9223372036854775807 >> /etc/sysctl.conf"
bash -c "echo kernel.shmall = 1152921504606846720 >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

blue "Removing SHM key 24 (request region hugepages)"
ipcrm -M 24

blue "Removing SHM keys used by MICA"
for i in `seq 0 28`; do
	key=`expr 3185 + $i`
	ipcrm -M $key 2>/dev/null
	key=`expr 4185 + $i`
	ipcrm -M $key 2>/dev/null
done

blue "Reset server QP registry"
pkill memcached
memcached -l 0.0.0.0 1>/dev/null 2>/dev/null &
sleep 1

blue "Starting master process"
LD_LIBRARY_PATH=/usr/local/lib/ \
	numactl --cpunodebind=0 --membind=0 ./main \
	--master 1 \
	--base-port-index 0 \
	--num-server-ports 2 &

# Give the master process time to create and register per-port request regions
sleep 1

blue "Starting worker threads"
LD_LIBRARY_PATH=/usr/local/lib/ \
	numactl --cpunodebind=0 --membind=0 ./main \
	--is-client 0 \
	--base-port-index 0 \
	--num-server-ports 2 \
	--postlist 32 &
