## RStudio Server

By default the RStudio Server image is not included in OpenShift AI out of the box. You need to Build the image for RStudio Server and CUDA - RStudio Server custom images as is described [here](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2-latest/html/getting_started_with_red_hat_openshift_ai_self-managed/creating-a-workbench-select-ide_get-started#building-the-rstudio-server-workbench-images_get-started)

Enabled both in Dev and Prod clusters but **NOT** managed through GitOps