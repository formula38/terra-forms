resource "aws_network_interface" "nic_custom" {
  subnet_id = aws_subnet.public_subnet.id
  private_ip = "10.0.1.50" # within the subnet range
  security_groups = [aws_security_group.sg_custom.id]
}
