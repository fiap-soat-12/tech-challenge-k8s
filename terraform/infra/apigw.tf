# resource "aws_apigatewayv2_api" "example_api" {
#   name          = "example-api"
#   protocol_type = "HTTP"
# }

# resource "aws_apigatewayv2_integration" "example_integration" {
#   api_id             = aws_apigatewayv2_api.example_api.id
#   integration_type   = "HTTP_PROXY"
#   integration_uri    = aws_lb_listener.http_listener.arn
#   connection_type    = "VPC_LINK"
#   connection_id      = aws_apigatewayv2_vpc_link.example_vpc_link.id
#   integration_method = "ANY"
# }

# resource "aws_apigatewayv2_route" "example_route" {
#   api_id    = aws_apigatewayv2_api.example_api.id
#   route_key = "GET /"

#   target = "integrations/${aws_apigatewayv2_integration.example_integration.id}"
# }

# resource "aws_apigatewayv2_stage" "example_stage" {
#   api_id      = aws_apigatewayv2_api.example_api.id
#   name        = "dev"
#   auto_deploy = true
# }
