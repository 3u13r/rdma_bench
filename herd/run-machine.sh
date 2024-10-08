# A function to echo in blue color
function blue() {
	es=`tput setaf 4`
	ee=`tput sgr0`
	echo "${es}$1${ee}"
}

export HRD_REGISTRY_IP="10.1.1.3"
export MLX5_SINGLE_THREADED=1
export MLX4_SINGLE_THREADED=1

if [ "$#" -ne 1 ]; then
    blue "Illegal number of parameters"
	blue "Usage: ./run-machine.sh <machine_number>"
	exit
fi

bash -c "echo kernel.shmmax = 9223372036854775807 >> /etc/sysctl.conf"
bash -c "echo kernel.shmall = 1152921504606846720 >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

blue "Removing hugepages"
shm-rm.sh 1>/dev/null 2>/dev/null

num_threads=14		# Threads per client machine

blue "Running $num_threads client threads"

LD_LIBRARY_PATH=/usr/local/lib/ \
	numactl --cpunodebind=0 --membind=0 ./main \
	--num-threads $num_threads \
	--base-port-index 0 \
	--num-server-ports 2 \
	--num-client-ports 2 \
	--is-client 1 \
	--update-percentage 0 \
	--machine-id $1 &
