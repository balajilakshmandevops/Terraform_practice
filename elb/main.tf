# ----------------------------
# CONFIGURE OUR AWS CONNECTION
# ----------------------------

provider "aws" {
  region = "ap-south-1"
}

# --------------------------------------------------------
# GET THE LIST OF AVAILABILITY ZONES IN THE CURRENT REGION
# --------------------------------------------------------

data "aws_availability_zones" "all" {}

# ------------------------------------------------------------------------------
# CREATE A SECURITY GROUP THAT CONTROLS WHAT TRAFFIC AN GO IN AND OUT OF THE ELB
# ------------------------------------------------------------------------------

resource "aws_security_group" "elb" {
  name = "adam-example-elb"

  # Allow all outbound (-1)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO EACH EC2 INSTANCE IN THE ASG
# ------------------------------------------------------------------------

resource "aws_security_group" "instance" {
  name = "adam-example-instance-elb"

  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------
# CREATE AN APPLICATION ELB TO ROUTE TRAFFIC ACROSS THE AUTO SCALING GROUP
# ------------------------------------------------------------------------

resource "aws_elb" "example" {
  name               = "adam-elb-example"
  security_groups    = [aws_security_group.elb.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

# -----------------------------------------------------------------------
# CREATE A LAUNCH CONFIGURATION THAT DEFINES EACH EC2 INSTANCE IN THE ASG
# -----------------------------------------------------------------------

resource "aws_launch_template" "example" {
  name = "adam-example-launchconfig"
  # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type in ap-south-01
  image_id      = "ami-023a307f3d27ea427"
  instance_type = "t2.medium"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo '<html><body><h1 style="font-size:50px;color:blue;">WEZVA TECHNOLOGIES (ADAM) <br> <font style="color:red;"> www.wezva.com <br> <font style="color:green;"> +91-9739110917 </h1> </body></html>' > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
              )
lifecycle {
    create_before_destroy = true
  }
}
