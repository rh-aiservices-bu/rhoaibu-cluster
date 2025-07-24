## RHOAI Instance

This folder controls using GitOps the RHOAI instance, with Kustomization files, base and overlays.

* [Base](base): Contains the base resources for the RHOAI instance.
  * [Accelerator Profiles](base/accelerator-profile.yaml): Contains the basic accelerator profiles for the RHOAI instance.
  * [DataScienceCluster](base/datasciencecluster.yaml): Contains the basic data science cluster for the RHOAI instance.
  * [Notebook-Controller-Culler-Config-CM](base/notebook-controller-culler-config-cm.yaml): Contains the idle stop Jupyter Notebooks Configuration for the RHOAI instance.
  * [ODH Dashboard Config](base/odh-dashboard-config.yaml): Contains the ODH Dashboard Configuration for the RHOAI instance.
* [Components](components): Contains the components for the RHOAI instance.
  * [Accelerator Profiles](components/accelerator-profiles): Contains the custom accelerator profiles for the RHOAI instance.
  * [Codeflare](components/codeflare): Contains the Distributed Workload (based in Codeflare/Kueue/) components for the RHOAI instance.
  * [Custom Workbenches](components/custom-workbenches/): Contains Image Stream definitions of custom workbenches for the RHOAI instance.
  * [Model Registry](components/model-registry)L Contains a Model Registry definition with MySQL DB, and necessary RBAC for everybody to use it. 
* [Overlays](overlays): Contains the overlays for the RHOAI instance.