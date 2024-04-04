resource "aws_eip" "eip_custom" {
  vpc = true
  network_interface = aws_network_interface.nic_custom.id
  associate_with_private_ip = "10.0.0.10"
  depends_on = [aws_internet_gateway.ig_custom]
}
