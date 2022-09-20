resource "aws_iam_role" "events_processing" {
  name = "events-processing-${var.env}"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "basic_lambda" {
  role       = aws_iam_role.events_processing.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "sqs" {
  name = "events-processing-lambda-sqs-${var.env}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:*"
        ]
        Effect   = "Allow"
        Resource = var.queue.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sqs" {
  role       = aws_iam_role.events_processing.name
  policy_arn = aws_iam_policy.sqs.arn
}

data "archive_file" "lambda_with_dependencies" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/dist/files/events-processing.zip"
}

resource "aws_lambda_function" "events_processing" {
  filename         = data.archive_file.lambda_with_dependencies.output_path
  function_name    = "events-processing-${var.env}"
  role             = aws_iam_role.events_processing.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_with_dependencies.output_base64sha256

  runtime = "nodejs16.x"
}

resource "aws_lambda_permission" "allows_sqs_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.events_processing.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.queue.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  batch_size       = 1
  event_source_arn = var.queue.arn
  enabled          = true
  function_name    = aws_lambda_function.events_processing.arn
}
