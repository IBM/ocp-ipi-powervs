locals {
    date = formatdate("YYYY-MM-DD-hh-mm", timestamp())
}

resource "null_resource" "cluster" {
  triggers = {
    api_key      = "${var.api_key}"
    cluster_dir  = "${var.cluster_dir}"
    ssh_identity = "${var.ssh_identity}"
    ssh_host     = "${var.ssh_host}"
    ssh_user     = "${var.ssh_user}"
  }

  connection {
    agent           = "true"
    agent_identity  = "${self.triggers.ssh_identity}"
    type            = "ssh"
    user            = "${self.triggers.ssh_user}"
    host            = "${self.triggers.ssh_host}"
  }

  provisioner "remote-exec" {
    inline = [
      "IBMCLOUD_API_KEY=${self.triggers.api_key} ${self.triggers.cluster_dir}/bin/openshift-install create cluster --dir=${self.triggers.cluster_dir} --log-level=debug",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "IBMCLOUD_API_KEY=${self.triggers.api_key} ${self.triggers.cluster_dir}/bin/openshift-install destroy cluster --dir=${self.triggers.cluster_dir} --log-level=debug",
    ]
  }
}
