#!/bin/bash
echo "Spoke app resources need to be deployed after Spoke VPC gets deployed"
echo "Terraform cannot determine how many public subnets been deployed in Spoke VPC until the deployment is finished"
echo "Hence the app resource deployment would fail with folowing error: "
echo 'The "for_each" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many instances will be created. To work around this, use the -target argument to first apply only the resources that the for_each depends on.'
echo ""
echo "This script is built to workaround this, and will create the spoke VPC first"
echo "Then .2ndstage file will be copied as .tf file and run terraform apply one more time"
read -n 1 -r -s -p $'Press enter to continue...\n'
echo "Starting first stage apply"
terraform init
terraform apply

if [ $? -ne 0 ]; then
    echo "previous apply failed, exiting"
    exit
fi

if [ -f "app-spoke-load-balancers.tf" ]; then
    echo "app-spoke-load-balancers.tf already exists."
else 
    echo "app-spoke-load-balancers.tf does not exist, copying .2ndstage file as .tf file"
    cp app-spoke-load-balancers.tf.2ndstage app-spoke-load-balancers.tf
fi

if [ -f "app-spoke-instances.tf" ]; then
    echo "app-spoke-instances.tf already exists."
else 
    echo "app-spoke-instances.tf does not exist, copying .2ndstage file as .tf file"
    cp app-spoke-instances.tf.2ndstage app-spoke-instances.tf
fi

echo "Starting second stage apply"
terraform init
terraform apply