//  Create a role which OpenShift instances will assume.
//  This role has a policy saying it can be assumed by ec2
//  instances.
resource "aws_iam_role" "sts-instance-role" {
  name = "${var.prefix}sts-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = var.common-tags
}

//  This policy allows an instance to forward logs to CloudWatch, and
//  create the Log Stream or Log Group if it doesn't exist.
resource "aws_iam_policy" "application-policy-forward-logs" {
  name        = "${var.prefix}${var.name}-instance-forward-logs"
  path        = "/"
  description = "Allows an instance to forward logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

//  Attach the policies to the roles.
resource "aws_iam_policy_attachment" "application-attachment-forward-logs" {
  name       = "${var.prefix}${var.name}-attachment-forward-logs"
  roles      = [aws_iam_role.sts-instance-role.name]
  policy_arn = aws_iam_policy.application-policy-forward-logs.arn
}

//  Create a instance profile for the role.
resource "aws_iam_instance_profile" "sts-instance-profile" {
  name  = "${var.prefix}sts-instance-profile"
  role = "${aws_iam_role.sts-instance-role.name}"
}

//  Create a user and access key for application-only permissions
resource "aws_iam_user" "application-aws-user" {
  name = "${var.prefix}${var.name}-aws-user"
  path = "/"

  tags = var.common-tags
}

//  Policy taken from https://github.com/openshift/openshift-ansible-contrib/blob/9a6a546581983ee0236f621ae8984aa9dfea8b6e/reference-architecture/aws-ansible/playbooks/roles/cloudformation-infra/files/greenfield.json.j2#L844
resource "aws_iam_user_policy" "application-aws-user" {
  name = "${var.prefix}${var.name}-aws-user-policy"
  user = aws_iam_user.application-aws-user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVolume*",
        "ec2:CreateVolume",
        "ec2:CreateTags",
        "ec2:DescribeInstance*",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DeleteVolume",
        "ec2:DescribeSubnets",
        "ec2:CreateSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeRouteTables",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:DescribeLoadBalancerAttributes"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "application-aws-user" {
  user    = aws_iam_user.application-aws-user.name
}
