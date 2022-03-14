data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

data "http" "ip" {
  url = "https://ifconfig.me"
}



resource "aws_network_interface" "this" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.this.id]

  tags = local.tags
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon-2.id
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }

  key_name = var.key_name
  tags     = local.tags

  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>${var.vm_name}</h1>" | sudo tee /var/www/html/index.html
EOF

}


resource "aws_eip" "this" {
  vpc = true

  instance = aws_instance.this.id
  tags     = local.tags
}


resource "aws_security_group" "this" {
  name        = "${var.vm_name} allow inbound to test instance"
  description = "${var.vm_name} allow inbound to test instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.ip.body}/32"]
  }

  ingress {
    description = "ICMP10"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "ICMP172"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["172.16.0.0/12"]
  }

  ingress {
    description = "ICMP192"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["192.168.0.0/16"]
  }



  ingress {
    description = "TCP80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}


output "instance_id" {
  value = aws_instance.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}