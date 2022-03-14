resource "aws_lb" "gwlbe_ingress_spoke_local_app_nlb" {
  name               = "${var.vpc_name}-local-app-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [for subnet in module.nlb_subnets.nlb_subnets : subnet.subnet_id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.vpc_name}-local-app-nlb"
  }
}

resource "aws_lb_target_group" "gwlbe_ingress_spoke_local_app_nlb_tg" {
  name     = "${var.vpc_name}-local-app-nlb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.ingress.id
}


resource "aws_lb_target_group_attachment" "gwlbe_ingress_spoke_local_app_nlb_tg_attachment" {
  count = length(module.gwlbe_ingress_spoke_instance)
  target_group_arn = aws_lb_target_group.gwlbe_ingress_spoke_local_app_nlb_tg.arn
  target_id        = module.gwlbe_ingress_spoke_instance[count.index].instance_id
  port             = 80
}

resource "aws_lb_listener" "gwlbe_ingress_spoke_local_app_nlb_listener" {
    load_balancer_arn = aws_lb.gwlbe_ingress_spoke_local_app_nlb.arn
    port = "80"
    protocol = "TCP"
    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlbe_ingress_spoke_local_app_nlb_tg.arn
  }
}

output "gwlbe_ingress_local_app_nlb_dns_name" {
    value = aws_lb.gwlbe_ingress_spoke_local_app_nlb.dns_name
}

resource "aws_lb" "gwlbe_ingress_spoke_local_app_alb" {
  name               = "${var.vpc_name}-local-app-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in module.nlb_subnets.nlb_subnets : subnet.subnet_id]
  security_groups    = [aws_security_group.gwlbe_ingress_spoke_local_app_alb_sg.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.vpc_name}-local-app-alb"
  }
}

resource "aws_security_group" "gwlbe_ingress_spoke_local_app_alb_sg" {
  name        = "${var.vpc_name}-local-app-alb-sg"
  description = "${var.vpc_name}-local-app-alb-sg"
  vpc_id      = aws_vpc.ingress.id

   ingress {
    description = "TCP80"
    from_port   = 0
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

  tags = {
    Name = "${var.vpc_name}-local-app-alb-sg"
  }
}


resource "aws_lb_target_group" "gwlbe_ingress_spoke_local_app_alb_tg" {
  name     = "${var.vpc_name}-local-app-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ingress.id
}


resource "aws_lb_target_group_attachment" "gwlbe_ingress_spoke_local_app_alb_tg_attachment" {
  count = length(module.gwlbe_ingress_spoke_instance)
  target_group_arn = aws_lb_target_group.gwlbe_ingress_spoke_local_app_alb_tg.arn
  target_id        = module.gwlbe_ingress_spoke_instance[count.index].instance_id
  port             = 80
}

resource "aws_lb_listener" "gwlbe_ingress_spoke_local_app_alb_listener" {
    load_balancer_arn = aws_lb.gwlbe_ingress_spoke_local_app_alb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlbe_ingress_spoke_local_app_alb_tg.arn
  }
}



output "gwlbe_ingress_local_app_alb_dns_name" {
    value = aws_lb.gwlbe_ingress_spoke_local_app_alb.dns_name
}