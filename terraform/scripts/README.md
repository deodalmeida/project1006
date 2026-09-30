# User-data assignment

Create `user_data.sh.tftpl` yourself as part of **Task 6**.

Your script/template should bootstrap a fresh Amazon Linux 2023 instance so that it can serve the provided Flask application on port `8000` without manual SSH configuration.

It should fail loudly when bootstrap steps fail, avoid embedding secrets, and retrieve required database credentials at runtime using the EC2 IAM role.

Before writing it, answer: **What must a brand-new EC2 instance know or retrieve to become a healthy ALB target automatically?**
