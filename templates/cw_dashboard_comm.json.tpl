{
    "widgets": [
        {
            "height": 6,
            "width": 6,
            "y": 10,
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
            "y": 10,
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
            "y": 10,
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
            "y": 10,
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
        {
            "height": 2,
            "width": 24,
            "y": 0,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "**${project}-${environment} ELB Metrics**"
            }
        },
        {
            "height": 2,
            "width": 24,
            "y": 8,
            "x": 0,
            "type": "text",
            "properties": {
                "markdown": "**${project}-${environment} MemoryDB Metrics**"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 2,
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
            "y": 2,
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
            "y": 2,
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
        }
    ]
}
