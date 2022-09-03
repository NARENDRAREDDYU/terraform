  # Terraform Block
terraform {
  required_version = "~> 1.2"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.2"
     }
  }
}

# Provider Block

provider "aws" {
    region = var.aws_region
    profile = "default"
  
}

# resource Block
resource "aws_instance" "myec2vm" {
  
    ami = data.aws_ami.amzlinux.id
    instance_type = var.instance_type_list[0]
    # instance_type = var.instance_type_list[1]
    # instance_type = var.instance_type_map["qa"]
   key_name = var.key_name
   vpc_security_group_ids = [ aws_security_group.vpc-ssh.id , aws_security_group.vpc-web.id ]
   user_data = file("${path.module}/app1-install.sh")
   #for_each = toset(["us-east-1a", "us-east-1b" , "us-east-1c" , "us-east-1d", "us-east-1e"])
   #for_each = tomap {"az1"="us-east-1a" , "az2"="us-east-1b" , "az3"="us-east-1c","az4"="us-east-1d","az5"="us-east-1e"}
    for_each = toset(keys({for az, details in data.aws_ec2_instance_type_offerings.my_inst_types:  az => details.instance_types 
    if length(details.instance_types) != 0})) 
    availability_zone = each.key
   #count = 2
   tags = {
     Name = "MyEC2Instane-${each.key}"
   }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}
#
resource "aws_security_group" "vpc-ssh" {
    name = "vpc-ssh"
    description = "EC2 Security Groups"
    vpc_id = aws_default_vpc.default.id
    

    ingress {
        description = "allow port 22"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow all traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }  
    tags = {
      Name = "vpc-ssh"
    }
}
resource "aws_security_group" "vpc-web" {
    name = "vpc-web"
    description = "EC2 Instance Web "
    vpc_id = aws_default_vpc.default.id
    ingress {
        description = "allow port 80"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        description = "allow port 443"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    egress {
        description = "allow all traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
      Name = "vpc-web"
    }
}



# Input Variables
/*
variable "instance_type" {
    description = "aws_ami_instance_type"
    # vaiables with list
    default = toset(["t2.micro", "t2.small", "t2.medium"])     
    
    # variables with map
    default = {"dev"= "t2.small" , "qa"="t2.small", "prod"= "t2.medium"}
    


    
    type = string
  
}

*/
variable "instance_type_map" {
    #variable with maps
    type = map(string)
    default = {
      "prod" = "t2.medium"
      "dev"  = "t2.small"
      "qa" = "t2.micro"
    }
}


variable "instance_type_list" {
    #variable with lists
     type = list(string)
    default = ["t3.micro" , "t2.small" , "t2.medium"]
}
 



variable "key_name" {
    description = "Keypair for us-east-1"
    type = string
    default = "udemalla"
}

variable "aws_region" {
    description = "aws_region"
    type = string
    default = "us-east-1"
}


# datasource for ec2 instance ami

data "aws_ami" "amzlinux" {
      most_recent = true
      owners = [ "amazon" ]

    filter {
      name = "name"
      values = [ "amzn2-ami-kernel-5.10-hvm-*-gp2" ]
    }
    filter {
      name = "architecture"
      values = [ "x86_64" ]

    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
    filter {
        name = "root-device-type"
        values = [ "ebs" ]
    }
}

data "aws_availability_zones" "my_azones" {
    
    filter {
      name = "opt-in-status"
      values = [ "opt-in-not-required" ]
    }
}

data "aws_ec2_instance_type_offerings" "my_inst_types" {
    for_each = toset(data.aws_availability_zones.my_azones.names)
    
    filter {
      name = "instance-type"
      values = [ "t3.micro" ]
    }  
    filter {
      name = "location"
      values = [ each.key ]
    }
    location_type = "availability-zone"
}
# 
#output Block 

output "public_ip" {
    value = toset([for instance in aws_instance.myec2vm: instance.public_ip])
}



#Output Block for map

output "public_dns_1" {
    value = {for instance, details in aws_instance.myec2vm: instance => details.public_dns}
}
# Output Block 

output "Public_dns_1" {
    value = tomap({for s, myec2vm in aws_instance.myec2vm: s => myec2vm.public_dns })
}


/* # Output
output "output_v1_1" {
  value = data.aws_ec2_instance_type_offerings.my_ins_type1.instance_types
}

#Output-1
# Important Note: Once for_each is set, its attributes must be accessed on specific instances
output "output_v2_1" {
  #value = data.aws_ec2_instance_type_offerings.my_ins_type1.instance_types
  value = toset([for t in data.aws_ec2_instance_type_offerings.my_ins_type2: t.instance_types])
}

#Output-2
# Create a Map with Key as Availability Zone and value as Instance Type supported
output "output_v2_2" {
  value = {
    for az, details in data.aws_ec2_instance_type_offerings.my_ins_type2: az => details.instance_types
  }
}

# Output-1
# Basic Output: All Availability Zones mapped to Supported Instance Types
output "output_v3_1" {
  value = {
    for az, details in data.aws_ec2_instance_type_offerings.my_ins_type: az => details.instance_types
  }
}

# Output-2
# Filtered Output: Exclude Unsupported Availability Zones
output "output_v3_2" {
  value = {
    for az, details in data.aws_ec2_instance_type_offerings.my_ins_type: 
    az => details.instance_types if length(details.instance_types) != 0 }
}

# Output-3
# Filtered Output: with Keys Function - Which gets keys from a Map
# This will return the list of availability zones supported for a instance type
output "output_v3_3" {
  value = keys({
    for az, details in data.aws_ec2_instance_type_offerings.my_ins_type: 
    az => details.instance_types if length(details.instance_types) != 0 })
}


# Output-4 (additional learning)
# Filtered Output: As the output is list now, get the first item from list (just for learning)
output "output_v3_4" {
  value = keys({
    for az, details in data.aws_ec2_instance_type_offerings.my_ins_type: 
    az => details.instance_types if length(details.instance_types) != 0 })[0]
}   */
/*
value = keys({for az, details in data.aws_ec2_instance_type_offerings.my_ins_type: az => details.instance_types 
if length(deatails.instance_types) != 0}) [0]

value = keys ({for az , details in data.aws_ece_instance_type_offerings.my_ins_type: az => detais.instance_types if
 length(details.instnace_types) != 0})
*/















