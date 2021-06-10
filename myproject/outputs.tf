output "instance_ids" {
  value = join(",", aws_instance.web.*.id)
}

output "instance_public_azs" {
  value = join(",", aws_instance.web.*.availability_zone)
}

output "instance_public_ips" {
  value = join(",", aws_instance.web.*.public_ip)
}
