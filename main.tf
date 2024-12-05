resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
  
}
resource "aws_subnet" "mysubnet1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  
}
resource "aws_subnet" "mysubnet2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
}
resource "aws_route_table_association" "rta1" {
  subnet_id = aws_subnet.mysubnet1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id = aws_subnet.mysubnet2.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.myvpc.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_s3_bucket" "myrohanbucket" {
  bucket = "myrohanbucket"
}

resource "aws_s3_bucket_public_access_block" "myrohanbucket" {
  bucket = aws_s3_bucket.myrohanbucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "myrohanbucket" {
  bucket = aws_s3_bucket.myrohanbucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicRead",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.myrohanbucket.arn}/*"
      }
    ]
  })
}

resource "aws_instance" "web" {
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id = aws_subnet.mysubnet1.id

}
resource "aws_instance" "web1" {
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id = aws_subnet.mysubnet2.id

}



    