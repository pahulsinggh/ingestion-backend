locals {
  path_prefix = var.subdir == "" ? "" : "cd ${var.subdir} && "
  target_dir  = var.subdir == "" ? "target" : "${var.subdir}/target"
}

# Guard the source-build App Runner service.
# When gh_conn_arn is empty (""), count = 0 -> no resource created.
resource "aws_apprunner_service" "backend" {
  count        = var.gh_conn_arn == "" ? 0 : 1
  service_name = "${var.proj}-backend"

  source_configuration {
    authentication_configuration {
      connection_arn = var.gh_conn_arn
    }

    code_repository {
      repository_url = var.repo_url

      source_code_version {
        type  = "BRANCH"
        value = var.repo_branch
      }

      code_configuration {
        configuration_source = "API"

        # NOTE: App Runner source runtimes support Corretto 8/11; 17 is not supported in source mode.
        # We are moving to IMAGE mode separately; this block is kept for reference and optional use.
        code_configuration_values {
          runtime       = "CORRETTO_17"
          build_command = "${local.path_prefix}./mvnw -DskipTests package"
          start_command = "bash -lc '${local.path_prefix}java -jar $(ls ${local.target_dir}/*SNAPSHOT*.jar | head -n1)'"
          port          = "8080"
        }
      }
    }

    auto_deployments_enabled = false
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/actuator/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
}

# Safe output: returns null if the resource wasn't created (count = 0)
output "apprunner_url" {
  value       = length(aws_apprunner_service.backend) > 0 ? aws_apprunner_service.backend[0].service_url : null
  description = "App Runner URL for the source-build path (only when gh_conn_arn is set)"
}
