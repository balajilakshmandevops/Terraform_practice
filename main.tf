provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "example" {
    ami = var.ami_id"
    instance_type = "t2.micro"
    tags = {
        Name = "terraform-example"
    }
}

resource "aws_s3_bucket" "example" {
    bucket = "terraform-state-123"
}

variable "ami_id" {
    type = string
    default = "ami-0c55b159cbfafe1f0"
}

backend "s3" {
    bucket = "terraform-state-123"
    key = "terraform.tfstate"
    region = "ap-south-1"
}