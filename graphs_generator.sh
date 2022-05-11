#Array of folders to clean
dir_array=(
"terraform/aws-eks-demo/"
"terraform/aws-eks-persistent/"
)
for d in "${dir_array[@]}";do
cd $d
terraform init
terraform graph -type=plan | dot -Tpng > graph.png
cd "-"
done