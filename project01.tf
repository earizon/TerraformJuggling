provider "libvirt" {
     uri = "qemu:///system" 
}                        

resource "libvirt_volume" "centos7-qcow2" {
  name = "centos7.qcow2"
  pool = "default"
  format = "qcow2"
  source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
# source = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2"
}

# Adding default user STEP 1 (((
# Our centos qcow2 does not provide any default user/pass to allow logins.
# libvirt_cloudinit_disk resource  is used to "bootstrap" user data to 
# the instance.

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")

}

# Use CloudInit to add the instance 
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data = data.template_file.user_data.rendered
}
# )))

resource "libvirt_domain" "db1" {
  name   = "db1"
  memory = "1024"
  vcpu   = 1

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = libvirt_volume.centos7-qcow2.id
  }
  
  # Adding default user STEP 2 (((
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  # )))

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }
  
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Output Server IP
# output "ip" {
#   value = libvirt_domain.db1.network_interface.0.addresses.0
# }

