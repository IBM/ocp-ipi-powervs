locals {
    date = formatdate("YYYY-MM-DD-hh-mm", timestamp())
}

resource "null_resource" "service_accounts" {
  triggers = {
    account_name   = "${var.cluster_name}-${local.date}"
    api_key        = "${var.api_key}"
    cluster_dir     = "${var.cluster_dir}"
    cluster_name   = "${var.cluster_name}"
    requests_dir   = "${var.cluster_dir}/credreqs"
    release_image  = "quay.io/openshift-release-dev/ocp-release:${var.openshift_release}-multi"
    resource_group = "${var.resource_group}"
    ssh_identity   = "${var.ssh_identity}"
    ssh_host       = "${var.ssh_host}"
    ssh_user       = "${var.ssh_user}"
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
      "${self.triggers.cluster_dir}/bin/oc adm release extract --cloud=powervs --credentials-requests ${self.triggers.release_image} --to=${self.triggers.requests_dir}",
      "IBMCLOUD_API_KEY=${self.triggers.api_key} ${self.triggers.cluster_dir}/bin/ccoctl ibmcloud create-service-id --credentials-requests-dir ${self.triggers.requests_dir} --name ${self.triggers.account_name} --output-dir ${self.triggers.cluster_dir} --resource-group-name ${self.triggers.resource_group}",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "IBMCLOUD_API_KEY=${self.triggers.api_key} ${self.triggers.cluster_dir}/bin/ccoctl ibmcloud delete-service-id --credentials-requests-dir ${self.triggers.requests_dir} --name ${self.triggers.account_name}",
    ]
  }
}
