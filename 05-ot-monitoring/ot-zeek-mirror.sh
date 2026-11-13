#!/bin/bash
VMID="$1"
PHASE="$2"

if [ "$PHASE" = "post-start" ]; then
  sleep 2
  # Clear any stale qdiscs before applying mirror rules
  tc qdisc del dev veth102i0 ingress 2>/dev/null || true
  tc qdisc del dev veth102i0 root 2>/dev/null || true

  # Mirror ingress and egress traffic from OpenPLC (102) to Zeek (104)
  tc qdisc add dev veth102i0 ingress
  tc filter add dev veth102i0 parent ffff: protocol all u32 match u32 0 0 action mirred egress mirror dev veth104i0

  tc qdisc add dev veth102i0 handle 1: root prio
  tc filter add dev veth102i0 parent 1: protocol all u32 match u32 0 0 action mirred egress mirror dev veth104i0
fi
