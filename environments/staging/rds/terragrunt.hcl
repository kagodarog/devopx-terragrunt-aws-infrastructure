
  # terragrunt.hcl

  include {
    path = find_in_parent_folders("root.hcl")
  }


  terraform {
    source = "../../../modules/rds"
  }

  dependency "vpc" {
    config_path = "../vpc"
    mock_outputs = {
      vpc_id             = "vpc-12345678"
      public_subnet_ids  = ["subnet-12345678", "subnet-23456789"]
      private_subnet_ids = ["subnet-34567890", "subnet-45678901"]
    }
  }


  inputs = {
  vpc_id               = dependency.vpc.outputs.vpc_id
  private_subnets      = dependency.vpc.outputs.private_subnet_ids
  create_prod_instance = true
  rds = {
    instance_class                  = "db.t4g.micro"
    engine                          = "mysql"
    engine_version                  = "8.0.35"
    username                        = "esX4rde5ertf"
    allocated_storage               = "20"
    max_allocated_storage           = "50"
    backup_retention_period         = "2"
    publicly_accessible             = false
    multi_az                        = false
    skip_final_snapshot             = true
    enabled_cloudwatch_logs_exports = ["error", "slowquery"]
    deletion_protection             = false
    storage_encrypted                 = true
    storage_type                      = "gp3"
    enable_auto_minor_version_upgrade = true
    blue_green_update                 = false
    performance_insights_enabled      = true
    copy_tags_to_snapshot             = true
    monitoring_interval               = 60
    email_sns_endpoint                = ["rogers@devopx.com", "aws@devopx.com"]
    db_custom_param = [
      {
        name         = "character_set_client"
        value        = "utf8"
        apply_method = "pending-reboot"
      },
      {
        name         = "collation_server"
        value        = "latin1_swedish_ci"
        apply_method = "pending-reboot"
      },
      {
        name         = "character_set_database"
        value        = "latin1"
        apply_method = "pending-reboot"
      },
      {
        name         = "character_set_server"
        value        = "latin1"
        apply_method = "pending-reboot"
      },
      {
        name         = "optimizer_switch"
        value        = "index_merge=off,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,index_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,duplicateweedout=on,subquery_materialization_cost_based=on,use_index_extensions=on,condition_fanout_filter=on,derived_merge=on,use_invisible_indexes=off,skip_scan=on,hash_join=on,subquery_to_derived=off,prefer_ordering_index=on,derived_condition_pushdown=on"
        apply_method = "pending-reboot"
      },
      {
        name         = "innodb_online_alter_log_max_size"
        value        = "10737418240"
        apply_method = "immediate"
      },
      {
        name         = "binlog_checksum"
        value        = "NONE"
        apply_method = "immediate"
      },
      {
        name         = "binlog_format"
        value        = "ROW"
        apply_method = "immediate"
      },
      {
        name         = "binlog_row_image"
        value        = "Full"
        apply_method = "immediate"
      },
      {
        name         = "slow_query_log"
        value        = "1"
        apply_method = "immediate"
      },
      {
        name         = "log_output"
        value        = "FILE"
        apply_method = "immediate"
      },
      {
        name         = "log_bin_trust_function_creators"
        value        = "1"
        apply_method = "immediate"
      },
      {
        name         = "wait_timeout"
        value        = "3600"
        apply_method = "immediate"
      },
    ]
  }
  }




