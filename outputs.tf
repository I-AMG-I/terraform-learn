//Check if the filter fetch the correct aws instance
//test it before the resource "aws_instance" "myapp-server"
# output "aws_ami_id" {
#     value = data.aws_ami.latest-amazon-linux-image.id
# }
output "ec2_public_ip" {
    value = module.myapp-server.instance.public_ip
}