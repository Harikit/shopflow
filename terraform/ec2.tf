# -----------------------------
# Get latest Amazon Linux 2023 AMI
# -----------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------
# Create EC2 Key Pair
# -----------------------------
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))

  tags = {
    Name = "${var.project_name}-${var.environment}-key"
  }
}
# -----------------------------
# EC2 Instance
# -----------------------------
resource "aws_instance" "k3s" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name               = aws_key_pair.main.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-${var.environment}-k3s"
  }
}