 # Common Development Prompts for Install-Arch Project

## PCIe Passthrough Configuration

**Prompt: Configure PCIe GPU Passthrough**
```
Configure PCIe passthrough for GPU {GPU_MODEL} on system with CPU {CPU_MODEL}.
Steps:
1. Verify IOMMU groups: `for d in /sys/kernel/iommu_groups/*/devices/*; do n=${d#*/iommu_groups/*}; n=${n%%/*}; printf 'IOMMU Group %s ' "$n"; lspci -nns "${d##*/}"; done`
2. Identify GPU PCI IDs: `lspci -nn | grep -i {GPU_VENDOR}`
3. Configure VFIO: Add `options vfio-pci ids={PCI_IDS}` to /etc/modprobe.d/vfio.conf
4. Update initramfs: `mkinitcpio -P`
5. Configure libvirt XML with hostdev for PCI device
6. Test passthrough with QEMU command-line first
```

**Prompt: Debug PCIe Passthrough Issues**
```
Debug PCIe passthrough failure for {GPU_MODEL} on {CPU_MODEL} system.
Check:
1. IOMMU enabled in kernel: `dmesg | grep -i iommu`
2. VFIO modules loaded: `lsmod | grep vfio`
3. GPU not bound to host driver: `lspci -nnk | grep {PCI_IDS}`
4. ACS override if needed: `echo 1 > /sys/bus/pci/devices/{DEVICE}/reset`
5. QEMU permissions: Ensure user in kvm/libvirt groups
```

## BTRFS Snapshot Management

**Prompt: Create BTRFS Snapshot**
```
Create BTRFS snapshot for {SUBVOLUME} on {MOUNT_POINT}.
Command: `sudo btrfs subvolume snapshot {SOURCE_PATH} {SNAPSHOT_PATH}/{SNAPSHOT_NAME}`
Example: `sudo btrfs subvolume snapshot / /.snapshots/root-$(date +%Y%m%d)`
List snapshots: `sudo btrfs subvolume list {MOUNT_POINT}`
```

**Prompt: Restore from BTRFS Snapshot**
```
Restore system from BTRFS snapshot {SNAPSHOT_NAME}.
For read-only root systems:
1. Remount root RW: `sudo mount -o remount,rw /`
2. Delete current subvolume: `sudo btrfs subvolume delete {CURRENT_SUBVOLUME}`
3. Create new subvolume from snapshot: `sudo btrfs subvolume snapshot {SNAPSHOT_PATH} {CURRENT_SUBVOLUME}`
4. Remount RO: `sudo mount -o remount,ro /`
```

## Arch Linux Update Management

**Prompt: Safe System Update with Read-Only Root**
```
Update Arch Linux system with read-only root filesystem.
Use system-update script:
1. `sudo system-update`
2. Script handles RW remount automatically
3. Runs `pacman -Syu`
4. Cleans cache optionally
5. Remounts RO automatically

Manual process if needed:
1. `sudo mount -o remount,rw /`
2. `sudo pacman -Syu`
3. `sudo mount -o remount,ro /`
```

**Prompt: Update NVIDIA Drivers**
```
Update NVIDIA drivers on Arch Linux virtualization host.
1. Check current version: `nvidia-smi`
2. Update packages: `sudo pacman -Syu nvidia-dkms nvidia-utils`
3. Rebuild modules: `sudo mkinitcpio -P`
4. Restart persistence daemon: `sudo systemctl restart nvidia-persistenced`
5. Test GPU passthrough compatibility
```

## Hardware Abstraction Prompts

**Prompt: Abstract CPU Configuration**
```
Abstract CPU configuration for {CPU_MODEL} with {CORE_COUNT} cores.
Variables:
- CPU_MODEL: {CPU_MODEL}
- PHYSICAL_CORES: {PHYSICAL_CORES}
- TOTAL_THREADS: {TOTAL_THREADS}
- SUPPORTS_VT: {VT_SUPPORT}
- SUPPORTS_IOMMU: {IOMMU_SUPPORT}

