terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"  
    }
  }
}
# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "eco-css_vpc" {
  cidr_block = "10.0.0.0/18" 

  tags = {
    Name = "Eco-car-sharing service"
  }
}

# Create  public and  private subnets within the VPC
resource "aws_subnet" "public_css1" {
  vpc_id                  = aws_vpc.eco-css_vpc.id
  cidr_block              = "10.0.1.0/24" 
  availability_zone       = "us-east-1a" 

  tags = {
    Name = "Css Public Subnet"
  }
}

resource "aws_subnet" "private_css1" {
  vpc_id                  = aws_vpc.eco-css_vpc.id
  cidr_block              = "10.0.2.0/24" 
  availability_zone       = "us-east-1b" 

  tags = {
    Name = "Css Private Subnet"
  }
}

# Launch four (2) EC2 instance

resource "aws_instance" "public_1" {
  ami               = "ami-0e8a34246278c21e4" 
  instance_type     = "t2.micro"              
  key_name          = "css_key"    
  subnet_id         = aws_subnet.public_css1.id
  associate_public_ip_address = true


  tags = {
    Name = "public 1"
  }
}

resource "aws_instance" "private_1" {
  ami               = "ami-0e8a34246278c21e4" 
  instance_type     = "t2.micro"              
  key_name          = "css_key"    
  subnet_id         = aws_subnet.private_css1.id
  
 
  tags = {
    Name = "private 1"
  }
}

resource "aws_launch_configuration" "css_lc" {
  name = "css-launch-config"
 image_id = "ami-0e8a34246278c21e4"  
  instance_type = "t2.micro"
  
}

# Define Auto scaling group
resource "aws_autoscaling_group" "css_asg" {
  launch_configuration = aws_launch_configuration.css_asg.id
  min_size             = 1
  max_size             = 5
  desired_capacity     = 2

}

# Define Target Group
resource "aws_lb_target_group" "css_tg" {
  name        = "css-tg"
  port        = 80  
  protocol    = "HTTP" 
  vpc_id      = "aws_vpc.eco-css_vpc.id"  
}

# Define Load Balancer
resource "aws_lb" "css_alb" {
  name               = "car-sharing"
  internal           = false  
  load_balancer_type = "application"  
  subnets            = ["aws_subnet.public_css1.id", "aws_subnet.private_css1.id"]  
}

# Define Listener
resource "aws_lb_listener" "css_listener" {
  load_balancer_arn = aws_lb.css_alb.arn
  port              = 80  
  protocol          = "HTTP"  

  default_action {
    target_group_arn = aws_lb_target_group.css_tg.arn  
    type             = "forward"
  }
}

# Define Routing Rules 
  resource "aws_lb_listener_rule" "css_listener_rule"{

  listener_arn = aws_lb_listener.css_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.css_tg.arn 
  }
  condition {
    path_pattern {
      values = "/"
    }
  }
}





















 