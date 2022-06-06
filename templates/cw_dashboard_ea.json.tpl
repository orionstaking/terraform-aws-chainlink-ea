{
    "widgets": [
        {
            "height": 6,
            "width": 9,
            "y": 0,
            "x": 0,
            "type": "metric",
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
            "height": 6,
            "width": 9,
            "y": 0,
            "x": 9,
            "type": "metric",
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
            "height": 3,
            "width": 3,
            "y": 0,
            "x": 21,
            "type": "metric",
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
            "height": 3,
            "width": 3,
            "y": 0,
            "x": 18,
            "type": "metric",
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
            "height": 6,
            "width": 18,
            "y": 6,
            "x": 0,
            "type": "log",
            "properties": {
                "query": " SOURCE '${log_group}' | fields @timestamp, @message\n| sort @timestamp desc\n| filter @message like 'error'\n| limit 20",
                "region": "${region}",
                "stacked": false,
                "view": "table"
            }
        },
        {
            "type": "alarm",
            "height": 3,
            "width": 6,
            "y": 3,
            "x": 18,
            "properties": {
                "title": "${ea_name} EA Alarms Status",
                "alarms": [
                    "arn:aws:cloudwatch:${region}:${account_id}:alarm:${project}-${environment}-ea-${ea_name}-CPUUtilizationHigh",
                    "arn:aws:cloudwatch:${region}:${account_id}:alarm:${project}-${environment}-ea-${ea_name}-MemoryUtilizationHigh"
                ]
            }
        },
        {
            "type": "alarm",
            "height": 6,
            "width": 6,
            "y": 6,
            "x": 18,
            "properties": {
                "title": "${ea_name} EA Logs Status",
                "alarms": [
                    "arn:aws:cloudwatch:${region}:${account_id}:alarm:${project}-${environment}-ea-${ea_name}-log-error"
                ]
            }
        }
    ]
}
