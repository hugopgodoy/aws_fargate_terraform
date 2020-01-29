# ecs plan

resource "aws_ecr_repository" "poc_ecr_01" {
  name                 = "poc-ecr-01"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    "project" = "poc",
    "Name"    = "poc-ecr-01"
  }
}

resource "aws_ecs_task_definition" "poc_ecs_task_01" {
  family                = "service"
  container_definitions = file("terraform/task_definitions/service.json")

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }

  tags = {
    "project" = "poc"
    "Name"    = "poc-ecs-task-01"
  }
}

resource "aws_ecs_cluster" "poc_ecs_cluster_01" {
  name = "poc-ecs-cluster-01"
}

resource "aws_ecs_service" "poc_ecs_service_01" {
  name            = "poc-ecs-service-01"
  cluster         = aws_ecs_cluster.poc_ecs_cluster_01.id
  
  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.poc_ecs_task_01.family}:${max("${aws_ecs_task_definition.poc_ecs_task_01.revision}", "${data.aws_ecs_task_definition.poc_ecs_task_01.revision}")}"
  desired_count   = 2
  # iam_role        = "${aws_iam_role.foo.arn}"
  # depends_on      = ["aws_iam_role_policy.foo"]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  # load_balancer {
  #   target_group_arn = "${aws_lb_target_group.foo.arn}"
  #   container_name   = "mongo"
  #   container_port   = 8080
  # }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }

  tags = {
    "project" = "poc",
    "Name" = "poc-ecs-service-01"
  }
}
