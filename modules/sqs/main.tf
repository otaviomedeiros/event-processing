resource "aws_sqs_queue" "queue" {
  name = "event-processing-queue-${var.env}"
}