
locals {
  proj_name = "dev"
   ingress_rules= [
    {
      port= 22,
      description ="SSH" },
    {
      port= 80,
      description ="HTTP"
    }
  ]
}

resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = local.proj_name
  }
}

resource "aws_subnet" "mtc_public_subnet" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "${local.proj_name}_publuc"
  }
}

resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id
  tags = {
    Name = "${local.proj_name}_igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id
  tags = {
    Name = "${local.proj_name}_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id
}

resource "aws_route_table_association" "mtc_public_assoc" {
  subnet_id      = aws_subnet.mtc_public_subnet.id
  route_table_id = aws_route_table.mtc_public_rt.id
}

resource "aws_security_group" "mtc_sg" {
  name        = "${local.proj_name}_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.mtc_vpc.id
  
  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
    } 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtc_key"
  public_key = file("~/.ssh/mtckey.pub")
}

resource "aws_instance" "dev_node" {
  ami           = data.aws_ami.server_ami.id
  instance_type = "t3.micro"
  key_name               = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_public_subnet.id
  user_data =file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }
  tags = {
    Name = "dev_node"
  }
}

resource "aws_instance" "my_server" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  user_data =file("userdata.tpl")

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${self.private_ip} >> /home/ec2-user/private_ips.txt"
    ]
  }

  provisioner "file" {
    content     = "ami used : ${self.ami}"
    destination = "/home/ec2-user/barsoon.txt"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/terraform")
    host        = self.public_ip
  }

  tags = {
    Name = "${local.proj_name}_Server"
  }
}

resource "null_resource" "status" {
    provisioner "local-exec"{
        command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.my-server.id} "
    }
    depends_on =[aws_instance.my-server]
  }

  resource "aws_s3_bucket" "bucket" {
  bucket = "roya-tf-test-bucket"
  depends_on = [
    aws_instance.my_server
  ]

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }

}
