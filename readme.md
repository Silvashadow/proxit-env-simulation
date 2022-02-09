# Terraform Init 

- Open the main terraform folder in the VSCode and in the root directory [ which contains other directories like modules, template etc. ] type the command given below for terraform initialization:

--->  terraform init

-------------------------------

# Terraform Workspace

- Once terraform is initialized, run the command below to create a separate workspace to specifically identify your infra deployed on AWS Cloud and also to deploy multiple AZ's if needed:

--->   terraform workspace new s201-aws-app

--------------------------------

# Terraform Apply

- Once terraform is initialized, run the command below to see which resources would get deployed if terraform script runs successfully:

--->   terraform plan -var-file=./SpecEnv/prod.tfvars 

- To deploy infrastructure, run the  command below in in root folder

--->   terraform apply -var-file=./SpecEnv/prod.tfvars 

### Note: Remember to run above command in /terraform_infra_1 folder , Else it will give ERROR due to File Location Issue.

- After the command starts to run, terraform will show resources being made and will ask permission from you to build up resources.
Type --> yes <-- and aws infrastructure will start to build up and get deployed

----------------------------------

# Terraform Destroy

- If you want to destroy the terraform, type the command below:

---> terraform destroy -var-file=./SpecEnv/prod.tfvars 
