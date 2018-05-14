variable "access_key" {}
variable "secret_key" {}

provider "aws" {
	access_key = "${var.access_key}"
  	secret_key = "${var.secret_key}"
  	region     = "us-east-1"
}

data "aws_ami" "node_app_ami" {
	most_recent = true


	filter {
		name = "packer-example*"
		values = ["Manas_integration_example*"]
	}

	filter {
		name = "Hyperv type "
		values = ["hvm"]
	}

	owners = ["185931747856"]
}


resource "aws_launch_configuration" "node_app_lc" {
	name_prefix   = "terraform-lc-example-node-app"
	image_id = "${data.aws_ami.node_app_ami.id}"
	instance_type = "t2.micro"
	security_groups = ["$aws_security_group.node_app_websg.id}"]

	lifecycle {

		create_before_destroy = true
	}

}


resource "aws_autoscaling_group" "node_app_asg" {
	name = "terraform-asg-node-${aws_launch_configuration.node_app_lc.name}"
	launch_configuration = "${aws_launch_configuration.node_app_lc.name}"
	availability_zones = ["${data.aws_availability_zones.allzones.name}"]
	min_size = 1
	max_size = 2

	load_balancers = ["${aws_elb.elb1.id}"]
	health_check_type = "ELB"



	lifecycle{
		create_before_destroy = true
	
	}

}



resource "aws_security_group" "node_app_websg" {

	name = "security-group-for-node-app-websg"
	ingress {

		from_port = 3000
		to_port	= 3000
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	lifecycle {

		create_before_destroy = true
	}
}



resource "aws_security_group" "elbsg" {

	name = "Manas-example-elb-sg"
	ingress {

		from_port = 3000
		to_port = 3000
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {

		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	lifecycle {

		create_before_destroy = true

	}
}


data "aws_availability_zones" "allzones" {}

resource "aws_elb" "elb1" {
	name = "node-app-manas-node-appelb"
	availability_zones = ["${data.aws_availability_zones.allzones.name}"]
	security_groups = ["${aws_security_group.elbsg.id}"]



	listener {
		instance_port = 3000
		instance_protocol = "http"
		lb_port = 3000
		lb_protocol = "http"
	}

	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		target = "HTTP:3000/"
		interval = 30
	}


	cross_zone_load_balancing = true
	idle_timeout = 400
	connection_draining = true
	connection_draining_timeout = 400

	tags {
		name = "terraform-elb-nodeapp"
	}

}













