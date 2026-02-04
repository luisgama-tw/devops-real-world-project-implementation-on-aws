resource "aws_key_pair" "ec2_key" {
  key_name   = "devops-course-key"
  public_key = file("~/.ssh/aws-ec2.pub")
}
