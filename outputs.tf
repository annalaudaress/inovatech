output "instance_ip" {
  description = "IP da instância EC2"
  value       = aws_instance.gitlab_runner.public_ip
}
