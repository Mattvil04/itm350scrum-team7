resource "aws_vpc" "ecs-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_prefix
  }
}

resource "aws_subnet" "subnet-pub1" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.ecs-vpc.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags = {
    Name = "${var.vpc_prefix}-public-2a"
  }
}

resource "aws_subnet" "subnet-pub2" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.ecs-vpc.cidr_block, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.vpc_prefix}-public-2b"
  }
}

resource "aws_subnet" "subnet-priv1" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.ecs-vpc.cidr_block, 8, 3)
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}a"
  tags = {
    Name = "${var.vpc_prefix}-private-2a"
  }
}

resource "aws_subnet" "subnet-priv2" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.ecs-vpc.cidr_block, 8, 4)
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}b"
  tags = {
    Name = "${var.vpc_prefix}-private-2b"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.subnet-pub1.id
  tags = {
    Name = "NAT-gateway"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ecs-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ecs-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "subnet_route" {
  subnet_id      = aws_subnet.subnet-pub1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "subnet2_route" {
  subnet_id      = aws_subnet.subnet-pub2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "priv_subnet1_route" {
  subnet_id      = aws_subnet.subnet-priv1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "priv_subnet2_route" {
  subnet_id      = aws_subnet.subnet-priv2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "alb-http-sg" {
  name_prefix = "alb-http-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb-http-sg"
  }
}

resource "aws_security_group" "ecs-cluster-sg" {
  name_prefix = "ecs-cluster-sg"
  ingress {
    from_port       = 32153
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-http-sg.id]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [aws_security_group.alb-http-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ecs-cluster-sg"
  }
}

resource "aws_key_pair" "ecs-node-kp" {
  key_name   = "ecs-node-key"
  public_key = var.public_key
}

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.ecs-node-kp.key_name
  vpc_security_group_ids = [aws_security_group.ecs-cluster-sg.id]
  iam_instance_profile {
    name = "LabInstanceProfile"
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }
  user_data = base64encode(data.template_file.user_data.rendered)
}

resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.subnet-priv1.id, aws_subnet.subnet-priv2.id]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tags = [
    {
      key                 = "Name"
      value               = "ecs-asg"
      propagate_at_launch = true
    }
  ]
}

resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-http-sg.id]
  subnets            = [aws_subnet.subnet-pub1.id, aws_subnet.subnet-pub2.id]

  enable_deletion_protection = false
  idle_timeout = 60

  tags = {
    Name = "ecs-alb"
  }
}

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "OK"
    }
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.ecs-vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "bb_task_definition" {
  family             = "bb-task"
  network_mode       = "bridge"
  execution_role_arn = var.lab_role
  task_role_arn      = var.lab_role
  cpu                = 256
  memory             = 256
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([{
    name      = "bb"
    image     = var.container_image
    cpu       = 0
    essential = true
    portMappings = [
      {
        containerPort = var.container_port
        hostPort      = 0
        protocol      = "tcp"
        appProtocol   = "http"
      }
    ]
  }])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "bb-ecs-srv"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.bb_task_definition.arn
  desired_count   = 2
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "bb"
    container_port   = var.container_port
  }
  depends_on = [aws_lb_listener.ecs_alb_listener]
}

output "alb_url" {
  value = aws_lb.ecs_alb.dns_name
}
