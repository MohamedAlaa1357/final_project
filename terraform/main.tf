provider "aws" {
    region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
    key_name    = "deployer-key"
    public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_security_group" "allow_ssh_http" {
    name          = "allow_ssh"
    description   = "allow ssh and http access"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 9090
        to_port     = 9090
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "monitoring" {
    ami           =  "ami-0c02fb55956c7d316"
    instance_type =  "t2.micro"
    key_name      = aws_key_pair.deployer.key_name
    security_groups = [aws_security_group.allow_ssh_http.name]

    tags = {
        Name = "monitoring-instance"
    }
}

resource "aws_db_instance" "default" {
    engine              =  "postgres"
    instance_class      =  "db.t2.micro"
    allocated_storage   = 20
    name                = "mydb"
    username            = "admin"
    password            = "password"
    publicly_accessible = true
    skip_final_snapshot = true
}


resource "aws_s3_bucket" "mybucket" {
    bucket = "mybucket"
    acl    = "private"
}

resource "aws_lambda_function" "my_lambda" {
    function_name      = "myLambdaFunction"
    role               = "aws_iam_role.lambda_exec.arn
    handler            = "index.handler"
    runtime            = "nodejs12.x"
    filename           = "lambda_function.zip"
    source_code_hash   = filebase64sha256("lambda_function.zip")
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}


resource "aws_cloudwatch_log_group" "lambda_log_group" {
    name      =  "/aws/lambda/myLambdaFunction"
    retenion_in_days = 14
}

