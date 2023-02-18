terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  shared_config_files      = ["/root/.aws/config"]
  shared_credentials_files = ["/root/.aws/credentials"]
  profile                  = "default"

}

#Creating a VPC
resource "aws_vpc" "mycustomvpc1"{
  cidr_block = "10.60.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
 

  tags = {
    NET = "MYNEWVPC"
    Env = "DEV-TEAM"
   }
}

#Creating a subnet
resource "aws_subnet" "mycustomsubnet" {
  vpc_id = aws_vpc.mycustomvpc1.id
  cidr_block = "10.60.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true  
  
  tags = {
    Name = "MYCUSTOMSUBNET"
    Env = "DEV-SUB"
  }
}

# Create a private subnet
resource "aws_subnet" "private-a" {
  vpc_id                  = aws_vpc.mycustomvpc1.id
  cidr_block              = "10.60.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-a"
  }
}

#CREATING A SG
resource "aws_security_group" "mycustomnewsg" {
  name = "MYNEWCUSTOMSG"
  description = "creating a new vpc subnet"
  vpc_id = aws_vpc.mycustomvpc1.id
 
  
  egress {
    description = "allowing access to outside"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "allowing access to inside"
    from_port = 22
    to_port  = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

  ingress {
    from_port = 0
    to_port  = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

   tags = {
     Name = "MYNEWSG"
     Env = "DEV-SG"
   }
}

#CReating a Internet gateway
resource "aws_internet_gateway" "myinternetway" {
  vpc_id = aws_vpc.mycustomvpc1.id

   tags = {
     Name = "MYNEWIGW"
     Env = "DEV-IGW"
   }
}

#CREATING A ROUTE TABLE
resource "aws_route_table" "mycustomrt" {
    vpc_id = aws_vpc.mycustomvpc1.id
  
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.myinternetway.id
   }
 
   tags = {
     Name = "MYCUSTOMRT"
     Envi = "DEV-IGW"
   }
}

#CREATING A ROUTETABLE ASSOCIATION
resource "aws_route_table_association" "mycustomrt_association" {
  subnet_id = aws_subnet.mycustomsubnet.id
  route_table_id = aws_route_table.mycustomrt.id
  }

#Creating a target group
resource "aws_lb_target_group" "mycustomnewtg" {
  name     = "mycustomnewalbtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mycustomvpc1.id
}

# Create an ALB
resource "aws_lb" "mycustomnew-alb" {
  name            = "mynewcustom-alb"
  internal        = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.mycustomnewsg.id]
  subnets         = [aws_subnet.mycustomsubnet.id, aws_subnet.private-a.id]

  tags = {
    Name = "mynewcustom-alb"
  }
}

# Create a listener for the ALB
resource "aws_lb_listener" "mycustomernew-listener" {
  load_balancer_arn = aws_lb.mycustomnew-alb.arn
  protocol          = "HTTP"
  port              = 80
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.mycustomnewtg.arn
  }
}

#Creating a route53 zone
resource "aws_route53_zone" "mycustomdns" {
  name = "myawsnewdev.xyz"

  tags = {
    Environment = "dev-dns"
  }
}

#Creating a route53 records
resource "aws_route53_record" "mycustomdnsrecord" {
  zone_id = aws_route53_zone.mycustomdns.zone_id
  name    = "myawsnewdev.xyz"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mycustominstance-web.public_ip]
}

#CREATING A NETWORK ACL TO SUBNET
resource "aws_network_acl" "mycustomacl" {
  vpc_id = aws_vpc.mycustomvpc1.id

  egress {
   protocol = "tcp"
   rule_no = 300
   action = "allow"
   cidr_block = "0.0.0.0/0"
   from_port = 443
   to_port = 443
  }
  
   ingress {
     protocol = "tcp"
     rule_no = 120
     action = "allow"
     cidr_block = "0.0.0.0/0"
     from_port = 80
     to_port = 80
   }
   
   ingress {
     protocol = "tcp"
     rule_no = 110
     action = "allow"
     cidr_block = "0.0.0.0/0"
     from_port = 8080
     to_port = 8080
   }

   tags = {
     Name = "mynetworkacl"
     Environ = "DEV-ACL"
   }
}

#CREATING A EBSVOLUME
resource "aws_ebs_volume" "mycustomebs" {
  availability_zone = "us-east-1a"
  size = "12"
 
  tags = {
    SOURCE = "MYNEWEBS"
    Env = "DEV-NEW"
   }
}

#CREATING A SNAPSHOT
resource "aws_ebs_snapshot" "mycustomsnap" {
  volume_id = aws_ebs_volume.mycustomebs.id

  tags = {
    Name = "MYSNAP"
    
  }
}


#Creating a KeyPair

