packer {
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "vm_name" {
  type    = string
  default = "arch-kde"
}

variable "vm_cpus" {
  type    = number
  default = 4
}

variable "vm_memory" {
  type    = number
  default = 4096
}

variable "vm_disk_size" {
  type    = string
  default = "20G"
}

variable "desktop_env" {
  type    = string
  default = "kde"
  validation {
    condition     = contains(["kde", "gnome", "xfce", "i3"], var.desktop_env)
    error_message = "Desktop environment must be kde, gnome, xfce, or i3."
  }
}

variable "access_method" {
  type    = string
  default = "spice"
  validation {
    condition     = contains(["spice", "ssh", "console"], var.access_method)
    error_message = "Access method must be spice, ssh, or console."
  }
}

source "qemu" "arch" {
  iso_url           = "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
  iso_checksum      = "file:https://mirror.rackspace.com/archlinux/iso/latest/sha256sums.txt"
  output_directory  = "output"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  disk_size         = var.vm_disk_size
  format            = "qcow2"
  accelerator       = "kvm"
  headless          = true
  memory            = var.vm_memory
  cpus              = var.vm_cpus
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "5s"
  boot_command      = [
    "<enter><wait10><wait10><wait10><wait10>",
    "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh<enter><wait5>",
    "chmod +x install.sh<enter><wait2>",
    "./install.sh<enter>"
  ]
  http_directory    = "http"
  ssh_username      = "packer"
  ssh_password      = "packer"
  ssh_timeout       = "20m"
}

build {
  sources = ["source.qemu.arch"]

  provisioner "file" {
    source      = "configs/"
    destination = "/tmp/configs"
  }

  provisioner "shell" {
    script = "scripts/setup-arch.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo pacman -Syu --noconfirm",
      "sudo pacman -S --noconfirm qemu-guest-agent spice-vdagent openssh",
      "sudo systemctl enable qemu-guest-agent",
      "sudo systemctl enable sshd"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}</content>
<parameter name="filePath">/home/spooky/Documents/projects/install-arch/vm-images/packer/arch/arch.pkr.hcl