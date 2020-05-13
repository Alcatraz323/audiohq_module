MODDIR=${0%/*}

mkdir -p /data/misc/audiohq

#setenforce 0

audiohq --service --force

(
  killall audioserver 2>/dev/null
)&