resource "aws_key_pair" "mynewcustomkey" {
  key_name   = "MYCUSTOMAWSKEY"
  public_key = "${file("/root/.ssh/id_rsa.pub")}"
}

#Creating a snapshot copy
resource "aws_ebs_snapshot_copy" "mycustomnewsnapcopy" {
  source_snapshot_id = aws_ebs_snapshot.mycustomsnap.id
  source_region      = "us-east-1"

  tags = {
    Name = "MYCUSTOM_Copy_Snap"
  }
}

#Creating a bucket
resource "aws_s3_bucket" "mycustombuc" {
  bucket = "my-dev-env-team-1"

  tags = {
    Name = "my-buc-dev"
  }
}

#creating a bucket acl
resource "aws_s3_bucket_acl" "mycustomaclbuc" {
  bucket = aws_s3_bucket.mycustombuc.id
  acl = "private"
  
}

#Creating a bucket with lifecycle config
resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.mycustombuc.id

  rule {
    id = "log"

    filter {
      and {
        tags = {
          key= "Name" 
          value= "my-buc-dev"
        }
      }
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

#creating a bucket-new
resource "aws_s3_bucket" "mynewvucketone" {
  bucket = "my-new-custom-cloudgani-2023"
 
  tags = {
    Name = "my-dev-newonebuc"
  }
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.mynewvucketone.id
  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "READ"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "READ_ACP"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}


#Creating a versioning enabled
resource "aws_s3_bucket_versioning" "mybucversion" {
  bucket = aws_s3_bucket.mycustombuc.id
  versioning_configuration {
    status = "Enabled"
  }
  
}

#Creating a new another bucket
resource "aws_s3_bucket" "mycustomnewbuc" {
  bucket = "my-new-dev-env-cloud-2023"
  
  tags = {
    Name = "my-env-new-buc"
  }
}

#creating a bucket policy
resource "aws_s3_bucket_policy" "mybucpolicy" {
  bucket = aws_s3_bucket.mycustomnewbuc.id
  policy = data.aws_iam_policy_document.allowing_access_to_account.json
}

data "aws_iam_policy_document" "allowing_access_to_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["188103252438"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

   resources = [
      aws_s3_bucket.mycustomnewbuc.arn,
      "${aws_s3_bucket.mycustomnewbuc.arn}/*",
    ]
  }
}


#Now Creating a bucket cross replication
#creating a source bucket
resource "aws_s3_bucket" "mycustomsourcebuc" {
  bucket = "my-source-buc-newgani"
 
  tags = {
    Name = "my-buc-rep1"
  }
}

#create a bucket acl
resource "aws_s3_bucket_acl" "mycustombucacl" {
 bucket = aws_s3_bucket.mycustomsourcebuc.id
 acl = "private"
}

#create a bucket versionoing
resource "aws_s3_bucket_versioning" "mycustombucsourceversion" {
  bucket = aws_s3_bucket.mycustomsourcebuc.id
  versioning_configuration {
     status = "Enabled"
 }
}

#creating a destination bucket
resource "aws_s3_bucket" "mycustomdestbuc" {
  bucket = "my-destnew-buc-newgani"

  tags = {
    Name = "my-buc-rep2"
  }
}

#create a dest bucket acl
resource "aws_s3_bucket_acl" "mycustomdestbucacl" {
 bucket = aws_s3_bucket.mycustomdestbuc.id
 acl = "private"
}

#create a bucket versionoing
resource "aws_s3_bucket_versioning" "mycustombucdestnewversion" {
  bucket = aws_s3_bucket.mycustomdestbuc.id
  versioning_configuration {
     status = "Enabled"
  }
}

