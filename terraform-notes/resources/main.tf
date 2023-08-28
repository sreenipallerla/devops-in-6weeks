terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
  
}

provider "aws" {

    region = "us-east-1"
  
}

#create VPC

resource "aws_vpc" "sreeni-test-vpc" {
    cidr_block = "10.0.0.0/16"
  


#tags

tags= {
    Name="sreeni-test-vpc"
}

}


#public subnet

resource "aws_subnet" "nearo-ps-1" {
    vpc_id = aws_vpc.sreeni-test-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      name = "nearo-ps-1"
    }
  
}

# private subnet

resource "aws_subnet" "nearo-pvts-1" {
    vpc_id = aws_vpc.sreeni-test-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1a"

    tags = {
      name = "nearo-pvts-1"
    }
  
}


#internet gateway

resource "aws_internet_gateway" "nearo-igway" {
    vpc_id = aws_vpc.sreeni-test-vpc.id
    tags= {
        Name="nearo-igway"
    }
  
}

#route table association

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.sreeni-test-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.nearo-igway.id
    }


    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.nearo-igway.id
    }

    tags = {
      Name="public Route table"
    }
  
}


resource "aws_route_table_association" "public_1_rt_a" {
    subnet_id = aws_subnet.nearo-ps-1.id
    route_table_id = aws_route_table.public_rt.id
  
}


resource "aws_security_group" "web_sg" {

    name="http and SSH"
    vpc_id = aws_vpc.sreeni-test-vpc.id 

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1 
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}


resource "aws_instance" "web_instance" {
    ami= "ami-051f7e7f6c2f40dc1"
    instance_type = "t2.micro"
    key_name = "MyKeyPair"
  
    subnet_id = aws_subnet.nearo-ps-1.id
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    associate_public_ip_address = true

    user_data = <<-EOF
    #!/bin/bash -ex

    amazon-linux-extras install nginx1 -y
    echo "<h1>$(curl https://api.kanye.rest/?format=text)</h1>" > /usr/share/nginx/html/index.html
    systemctl enable nginx
    systemctl start nginx
    EOF

    tags = {
        "name"="Sreeni"
    }

}