# Generate a secure private key
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key locally to connect via SSH
resource "local_file" "private_key_pem" {
  content  = tls_private_key.jenkins_key.private_key_pem
  filename = "${path.module}/jenkins_private_key.pem"

  # Important: Set strict permissions on the key file
  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/jenkins_private_key.pem"
  }
}

# Upload the public key to AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "jenkins-server-key-${terraform.workspace}" # Unique name
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

# Create a security group for Jenkins (unchanged)
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg-terraform"
  description = "Allow SSH and Jenkins Web UI"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-SG-Terraform"
  }
}

# Find the latest Ubuntu AMI (unchanged)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create the Jenkins EC2 instance (Uses the generated key!)
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.generated_key.key_name # Use our new key
  user_data              = file("user_data.sh")

  tags = {
    Name = "Doctorly-Jenkins-Server-Terraform"
  }
  associate_public_ip_address = true
}