variable "instance_type" {
    type = string
    description = "The size of the EC2 instance"
    default = "t2.micro"
    sensitive = false

    validation {
      condition = can(regex("^t2.", var.instance_type))
      error_message = "The instance must be a t2 type EC2 instance"    
    }
}
variable "region" {
    type = string 
    default = "us-east-1
}

variable "availability_zones" {
    type = list  
}
