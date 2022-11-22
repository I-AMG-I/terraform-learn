provider "aws"{
    region = "us-east-1"
    profile = "free"
}



resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc" 
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
   tags = {
        Name: "${var.env_prefix}-subnet-1"
   } 
}

//custom route table
/*resource "aws_route_table" "mypp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id


    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }

} */

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

//association for the custom route table to the vpc
/*resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.mypp-route-table.id
}*/

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

}

//Check if the filter fetch the correct aws instance
//test it before the resource "aws_instance" "myapp-server"
/*output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}*/
output "aws_ami_id" {
    value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key"{
    key_name = "givanov-pem-key"
    public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone
    
//Define true to be able to ssh and key_name from aws console
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("entry-script.sh")

    tags = {
        Name: "${var.env_prefix}-server"
    }
}

# resource "aws_iam_role" "ec2_role" {
#   name = "${var.env_prefix}-ec2-role"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })

#   tags = {
#         Name: "${var.env_prefix}-ec2-role"
#   }
# }


# resource "aws_iam_role" "example" {
#   name               = "yak_role"
#   assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)

#   inline_policy {
#     name = "my_inline_policy"

#     policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Action   = ["ec2:Describe*"]
#           Effect   = "Allow"
#           Resource = "*"
#         },
#       ]
#     })
#   }

#   inline_policy {
#     name   = "policy-8675309"
#     policy = data.aws_iam_policy_document.inline_policy.json
#   }
# }

# data "aws_iam_policy_document" "inline_policy" {
#   statement {
#     actions   = ["ec2:DescribeAccountAttributes"]
#     resources = ["*"]
#   }
# }