resource "aws_instance" "home_hardware" {
  ami           = data.aws_ami.amzlinux2.id
  instance_type = "t2.micro"
  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_tokens = "required"
  }
}

