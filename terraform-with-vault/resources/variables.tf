
#variable "public_subnet" {
#description = "List of public subnet CIDR blocks"
#default = "10.0.1.0/24"
#}

variable "instance_ami" {
  description = "AMI for aws instance"
  default     = "ami-03a6eaae9938c858c"
}

variable "instance_type" {
  description = "type for EC2 instance"
  default     = "t2.micro"
}

variable "enviroment_tag" {
  description = "Enviroment tag"
  default     = "production"
}


variable "region" {
  default = "us-west-2"
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "azs" {
  description = "List of availability zones"
  type        = string
  default     = "us-west-2a"
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuJ40R+zUKzZvkuiob4gnWHjZW/keEjmCRtm5cHybddA5x72Eh3tNCfq51eKfa2wsUJ3Xx2gH5iC3LWRECchWDICAp2M95/EQwWS3H2QJB+AD89hiYerurZNShyLPQsDVqCp9cRxcq6Gar4DaH8OsgGt0/Vs+v4m4iFIZwoH+ed0alACmQMShDfS0PmCTqAOYeNV0EEryO48tHU6N9weetRuLBA6t6xWz5D0OzJ1IpI+muz9MYOIYiFDg55lzUPR06gxtpUuY8HLr/bNwd3tWD/1pS3BowZpBz+F6/jGsrei3jchSks/vR6UN9pYkwyBS824drx1xEKEM9mlef2wHx0IlUrb0pFkY9RHAqxH/yaIl2elre7mTDSJydGncu1XYoqWeTClMvtwztbrtkn8tZQEWqXG78Cm4cHuN8By3Mn0G6DZATWy1o/XFdD1xk9whYY2pIWaNAV0JEFjGRCjYgnQPls5g7R4SP2XH+iGj28AGJEGIRYPFX119T0kcOEJU= Andre@MacBook-Pro.local"
}


