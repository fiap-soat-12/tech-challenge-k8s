# resource "aws_apigatewayv2_vpc_link" "example_vpc_link" {
#   name = "techchallenge-vpc-link"

#   subnet_ids = [for subnet in data.aws_subnet.selected_private_subnets : subnet.id]
#   security_group_ids = [
#     aws_security_group.alb_sg.id
#   ]
# }