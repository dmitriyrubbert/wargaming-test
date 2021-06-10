#----------------------------------------------------------
# 1 VPC
# XX Subnets
# 1 Internet Gateway
# 1 Route Table
# 2 Security Group (web,ssh)
# XX EC2 Instances
# 
# Made by Dmitriy Lazarev cold summer in 2021
#----------------------------------------------------------

#===============================================


# --------------- VPS --------------------------
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = merge(var.common_tags, { Name = "${var.env}-vpc" })
}

# ----------------- Subnet ----------------
resource "aws_subnet" "public_subnets" {
  count                   = length(var.vpc_public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.vpc_public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, { Name = "${var.env}-public-${count.index + 1}" })
}

#-------------- Gateway --------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${var.env}-igw" })
}

# ----------------- Route table ----------
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.common_tags, { Name = "${var.env}-route-public-subnets" })
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}


#============================================================


# ---------------- Security group ---------------
resource "aws_security_group" "web" {
  name   = "WebServer Security Group"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allow_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.env}-security-group-web" })
}

resource "aws_security_group" "ssh" {
  name   = "SSH Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.env}-security-group-ssh" })
}

# ---------------- EC2 instance ---------------
data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  count                  = var.default_instance_count
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.default_instance_type
  vpc_security_group_ids = [aws_security_group.web.id, aws_security_group.ssh.id]
  subnet_id              = element(aws_subnet.public_subnets[*].id, count.index)
  key_name               = var.default_key
  tags                   = merge(var.common_tags, { Name = "${var.env}-webserver" })
}

#===============================================
