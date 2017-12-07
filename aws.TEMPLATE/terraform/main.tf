# These variables are meant to be supplied from config files

variable "username"            {} 
variable "remote_user"         {}
variable "bucket"              {} 

variable "profile"             {} 
variable "key_name"            {}
variable "key_path"            {}
variable "s3_access_role_name" {}
variable "user_cidr_block"     {}

variable "instance_type"       {} 
variable "ami"                 {}
variable "zone"                {} 
variable "launch_region"       {}
variable "local_storage_size"  {}
variable "instance_count"      {}
variable "spot_price"          {}
variable "extra_volume_size"   {}


# --- Misc setup variables for each machine ---

variable "extra_volume_dir" {
  default = "data"
}

variable "tmp_project_dir" {
  default = "./.tmp-terraform-rsync-dir"
}


# NOTE: you may want to change `project_name`
# NOTE: conda is kinda hardcoded here.
# NOTE: this will fail with miniconda.

locals {
  remote_home  = "/home/${var.remote_user}"
  project_name = "${basename( "${dirname( "${dirname( "${path.module}" )}" )}" )}"
  project_path = "${local.remote_home}/${local.project_name}"
  conda_bin    = "${local.remote_home}/anaconda3/bin"
}


# ---  General aws setup ---

provider "aws" {
    profile = "${var.profile}"
    region  = "${var.launch_region}"
}


# ---  Setup access rules ---

resource "aws_security_group" "manager_ssh" {
  # names
  name        = "custom_ssh"
  description = "Enable SSH access from my ip"

  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.user_cidr_block}"]
  }

  # 5 jupyter kernels
  ingress {
    from_port   = 8888
    to_port     = 8893
    protocol    = "tcp"
    cidr_blocks = ["${var.user_cidr_block}"]
  }

  # traffic outside of aws
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---  Setup access to s3 that is passed to instances without copying credentials ---

data "aws_iam_role" "s3_role" {
  name = "${var.s3_access_role_name}"
}

resource "aws_iam_instance_profile" "s3_profile" {
  name  = "s3_profile"
  role = "${data.aws_iam_role.s3_role.name}"
}

# --- Build the spot request ---

resource "aws_spot_instance_request" "manager_worker" {
  ami               = "${var.ami}"
  spot_price        = "${var.spot_price}"
  availability_zone = "${var.zone}"
  instance_type     = "${var.instance_type}"
  count             = "${var.instance_count}"
  key_name          = "${var.key_name}"
  
  spot_type            = "one-time"
  wait_for_fulfillment = true

  iam_instance_profile = "${aws_iam_instance_profile.s3_profile.id}"

  tags {
    Name = "Terraform-BNB-AutoTag"
  }

  vpc_security_group_ids = [
      "${aws_security_group.manager_ssh.id}"
  ]

  connection {
    user = "${var.remote_user}"
    private_key = "${file("${var.key_path}")}"
  }
  
  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.local_storage_size}"
    delete_on_termination = true
  }

  ebs_block_device {
    volume_type = "gp2"
    device_name = "/dev/sdb"
    volume_size = "${var.extra_volume_size}"
    delete_on_termination = true    
  }

  # copy the source to tempdir ignoring the same paths as specified in .gitignore
  provisioner "local-exec" {
    command = "rsync -r ../.. ${var.tmp_project_dir}-${self.id} --filter=':- ../../.gitignore'"
  }

  # copy the 'cleaned' source to remote machine
  provisioner "file" {
    source      = "${var.tmp_project_dir}-${self.id}"
    destination = "${local.project_path}"
  }

  # get rid of local copy
  provisioner "local-exec" {
    command = "rm -rf ${var.tmp_project_dir}-${self.id}"
  }

  # additional, project-specific python setup on the remote machine
  # NOTE: note the conda-list.txt
  # NOTE: these commands will never fail due to `|| true`
  provisioner "remote-exec" {
    inline = [
      "cd ${local.project_path}",
      "${local.conda_bin}/conda install -y --file conda-list.txt || true",
      "${local.conda_bin}/pip install -r requirements.txt || true",
    ]
  }

  # Setup additional storage
  provisioner "remote-exec" {
    inline = [
      "cd ${local.remote_home}",
      "sudo mkfs -t ext4 /dev/xvdb",
      "sudo mkdir ${var.extra_volume_dir}",
      "sudo mount /dev/xvdb ${var.extra_volume_dir}",
      "sudo chmod 775 ${var.extra_volume_dir}",
      "sudo chown ${var.remote_user} ${var.extra_volume_dir}"
      ]
  }
}


# --- Write IPs of created instances to a json file ---

resource "local_file" "created_ips" {
    content     = "${jsonencode( "${aws_spot_instance_request.manager_worker.*.public_ip}" )}"
    filename = "${path.module}/instance_ips.json"
}


# --- Output variables ---

output "public_ips" {
  value = ["${aws_spot_instance_request.manager_worker.*.public_ip}"]
}
