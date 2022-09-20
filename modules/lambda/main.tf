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

data "archive_file" "lambda_with_dependencies" {
  type        = "zip"
  source_dir = "${path.module}/src"
  output_path = "${path.module}/dist/files/events-processing.zip"
}

resource "aws_lambda_function" "events_processing" {
  filename      = data.archive_file.lambda_with_dependencies.output_path
  function_name = "events-processing"
  role          = aws_iam_role.events_processing.arn
  handler       = "index.handler"
  source_code_hash = data.archive_file.lambda_with_dependencies.output_base64sha256

  runtime = "nodejs16.x"
}
