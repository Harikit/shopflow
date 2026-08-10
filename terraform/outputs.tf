output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.k3s.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.k3s.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.k3s.public_dns
}