resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "event-processing-api-gateway-${var.env}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "event_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_method" "event_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.event_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "event_post_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_resource.event_resource.id
  http_method          = aws_api_gateway_method.event_post_method.http_method
  type                 = "AWS"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.region}:sqs:path/${var.queue.name}"
  credentials             = aws_iam_role.api_events_resource_role.arn 

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_api_gateway_method_response" "event_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.event_resource.id
  http_method = aws_api_gateway_method.event_post_method.http_method
  status_code = 200
}

resource "aws_api_gateway_integration_response" "event_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.event_resource.id
  http_method = aws_api_gateway_method.event_post_method.http_method
  status_code = aws_api_gateway_method_response.event_post_method_response.status_code

  depends_on = [aws_api_gateway_integration.event_post_integration]
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.event_post_integration]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "prod"
}

resource "aws_iam_role" "api_events_resource_role" {
  name = "api_gateway_sqs-${var.env}"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "apigateway.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "api_events_resource_logs_policy" {
  role       = aws_iam_role.api_events_resource_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_policy" "api_sqs_policy" {
  name        = "api_events_sqs_policy-${var.env}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage",
        ]
        Effect   = "Allow"
        Resource = var.queue.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_events_resource_sqs_policy" {
  role       = aws_iam_role.api_events_resource_role.name
  policy_arn = aws_iam_policy.api_sqs_policy.arn
}
