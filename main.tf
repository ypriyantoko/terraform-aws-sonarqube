# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  profile = var.profile
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------------------------------------------------
locals {
  sonar_postgres_sql_db_version = "11.6"
  sonar_postgre_sql_port        = 5432
  sonar_postgre_sql_db          = "sonar"
  sonar_db_instance_size        = "db.r4.large"
  sonar_db_name                 = "sonar"
  sonar_db_username             = "sonar"
  sonar_db_password             = "${var.name_preffix}-sonar-pass"
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS Fargate Service
# ---------------------------------------------------------------------------------------------------------------------
module "ecs_fargate" {
  source  = "cn-terraform/ecs-fargate/aws"
  version = "2.0.12"
  # source = "../terraform-aws-ecs-fargate"

  name_preffix                 = "${var.name_preffix}-sonar"
  profile                      = var.profile
  region                       = var.region

  vpc_id                       = var.vpc_id
  public_subnets_ids           = var.public_subnets_ids
  private_subnets_ids          = var.private_subnets_ids
  container_name               = "${var.name_preffix}-sonar"
  container_image              = "cnservices/sonarqube"
  container_cpu                = 4096
  container_memory             = 8192
  container_memory_reservation = 4096
  lb_http_ports                = [ 9000, 9001 ]
  lb_https_ports               = []
  port_mappings = [
    {
      containerPort = 9000
      hostPort      = 9000
      protocol      = "tcp"
    },
    {
      containerPort = 9001
      hostPort      = 9001
      protocol      = "tcp"
    }
  ]
  environment = [
    {
      name  = "SONAR_JDBC_USERNAME"
      value = local.sonar_db_username
    },
    {
      name  = "SONAR_JDBC_PASSWORD"
      value = local.sonar_db_password
    },
    {
      name  = "SONAR_JDBC_URL"
      value = "jdbc:postgresql://${aws_rds_cluster.aurora_db.endpoint}/${local.sonar_db_name}"
    },
  ]
}
