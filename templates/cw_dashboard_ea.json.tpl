{
    "widgets": [
        {
            "height": 1,
            "width": 24,
            "y": 0,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "**${project}-${environment} ELB Metrics**"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 1,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${elb_arn_suffix}", { "visible": false } ],
                    [ "...", "app/chainlink-orion-money-node/123c01e674909a23" ],
                    [ ".", "HTTPCode_ELB_4XX_Count", ".", "." ],
                    [ ".", "HTTPCode_ELB_5XX_Count", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "stat": "Sum",
                "period": 300,
                "title": "AppELB Request Codes"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 1,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "ProcessedBytes", "LoadBalancer", "${elb_arn_suffix}" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "stat": "Sum",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 1,
            "x": 12,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "ConsumedLCUs", "LoadBalancer", "${elb_arn_suffix}" ]
                ],
                "region": "${region}"
            }
        },
        {
            "height": 1,
            "width": 24,
            "y": 7,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "**${project}-${environment} MemoryDB Metrics**"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 8,
            "x": 0,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/MemoryDB", "EngineCPUUtilization", "ClusterName", "${project}-${environment}-ea" ]
                ],
                "region": "${region}",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 8,
            "x": 6,
            "type": "metric",
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/MemoryDB", "DatabaseMemoryUsagePercentage", "ClusterName", "${project}-${environment}-ea" ]
                ],
                "region": "${region}",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 8,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/MemoryDB", "MemoryFragmentationRatio", "ClusterName", "${project}-${environment}-ea" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "stat": "Maximum",
                "period": 300
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 8,
            "x": 18,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/MemoryDB", "CurrItems", "ClusterName", "${project}-${environment}-ea" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "stat": "Sum",
                "period": 300
            }
        },
        %{ for ea_name in ea_names ~}
        {
            "type": "text",
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": "**${project}-${environment}-${ea_name} adapter metrics**"
            }
        },
        {
            "type": "metric",
            "width": 12,
            "height": 6,
            "properties": {
                "region": "${region}",
                "title": "CPU Utilization",
                "legend": {
                    "position": "bottom"
                },
                "timezone": "Local",
                "metrics": [
                    [ { "id": "expr1m0", "label": "${project}-${environment}-${ea_name}", "expression": "mm1m0 * 100 / mm0m0", "stat": "Average" } ],
                    [ "ECS/ContainerInsights", "CpuReserved", "ClusterName", "${project}-${environment}-ea", "ServiceName", "${project}-${environment}-${ea_name}", { "id": "mm0m0", "visible": false, "stat": "Sum" } ],
                    [ "ECS/ContainerInsights", "CpuUtilized", "ClusterName", "${project}-${environment}-ea", "ServiceName", "${project}-${environment}-${ea_name}", { "id": "mm1m0", "visible": false, "stat": "Sum" } ]
                ],
                "start": "-P0DT3H0M0S",
                "end": "P0D",
                "liveData": false,
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "Percent"
                    }
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "width": 12,
            "height": 6,
            "properties": {
                "region": "${region}",
                "title": "Memory Utilization",
                "legend": {
                    "position": "bottom"
                },
                "timezone": "Local",
                "metrics": [
                    [ { "id": "expr1m0", "label": "${project}-${environment}-${ea_name}", "expression": "mm1m0 * 100 / mm0m0", "stat": "Average" } ],
                    [ "ECS/ContainerInsights", "MemoryReserved", "ClusterName", "${project}-${environment}-ea", "ServiceName", "${project}-${environment}-${ea_name}", { "id": "mm0m0", "visible": false, "stat": "Sum" } ],
                    [ "ECS/ContainerInsights", "MemoryUtilized", "ClusterName", "${project}-${environment}-ea", "ServiceName", "${project}-${environment}-${ea_name}", { "id": "mm1m0", "visible": false, "stat": "Sum" } ]
                ],
                "start": "-P0DT6H0M0S",
                "end": "P0D",
                "liveData": false,
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "Percent"
                    }
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "log",
            "width": 12,
            "height": 6,
            "properties": {
                "query": " SOURCE '/aws/ecs/${project}-${environment}-${ea_name}' | fields @timestamp, @message\n| sort @timestamp desc\n| filter @message like 'error'\n| limit 20",
                "region": "${region}",
                "stacked": false,
                "view": "table"
            }
        },
        {
            "type": "metric",
            "width": 3,
            "height": 6,
            "properties": {
                "region": "${region}",
                "title": "Number of Desired Tasks",
                "legend": {
                    "position": "bottom"
                },
                "timezone": "Local",
                "metrics": [
                    [ "ECS/ContainerInsights", "DesiredTaskCount", "ClusterName", "${project}-${environment}-ea", "ServiceName", "${project}-${environment}-${ea_name}", { "stat": "Average" } ]
                ],
                "start": "-P0DT6H0M0S",
                "end": "P0D",
                "liveData": false,
                "period": 60,
                "view": "singleValue",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "width": 3,
            "height": 6,
            "properties": {
                "region": "${region}",
                "title": "Number of Running Tasks",
                "legend": {
                    "position": "bottom"
                },
                "timezone": "Local",
                "metrics": [
                    [ "ECS/ContainerInsights", "RunningTaskCount", "ClusterName", "${project}-${environment}-ea", "ServiceName", "${project}-${environment}-${ea_name}", { "stat": "Average" } ]
                ],
                "start": "-P0DT6H0M0S",
                "end": "P0D",
                "liveData": false,
                "period": 60,
                "view": "singleValue",
                "stacked": false
            }
        },
        {
            "type": "alarm",
            "width": 6,
            "height": 6,
            "properties": {
                "title": "${ea_name} EA Alarms Status",
                "alarms": [
                    "arn:aws:cloudwatch:${region}:${account_id}:alarm:${project}-${environment}-ea-${ea_name}-CPUUtilizationHigh",
                    "arn:aws:cloudwatch:${region}:${account_id}:alarm:${project}-${environment}-ea-${ea_name}-MemoryUtilizationHigh",
                    "arn:aws:cloudwatch:${region}:${account_id}:alarm:${project}-${environment}-ea-${ea_name}-log-error"
                ]
            }
        },
        %{ endfor ~}
        {
            "type": "text",
            "width": 24,
            "height": 1,
            "properties": {
                "markdown": ""
            }
        }
    ]
}