#creating a iam role
resource "aws_iam_role" "mycustoms3replication" {
  name = "mynewbucrole-replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "mycustomnewbucreplication" {
  name = "myrolenew-policy-replication"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.mycustomsourcebuc.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.mycustomsourcebuc.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.mycustomdestbuc.arn}/*"
    }
  ]
}
POLICY
}

#Creating a bucket object
resource "aws_s3_object" "mycustombucobject" {
  key        = "myfolder"
  bucket     = aws_s3_bucket.mycustomsourcebuc.id
  source     = "index.html"
}

#Creating a bucket object
resource "aws_s3_object" "mycustomnewbucobject" {
  key        = "myfolder"
  bucket     = aws_s3_bucket.mycustomsourcebuc.id
  source     = "file1"
}

#Creating a bucket object
resource "aws_s3_object" "mycustomnewbucobject-1" {
  key        = "myfolder"
  bucket     = aws_s3_bucket.mycustomsourcebuc.id
  source     = "file2"
}


resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.mycustoms3replication.name
  policy_arn = aws_iam_policy.mycustomnewbucreplication.arn
}

#creating a bucket cross replication
resource "aws_s3_bucket_replication_configuration" "mycustomnewreplication" {
 
  # Must have bucket versioning enabled first
  #depends_on = [aws_vpc.]

  role   = aws_iam_role.mycustoms3replication.arn
  bucket = aws_s3_bucket.mycustomsourcebuc.id

  rule {
    id = "mylog"

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.mycustomdestbuc.arn
      storage_class = "STANDARD"
    }
  }
}

#creating a aws kms key
resource "aws_kms_key" "mynewcustomkey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}

#creating a new bucket for s3
resource "aws_s3_bucket" "mycustomssebucket" {
  bucket = "my-buc-sse-encyprt"

  tags = {
    Name = "my-new-buc-sse"
  }
}

#creating a bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "mynewbucsse" {
  bucket = aws_s3_bucket.mycustomssebucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mynewcustomkey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


/*
#Creating a network interface
resource "aws_network_interface" "mycustomeni" {
  subnet_id   = aws_subnet.mycustomsubnet.id
  private_ips = ["10.60.1.100"]

  tags = {
    Name = "mycustom-eni"
  }
}
*/

#Creating a ec2-server
resource "aws_instance" "mycustominstance-web" {
  
  ami           = "ami-0dfcb1ef8550277af"
  instance_type = "t2.micro"
  tenancy    = "default"
  key_name =  aws_key_pair.mynewcustomkey.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mycustomnewsg.id]
  subnet_id                   = aws_subnet.mycustomsubnet.id

  /*
  network_interface {
    network_interface_id = aws_network_interface.mycustomeni.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
   }
*/
  
  provisioner "local-exec" {
    
    command = "sudo yum -y install httpd && sudo systemctl enable httpd && sudo systemctl start httpd"      
     }  

  tags = {
    Name = "mynewcustom-ec2inst"
  }
}

/*
#creating a target group
resource "aws_lb_target_group" "mycustomtg-1" {
  name     = "mynewcustomtg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mycustomvpc1.id
}

#creating a alb now
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group..id]
  subnets            = [aws_subnet.public..id]

  enable_deletion_protection = false

  tags = {
    Environment = "Dev-Team"
  }
}


#creating a elastic beanstack
resource "aws_elastic_beanstalk_application" "mywebelbapp" {
  name        = "mycustomnew-webapp"
  description = "Creating a my custom web application"
}

#creating a elastic beanstalk env
resource "aws_elastic_beanstalk_environment" "mynewcustomelbenv" {
  name                = "newenvwebapp-1"
  application         = aws_elastic_beanstalk_application.mywebelbapp.name
  solution_stack_name = "64bit Amazon Linux 2 v4.3.4 running Tomcat 8.5 Corretto 8"
}

*/

#creating a ecr
resource "aws_ecr_repository" "mycustomecr" {
  name                 = "mynewcustomecr-1"
  image_tag_mutability = "MUTABLE"
  force_delete  = true
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "mycustom-ecr"
  }
}

#creating a ecr repository policy
resource "aws_ecr_repository_policy" "mycustomecrpolicy" {
  repository = aws_ecr_repository.mycustomecr.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

#creating a ecr lifecycle
resource "aws_ecr_lifecycle_policy" "mycustomecrpolicy" {
  repository = aws_ecr_repository.mycustomecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}


#creating a ecs cluster
resource "aws_ecs_cluster" "myecscluster-1" {
  name = "MYECSCLUSTER-1"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#creating a ecs task def
resource "aws_ecs_task_definition" "mycustomtaskdef" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "myconfirstimage"
      image     = "nginx:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 8090
        }
      ]
    }
   ])
   volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
   }
 }
 
#creating a iam role for ecs
resource "aws_iam_role" "myiamecsrole" {
  name = "mycustomiam-role-replication"

  assume_role_policy = <<POLICY
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#creating a ecs service iam role policy
resource "aws_iam_policy" "mycustomecspolicy" {
  name = "mycustomecsiam-role-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "ecs:*",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

#now attaching a policy attachment
resource "aws_iam_role_policy_attachment" "myiamroleecspolicy" {
  role       = aws_iam_role.myiamecsrole.name
  policy_arn = aws_iam_policy.mycustomecspolicy.arn
}

#Creating a ecs service policy
 resource "aws_ecs_service" "mycustomecsservice" {
  name            = "mycustomecstask-ser"
  cluster         = aws_ecs_cluster.myecscluster-1.id
  task_definition = aws_ecs_task_definition.mycustomtaskdef.arn
  desired_count   = 3
  #iam_role        = aws_iam_role.myiamecsrole.arn
  #depends_on      = [aws_iam_role_policy.mycustomecspolicy]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}
