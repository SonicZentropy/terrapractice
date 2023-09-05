

resource "aws_db_instance" "example" {
  identifier = "zentropy-terraform"
  engine = "postgres"
  allocated_storage = 10
  instance_class = "db.t3.micro"
  skip_final_snapshot = true
  db_name = "doggr"

  username = var.db_username
  password = var.db_password
}