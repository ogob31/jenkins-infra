output "jenkins_public_ip" {
  description = "The public IP address to access the Jenkins server."
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "The public DNS name of the Jenkins server."
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "The URL to access the Jenkins web UI."
  value       = "http://${aws_instance.jenkins.public_dns}:8080"
}

output "ssh_private_key_file" {
  description = "The path to the generated private key file for SSH access."
  value       = local_file.private_key_pem.filename
}

output "ssh_command" {
  description = "The command to SSH into the Jenkins server."
  value       = "ssh -i ${local_file.private_key_pem.filename} ubuntu@${aws_instance.jenkins.public_ip}"
}