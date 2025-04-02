provider "aws" {
  region = "eu-north-1"
}

resource "aws_security_group" "allow_all" {
  name_prefix = "allow_all_"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "fastapi_lc" {
  name          = "fastapi-lc"
  image_id      = "ami-0c1ac8a41498c1a9c"  # Ubuntu 22.04 LTS AMI
  instance_type = "t3.micro"
  security_groups = [aws_security_group.allow-all.id]
}



resource "aws_instance" "fastapi_instance" {
  ami           = "ami-0c1ac8a41498c1a9c"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.allow_all.name]
  tags = {
    Name = "FastAPI-Instance"
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.22"
  instance_class       = "db.t3.micro"
  db_name              = "fastapi_db"
  username             = "dbuser"
  password             = "password123"
  skip_final_snapshot  = true
  publicly_accessible  = true
}

resource "aws_lb" "app_lb" {
  name               = "fastapi-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_all.id]
  subnets            =["subnet-0f3157d0aad845f98", "subnet-0157522a67b946e58"] 
}

resource "aws_lb_target_group" "fastapi_tg" {
  name     = "fastapi-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0d2c0a5a3f8ccbd00" 
}
resource "aws_autoscaling_group" "fastapi_asg" {
  desired_capacity     = 2
  min_size             = 1
  max_size             = 5
  launch_configuration = aws_launch_configuration.fastapi_lc.name
  vpc_zone_identifier  = ["subnet-0f3157d0aad845f98", "subnet-0898dadc4c9424dc0"]  # Replace with your subnet ID
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastapi_tg.arn
  }
}

