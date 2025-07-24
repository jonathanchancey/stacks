# thunderbolt

```log
10.131.181.83: kern:    info: [2025-06-17T01:16:05.269765818Z]: thunderbolt 0-1: Intel Corp. sentinel-01
10.131.181.83: kern:    info: [2025-06-17T01:16:14.965300818Z]: thunderbolt 1-1: Intel Corp. sentinel-02

10.131.181.86: kern:    info: [2025-06-17T01:19:48.401054091Z]: thunderbolt 0-1: Intel Corp. sentinel-00
10.131.181.86: kern:    info: [2025-06-17T01:19:58.226870091Z]: thunderbolt 1-1: Intel Corp. sentinel-02

10.131.181.87: kern:    info: [2025-06-17T01:20:30.535634134Z]: thunderbolt 0-1: Intel Corp. sentinel-01
10.131.181.87: kern:    info: [2025-06-17T01:20:37.186197134Z]: thunderbolt 1-1: Intel Corp. sentinel-00

```

```bash
grep thunderbolt /proc/interrupts | cut -d ":" -f1 | xargs -I {} sh -c 'echo 0-7 | tee "/proc/irq/{}/smp_affinity_list"'

apt update
apt install iperf3 pciutils

iperf3 -s -B 169.254.255.100
iperf3 -c 169.254.255.100 -B 169.254.255.101 -R
iperf3 -c 169.254.255.100 -B 169.254.255.102 -R
```