VM Configuration:
- vCPU allocation: min({TOTAL_THREADS} * 0.75, 16)
- CPU pinning: cores 0-{PHYSICAL_CORES-1} for performance
- CPU mode: host-passthrough if VT supported
```

**Prompt: Abstract GPU Configuration**
```
Abstract GPU configuration for {GPU_MODEL} with {VRAM_GB}GB VRAM.
Variables:
- GPU_MODEL: {GPU_MODEL}
- GPU_VENDOR: {GPU_VENDOR}
- PCI_IDS: {PCI_IDS}
- IOMMU_GROUP: {IOMMU_GROUP}
- SUPPORTS_PASSTHROUGH: {PASSTHROUGH_SUPPORT}

VFIO Configuration:
- PCI IDs: {PCI_IDS}
- ACS override: {ACS_NEEDED}
- ROM file: {ROM_FILE_PATH}
- Audio function: {AUDIO_FUNCTION_ID}
```

**Prompt: Hardware Compatibility Check**
```
Check hardware compatibility for {CPU_MODEL} + {GPU_MODEL} combination.
Requirements:
- VT-x/VT-d support: Required for virtualization
- IOMMU groups: Must isolate GPU
- PCIe generation: {PCIE_GEN} compatibility
- Memory: Minimum {MIN_MEMORY_GB}GB
- BIOS settings: VT enabled, IOMMU enabled, CSM disabled

Validation commands:
- CPU flags: `lscpu | grep -E "(vmx|svm)"`
- IOMMU: `dmesg | grep -i iommu`
- PCIe: `lspci -vv | grep -A 10 {GPU_MODEL}`
```

## Virtualization Setup Prompts

**Prompt: Configure libvirt Network Bridge**
```
Configure libvirt network bridge for VM connectivity.
1. Create bridge interface: `sudo nmcli connection add type bridge con-name br0 ifname br0`
2. Add physical interface: `sudo nmcli connection add type ethernet con-name br0-slave ifname {INTERFACE} master br0`
3. Configure bridge: `sudo nmcli connection modify br0 ipv4.method disabled ipv6.method disabled`
4. Create libvirt network: `virsh net-define network.xml`
5. Start network: `virsh net-start br0; virsh net-autostart br0`
```

**Prompt: Create VM with Hardware Abstraction**
```
Create VM configuration for {CPU_MODEL}/{GPU_MODEL} host.
VM Specs:
- Memory: {VM_MEMORY_MB}MB
- vCPUs: {VM_VCPU_COUNT}
- Disk: {VM_DISK_GB}GB qcow2
- Network: Bridge br0
- CPU mode: host-passthrough
- Machine type: q35

Hardware-specific optimizations:
- CPU pinning: {CPU_PINNING_CORES}
- Hugepages: {HUGEPAGES_ENABLED}
- GPU passthrough: {GPU_PASSTHROUGH_ENABLED}
```

## Troubleshooting Prompts

**Prompt: Diagnose Boot Issues**
```
Diagnose Arch Linux boot issues on {CPU_MODEL} system.
Check:
1. Bootloader: `efibootmgr -v`
2. Kernel parameters: `cat /proc/cmdline`
3. Initramfs: `lsinitcpio /boot/initramfs-linux.img`
4. Encryption: `cryptsetup luksDump {DEVICE}`
5. Logs: `journalctl -b`
```

**Prompt: Fix Read-Only Root Issues**
```
Fix read-only root filesystem issues.
Common causes:
1. System update interrupted
2. Disk full: `df -h /`
3. Filesystem errors: `btrfs scrub status /`
4. Manual remount needed: `sudo mount -o remount,rw /`

Recovery:
1. Boot from USB if needed
2. Check filesystem: `sudo btrfs check {DEVICE}`
3. Repair if necessary: `sudo btrfs repair {DEVICE}`
4. Remount RW and complete updates
```

**Prompt: Resolve VFIO Conflicts**
```
Resolve VFIO driver conflicts with {GPU_MODEL}.
Issues:
1. Nouveau loaded: `lsmod | grep nouveau`
2. Host driver bound: `lspci -nnk | grep {PCI_IDS}`

Solutions:
1. Blacklist nouveau: Add to /etc/modprobe.d/blacklist.conf
2. Unbind from host: `echo {PCI_IDS} > /sys/bus/pci/drivers/{DRIVER}/unbind`
3. Bind to VFIO: `echo {PCI_IDS} > /sys/bus/pci/drivers/vfio-pci/bind`
4. Reboot with vfio-pci.ids={PCI_IDS} kernel parameter
```