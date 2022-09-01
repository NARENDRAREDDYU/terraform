# Terraform Block
terraform {
    required_version = "~> 1.2"
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.28"
       }
    }
}

# Provider Block 

provider "aws" {
    region = var.region
    profile = "default"
}

# Resource Block

resource "aws_instance" "ec2_instnce" {
    ami = data.aws_ami.amzlinux.id
    instance_type = var.aws_instance
    key_name = var.key_name
    user_data = file ("${path.module}/app1-install.sh")
    vpc_security_group_ids = [aws_security_group.vpc-ssh.id , aws_security_group.vpc-web.id]
    tags = {
      "Name" = "ec2_instnace"
    }
}


# Resource Secuirty Groups for SSH and WEB

resource "aws_security_group" "vpc-ssh" {
    name = "vpc-ssh"
    description = "EC2_Instnace Security group"
    ingress {
        description = "allow port 22"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]   
    }
    egress {
        description = " allow all traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } 
tags = {
"Name" = "vpc-ssh"
}  
}

# Resource Group for security group

resource "aws_security_group" "vpc-web" {
    name = "vpc-web"
    description = "EC2_Instance Web"
    ingress {
        description = "allow port 80"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "allow all traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } 


tags ={
    "Name" = "vpc-web"
}

}


# Input variable Block

variable "aws_instance" {
    description = "aws instance type"
    type = string
    default = "t2.micro"
}
variable "key_name" {
    description = "Secret key Name"
    type = string
    default = "udemalla"
}
variable "region" {
    description = "Region"
    type = string
    default = "us-east-1"
}


# output Block

output "public_ip" {
    description = "display the public_ip"
    value = aws_instance.ec2_instnce.public_ip
  
}

 output "public_dns" {
    description = "display the public_dns"
    value = aws_instance.ec2_instnce.public_dns
   
 }


 # datasource Block

 data "aws_ami" "amzlinux" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["amzn2-ami-kernel-5.10-hvm-*-gp2"]
    
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    filter {
      name = "architecture"
      values = ["x86_64"]
    }
    filter {
        name = "root-device-type"
        values = ["ebs"]
    }

 }