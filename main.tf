# Providenciador AWS
provider "aws" {
  region = "us-east-1"  # Substitua pela região desejada
}

# Criando uma chave SSH para acessar a instância EC2
resource "aws_key_pair" "ec2_key" {
  key_name   = "gitlab-pipeline-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Substitua pelo caminho do seu arquivo de chave pública
}

# Criando uma security group para a instância EC2
resource "aws_security_group" "ec2_sg" {
  name_prefix = "gitlab-pipeline-sg"
  description = "Security group for EC2 instance"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite acesso SSH de qualquer IP
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego HTTP
  }
}

# Criando a instância EC2
resource "aws_instance" "gitlab_runner" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Substitua pela AMI do Ubuntu na sua região
  instance_type           = "t2.medium"
  key_name                = aws_key_pair.ec2_key.key_name
  security_groups         = [aws_security_group.ec2_sg.name]
  associate_public_ip_address = true
  tags = {
    Name = "GitLab-Runner"
  }

  # Instalando Docker, GitLab Runner e dependências
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash",
      "sudo apt-get install -y gitlab-ci-multi-runner",
      "sudo gitlab-ci-multi-runner register --url https://gitlab.com/ --registration-token ${var.gitlab_registration_token} --executor docker --docker-image docker:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock --description 'docker-runner' --tag-list 'small-runner' --run-untagged --locked=false",
      "sudo gitlab-ci-multi-runner start"
    ]
  }

  tags = {
    Name = "GitLab-Runner"
  }
}
