
variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "web_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "db_sg_id" {
  type = string
}

variable "web_target_group_arn" {
  type = string
}

variable "app_target_group_arn" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Web Tier - 2 EC2 instances
resource "aws_instance" "web" {
  count                       = 2
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_ids[count.index]
  vpc_security_group_ids      = [var.web_sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    echo "<h1>Web Tier - Server ${count.index + 1}</h1>" > /var/www/html/index.html
    systemctl start httpd
  EOF

  tags = {
    Name = "web-server-${count.index + 1}"
    Tier = "Web"
  }
}

# Register Web EC2 instances with Public ALB
resource "aws_lb_target_group_attachment" "web" {
  count            = 2
  target_group_arn = var.web_target_group_arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# App Tier - 2 EC2 instances
resource "aws_instance" "app" {
  count                  = 2
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [var.app_sg_id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    echo "<h1>Application Tier - Server ${count.index + 1}</h1>" > /var/www/html/index.html
    systemctl start httpd
  EOF

  tags = {
    Name = "app-server-${count.index + 1}"
    Tier = "App"
  }
}

# Register App EC2 instances with Private ALB
resource "aws_lb_target_group_attachment" "app" {
  count            = 2
  target_group_arn = var.app_target_group_arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

# Database Tier - 1 EC2 instance
resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.db_sg_id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y mariadb105-server
    systemctl enable mariadb
    systemctl start mariadb
  EOF

  tags = {
    Name = "database-server"
    Tier = "Database"
  }
}

output "web_instance_ids" {
  value = aws_instance.web[*].id
}

output "app_instance_ids" {
  value = aws_instance.app[*].id
}

output "db_instance_id" {
  value = aws_instance.db.id
}
