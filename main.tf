resource "aws_ecr_repository" "hello-world" {
  name                 = "hello-world"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "hello-world-cl" {
  name = "hello-world"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}


resource "aws_ecs_task_definition" "first-task" {
 depends_on = [
    aws_iam_role.ecsTaskExecutionRole
  ]
 
  family = "first-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "${aws_ecr_repository.hello-world.repository_url}:New",
      essential = true
      cpu = 1024
      memory = 2048
      portMappings = [
        { 
          protocol = "tcp"
          containerPort = 80
          hostPort      = 80
        }
      ],
     logConfiguration={
          "logDriver": "awslogs",
          "options": {
            "awslogs-create-group": "true",
            "awslogs-group": "/ecs/app",
            "awslogs-region": "eu-west-2",
            "awslogs-stream-prefix": "ecs"
          }
        }
    }
  ]
  )
}

resource "aws_iam_role" "ecsTaskExecutionRole"{
  name= "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
}
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy"{
  statement {
    sid = "A"
    actions=["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]

    }
}
  statement {
    sid= "B"
    actions=["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = ["*"]

    }
  }
}

resource "aws_ecs_service" "hello-world" {
  name                = "hello-world"
  cluster        = aws_ecs_cluster.hello-world-cl.id
  task_definition     = aws_ecs_task_definition.first-task.arn
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    security_groups =  ["${aws_default_security_group.default.id}"]
    subnets= ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}","${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true 
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = "vpc-03e7ba2c2d4601f5b"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_vpc" "default_vpc" {
  
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "eu-west-2a"
  
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "eu-west-2b"
  
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "eu-west-2c"

} 
