#!/bin/bash

printf "%-22s %-22s %-13s %s\n" "LOCAL" "REMOTE" "STATE" "BINARY(PID)"

awk 'NR>1 {print $2, $3, $4, $10}' /proc/net/tcp | while read local remote state inode; do

  conv() {
    ip_hex=${1%:*}
    port_hex=${1#*:}

    ip=$(printf "%d.%d.%d.%d" \
      $((0x${ip_hex:6:2})) \
      $((0x${ip_hex:4:2})) \
      $((0x${ip_hex:2:2})) \
      $((0x${ip_hex:0:2})))

    port=$((0x$port_hex))
    echo "$ip:$port"
  }

  local_h=$(conv "$local")
  remote_h=$(conv "$remote")

  case "$state" in
    01) s="ESTABLISHED";;
    02) s="SYN_SENT";;
    03) s="SYN_RECV";;
    04) s="FIN_WAIT1";;
    05) s="FIN_WAIT2";;
    06) s="TIME_WAIT";;
    07) s="CLOSE";;
    08) s="CLOSE_WAIT";;
    09) s="LAST_ACK";;
    0A) s="LISTEN";;
    0B) s="CLOSING";;
    *)  s="UNKNOWN";;
  esac

  hit=$(ls -l /proc/[0-9]*/fd/* 2>/dev/null | grep "socket:\[$inode\]" | head -n1)

  if [ -n "$hit" ]; then
    pid=$(echo "$hit" | awk -F'/' '{print $3}')
    bin=$(readlink -f /proc/$pid/exe 2>/dev/null)
    [ -z "$bin" ] && bin="unknown"
  else
    pid="-"
    bin="-"
  fi

  printf "%-22s %-22s %-13s %s(%s)\n" "$local_h" "$remote_h" "$s" "$bin" "$pid"

done
