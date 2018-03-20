#!/bin/bash
cd ~/.ssh
ssh-keygen -t rsa
ssh 192.168.1.11 cat /root/.ssh/id_rsa.pub >> authorized_keys
scp authorized_keys shangtv@120.76.96.73:/home/shangtv/.ssh/authorized_keys