
variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_alb_sg_id" {
  type = string
}

variable "private_alb_sg_id" {
  type = string
}

# Public Application Load Balancer
resource "aws_lb" "public" {
  name               = "three-tier-public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.public_alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "public-alb"
  }
}

# Public ALB Target Group
resource "aws_lb_target_group" "web" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
  }

  tags = {
    Name = "web-target-group"
  }
}

# Public ALB Listener
resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Private Application Load Balancer
resource "aws_lb" "private" {
  name               = "three-tier-private-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.private_alb_sg_id]
  subnets            = var.private_subnet_ids

  tags = {
    Name = "private-alb"
  }
}

# Private ALB Target Group
resource "aws_lb_target_group" "app" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
  }

  tags = {
    Name = "app-target-group"
  }
}

# Private ALB Listener
resource "aws_lb_listener" "private" {
  load_balancer_arn = aws_lb.private.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "web_target_group_arn" {
  value = aws_lb_target_group.web.arn
}

output "app_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "public_alb_dns" {
  value = aws_lb.public.dns_name
}

output "private_alb_dns" {
  value = aws_lb.private.dns_name
}
