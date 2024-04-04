resource "aws_route_table_association" "rt_custom_internet_association" {
  route_table_id = aws_route_table.rt_custom_internet.id
  subnet_id = aws_subnet.public_subnet.id
}
