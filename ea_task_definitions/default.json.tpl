[
  {
    "name": "${project}-${environment}-${ea_name}",
    "cpu": ${cpu},
    "memory": ${memory},
    "image": "${docker_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${port},
        "hostPort": ${port}
      }
    ],
    "environment" : [
        { "name" : "API_TIMEOUT", "value" : "${api_timeout}" },
        { "name" : "CACHE_ENABLED", "value" : "${cache_enabled}" },
        { "name" : "CACHE_MAX_AGE", "value" : "${cache_max_age}" },
        { "name" : "CACHE_MAX_ITEMS", "value" : "${cache_max_items}" },
        { "name" : "CACHE_TYPE", "value" : "${cache_type}" },
        { "name" : "CACHE_KEY_GROUP", "value" : "${ea_name}" },
        %{ if cache_type == "redis" }
        { "name" : "CACHE_REDIS_HOST", "value" : "${cache_redis_host}" },
        { "name" : "CACHE_REDIS_PORT", "value" : "${cache_redis_port}" },
        { "name" : "CACHE_REDIS_TIMEOUT", "value" : "${cache_redis_timeout}" },
        %{ endif }
        { "name" : "RATE_LIMIT_ENABLED", "value" : "${rate_limit_enabled}" },
        { "name" : "WARMUP_ENABLED", "value" : "${warmup_enabled}" },
        { "name" : "RATE_LIMIT_API_PROVIDER", "value" : "${ea_name}" },
        { "name" : "RATE_LIMIT_API_TIER", "value" : "${api_tier}" },
        { "name" : "WS_ENABLED", "value" : "${ws_enabled}" },
        { "name" : "REQUEST_COALESCING_ENABLED", "value" : "${request_coalescing_enabled}" },
        { "name" : "REQUEST_COALESCING_INTERVAL", "value" : "${request_coalescing_interval}" },
        { "name" : "REQUEST_COALESCING_INTERVAL_MAX", "value" : "${request_coalescing_interval_max}" },
        { "name" : "REQUEST_COALESCING_INTERVAL_COEFFICIENT", "value" : "${request_coalescing_interval_coefficient}" },
        { "name" : "REQUEST_COALESCING_ENTROPY_MAX", "value" : "${request_coalescing_entropy_max}" },
        { "name" : "LOG_LEVEL", "value" : "${log_level}" },
        { "name" : "DEBUG", "value" : "${debug}" },
        { "name" : "API_VERBOSE", "value" : "${api_verbose}" },
        %{~ for definition in ea_specific_variables ~}
        { "name" : "${definition.name}", "value" : "${definition.value}" },
        %{~ endfor ~}
        { "name" : "EXPERIMENTAL_METRICS_ENABLED", "value" : "${experimental_metrics_enabled}" },
        { "name" : "METRICS_NAME", "value" : "${ea_name}" }
      ],
    %{ if api_key != "" }
    "secrets": [
      %{~ for secret in ea_specific_secret_variables ~}
      {
        "name": "${secret.name}",
        "valueFrom": "${secret.valueFrom}"
      },
      %{~ endfor ~}
      {
        "name": "API_KEY",
        "valueFrom": "${api_key}"
      }
    ],
    %{ endif }
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
