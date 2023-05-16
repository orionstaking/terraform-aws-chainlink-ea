[
  {
    "name": "${project}-${environment}-${ea_name}",
    "cpu": ${cpu},
    "memory": ${memory},
    "image": "${docker_image}:${docker_tag}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${ea_port},
        "hostPort": ${ea_port}
      },
      {
        "containerPort": ${metrics_port},
        "hostPort": ${metrics_port}
      }
    ],
    "environment" : [
        { "name" : "CACHE_ENABLED", "value" : "${cache_enabled}" },
        { "name" : "CACHE_TYPE", "value" : "${cache_type}" },
        { "name" : "CACHE_KEY_GROUP", "value" : "${ea_name}" },
        { "name" : "BASE_URL", "value" : "/${ea_name}" },
        { "name" : "METRICS_USE_BASE_URL", "value" : "true" },
        { "name" : "METRICS_PORT", "value" : "${metrics_port}" },
        %{ if cache_type == "redis" }
        { "name" : "CACHE_REDIS_HOST", "value" : "${cache_redis_host}" },
        { "name" : "CACHE_REDIS_PORT", "value" : "${cache_redis_port}" },
        %{ endif }
        { "name" : "RATE_LIMIT_ENABLED", "value" : "${rate_limit_enabled}" },
        { "name" : "RATE_LIMIT_API_PROVIDER", "value" : "${rate_limit_api_provider}" },
        %{ if rate_limit_api_tier != "" }
        { "name" : "RATE_LIMIT_API_TIER", "value" : "${rate_limit_api_tier}" },
        %{ endif }
        %{~ for definition in ea_specific_variables ~}
        { "name" : "${definition.name}", "value" : "${definition.value}" },
        %{~ endfor ~}
        { "name" : "LOG_LEVEL", "value" : "${log_level}" }
      ],
    "secrets": ${jsonencode([
      for secret in ea_secret_variables : {
        name      = "${secret.name}"
        valueFrom = "${secret.valueFrom}" 
      }
    ])},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
          "awslogs-region": "${aws_region}",
          "awslogs-group": "/aws/ecs/${project}-${environment}-${ea_name}",
          "awslogs-stream-prefix": "${ea_name}"
      }
    }
  }
]
