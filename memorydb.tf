resource "aws_memorydb_parameter_group" "this" {
  count = var.cache_redis ? 1 : 0

  name   = "${var.project}-${var.environment}-ea"
  family = "memorydb_redis6"
}

resource "aws_memorydb_subnet_group" "this" {
  count = var.cache_redis ? 1 : 0

  name       = "${var.project}-${var.environment}-ea"
  subnet_ids = var.vpc_private_subnets
}

resource "aws_memorydb_cluster" "this" {
  count = var.cache_redis ? 1 : 0

  acl_name                 = "open-access"
  tls_enabled              = false
  name                     = "${var.project}-${var.environment}-ea"
  node_type                = var.memorydb_node_type
  num_shards               = var.memorydb_shards_count
  num_replicas_per_shard   = var.memorydb_num_replicas_per_shard
  port                     = 6379
  security_group_ids       = [aws_security_group.memorydb_sg[0].id]
  snapshot_retention_limit = var.memorydb_snapshot_retention_limit
  subnet_group_name        = aws_memorydb_subnet_group.this[0].id
  parameter_group_name     = aws_memorydb_parameter_group.this[0].id
  # sns_topic_arn            = var.monitoring_enabled ? ( var.sns_topic_arn == "" ? aws_sns_topic.this[0].arn : var.sns_topic_arn ) : ""
}

# SG for MemoryDB
resource "aws_security_group" "memorydb_sg" {
  count = var.cache_redis ? 1 : 0

  name        = "${var.project}-${var.environment}-ea-memorydb"
  description = "Allow trafic to redis memoryDB from VPC"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress_mem_allow_self" {
  count = var.cache_redis ? 1 : 0

  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  self      = true

  security_group_id = aws_security_group.memorydb_sg[0].id
}

resource "aws_security_group_rule" "egress_mem_allow_all" {
  count = var.cache_redis ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.memorydb_sg[0].id
}
