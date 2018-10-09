resource "aws_ecs_cluster" "ecs_blog_cluster" {
  name = "ecs_blog_ohr486_net"
}

resource "aws_ecs_service" "ces_blog_service" {
  cluster = "${aws_ecs_cluster.ecs_blog_cluster.id}"
  name = "ecs_blog_ohr486_service"
  launch_type = "FARGATE"
  task_definition = "${aws_ecs_task_definition.ecs_blog_service.arn}"
  network_configuration {
    subnets = ["${aws_subnet.blog_ohr486_net.id}"]
    security_groups = ["${aws_security_group.blog_ohr486_net_allow_all.id}"]
    assign_public_ip = "true"
  }
}

resource "aws_ecs_task_definition" "ecs_blog_service" {
  family = "ecs_blog_service"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  execution_role_arn = "arn:aws:iam::800832305859:role/ecs-service-role"
  cpu = 256
  memory = 512
  container_definitions = <<EOF
[
  {
    "environment": [],
    "image": "nginx",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "blog-ohr486-net",
        "awslogs-region": "ap-northeast-1",
        "awslogs-stream-prefix": "wordpress"
      }
    },
    "memory": 300,
    "name": "wordpress",
    "portMappings": [
      {
        "containerPort": 5000,
        "protocol": "tcp"
      }
    ]
  }
]
EOF
}
