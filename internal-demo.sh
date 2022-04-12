export RG="album-app-internal"
export LOCATION="eastus"
export SUB_ID="a3e34e6c-4019-4f37-b81d-addaf23b5080"

# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzNV90HrayM/+plgz0qwmyaCzLKxbIZsapiPOnL1vqzEIico8aKwYRTONREIBddI94EyEQj7MkyCm9hfXcvURWu16wq7KhDeSPcLx287bDP7v5FDgpMl45G7sQfC88AbtmTP9b1CNDLUL7KZL5MdrCRnHWvHacfVSkOfHENHLFHZeJfh+lRok90Tg5SI1D4YY+3qyuU5FXCEGxmq8d8LbcBjKV4knGlT++FtclysdF/hYvq9CSrJ1eGdtr/cTf6s2HCILFc3pDhtlTf/FVM+0IAZWowJe4JWBWIR6h7am/7DUsa++ttasTHGdkQskdoPRehzoZ04JN8hPiH+t0eY7XxLDhds1mSTMujEskHvI1C/yI99lBzqX/1CGw8/vT2Wbd/LQjxFU2sbZt8VkMLqNtTuUZ+iPUF3Jy6Gtfxmo/szBq+khaMCcnRYUyvnS61kcb1ug+i+b7X0Hz323naHiEUz3reXYSMKIswwTnvVhJVQXdcbSKC82iyMxp4nnF9WPbwSH02Iu+Ntkoo8JI+wdrhSdWP8/qSdZU85Sy+N28A+lr8FET2y+3t8rYevsDNISdBNNLiv3byTNzvYTf8ZSdKZV7LVihsRuotTZMVIhyY8ApvosKk9UxgQMEJUIAMCHopBn5Zimk41lk7+5giXi5/T3NdfHczEdYbNVvhKXr0Q== kendallroden@Kendalls-MBP.lan

# # Follow Azure CLI prompts to authenticate to your subscription of choice
# az login
# az account set --subscription $SUB_ID

# Create resource group
az group create -n $RG -l $LOCATION

# Deploy all infrastructure and reddog apps
az deployment group create -n $RG -g $RG -f ./deploy/bicep-internal/main.bicep

# Show outputs for bicep deployment
az deployment group show -n $RG -g $RG -o json --query properties.outputs.urls.value