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
resource "aws_vpc" "css_vpc" {
  cidr_block = "10.0.0.0/18" 

  tags = {
    Name = "Eco-car-sharing-service"
  }
}


# Create  public and  private subnets within the VPC
resource "aws_subnet" "public-css1" {
  vpc_id                  = aws_vpc.css_vpc.id
  cidr_block              = "10.0.1.0/24" 
  availability_zone       = "us-east-1a" 

  tags = {
    Name = "Css Public Subnet"
  }
}

resource "aws_subnet" "private-css1" {
  vpc_id                  = aws_vpc.css_vpc.id
  cidr_block              = "10.0.2.0/24" 
  availability_zone       = "us-east-1b" 

  tags = {
    Name = "Css Private Subnet"
  }
}

# Launch two (2) EC2 instance

resource "aws_instance" "public_1" {
  ami               = "ami-0e8a34246278c21e4" 
  instance_type     = "t2.micro"              
  key_name          = "my-private-key"    
  subnet_id         = aws_subnet.public-css1.id
  associate_public_ip_address = true


  tags = {
    Name = "public 1"
  }
}

resource "aws_instance" "private-1" {
  ami               = "ami-0e8a34246278c21e4" 
  instance_type     = "t2.micro"              
  key_name          = "my-private-key"    
  subnet_id         = aws_subnet.private-css1.id
  
 
  tags = {
    Name = "private 1"
  }
}


#ASG launch configuration is used to configure the EC2 instances that will be launched by the ASG
resource "aws_launch_configuration" "css-launch-config" {
  name = "css-launch-config"
 image_id = "ami-0e8a34246278c21e4"  
  instance_type = "t2.micro"
  user_data    = <<-EOF
                    #!/bin/bash
                    echo "Hello, World!" > index.html
                    EOF
}

# Define Auto scaling group
resource "aws_autoscaling_group" "css-asg"{
  launch_configuration = aws_launch_configuration.css-launch-config.id
  min_size             = 1
  max_size             = 5
  desired_capacity     = 2
  vpc_zone_identifier = ["public-css1" , "private-css1"]
  
  health_check_type          = "EC2"
  health_check_grace_period  = 200
  force_delete               = true

  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }
}

# Define Target Group
resource "aws_lb_target_group" "css-tg" {
  name        = "css-tg"
  port        = 80  
  protocol    = "HTTP" 
  vpc_id      = aws_vpc.css_vpc.id
}

# Define Load Balancer
resource "aws_lb" "css-alb" {
  name               = "css-alb"
  internal           = false  
  load_balancer_type = "application"  
  subnets            = ["public-css1" , "private-css1"]
}

# Define Listener
resource "aws_lb_listener" "css-listener" {
  load_balancer_arn = aws_lb.css-alb.arn
  port              = 80  
  protocol          = "HTTP"  

  default_action {
    target_group_arn = aws_lb_target_group.css-tg.arn  
    type             = "forward"
  }
}





















 