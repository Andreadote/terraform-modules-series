
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet" {
  value = ["${aws_subnet.public_subnet}"]

}

output "aws_route_table" {
  value = ["${aws_route_table.rtb_public}"]

}

output "aws_instance_id" {
  value = ["${aws_instance.testinstance.id}"]

}





