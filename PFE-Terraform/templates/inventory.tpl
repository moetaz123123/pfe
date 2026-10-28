[master]
%{ for name, ip in masters ~}
${name} ansible_host=${ip} ansible_user=ubuntu
%{ endfor ~}

[workers]
%{ for name, ip in workers ~}
${name} ansible_host=${ip} ansible_user=ubuntu
%{ endfor ~}

[cluster:children]
master
workers

[cluster:vars]
ansible_ssh_private_key_file=/home/ubuntu/.ssh/vm_test.pem
ansible_python_interpreter=/usr/bin/python3


