resource "aws_default_security_group" "default-sg" {
    vpc_id = var.vpc_id

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
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

}


resource "aws_key_pair" "ssh-key"{
    key_name = "givanov-pem-key"
    public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone
    
//Define true to be able to ssh and key_name from aws console
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("entry-script.sh")

    //PROVISIONER ARE NOT RECCOMENDENT (LAST RESORT)
    //Defines connection for provisioner
    /*connection {
      type = "ssh"
      host = self.public_ip
      user = "ec2-user"
      private_key = file(var.private_key_location)
    }

    /*provisioner "file" {
      source = "entry-script.sh"
      destination = "/home/ec2-user/entry-script-on-ec2.sh"
    }

    provisioner "remote-exec" {
      script = file("entry-script-on-ec2.sh")
    }

    provisioner "local-exec" {
      command = "echo ${self.public_ip} > output.txt"
    }*/

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