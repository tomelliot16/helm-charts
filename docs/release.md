# Releasing new version of Stormforge

Documentation for when Stormforge team releases a new version of their application images
or a new version of the chart that resided at the root of this repository.

The release process mentioned below should be followed for the release.
All changes should be made in a branch and presented to the team for review and approval.


  - [Configure the new image version and deploy to dev](#configure-the-new-image-version-and-deploy-to-dev)
  - [Create a new Tag on the main branch](#create-a-new-tag-on-the-main-branch)
  - [Upgrade qa, staging and prod environments to the new tag.](#upgrade-qa-staging-and-prod-environments-to-the-new-tag)
  - [Process to Create Clusters Token using stormforge CLI](#process-to-create-clusters-token-using-stormforge-cli)


## Configure the new image version and deploy to dev

1. Create a ticket in JIRA for the release and create a Pull Request
   in this repo from the main branch with the ticket number.

2. Update the file `.acquia/pipeline.env` with the new versions information.
   
   Following examples use stormforge version `v1.1.0`.
   ```yaml
   CONTROLLER_VERSION=0.0.21-rc4
   TSDB_VERSION=0.0.14-rc1
   APPLIER_VERSION=0.0.8-rc5
   RECOMMENDER_VERSION=0.3.4-rc4
   GRAFANA_VERSION=9.2.1
   ```

3. Uncomment the `clusterOverrides` section for `dev` with your PR branch name in `.acquia/platform.yaml`:

   ```yaml
          clusterOverrides:
            - selectorLabels:
              - key: name
                value: csd-hades82db9
              targetRevision: MY-PR-BRANCH
              valuesFiles:
                - values.yaml
   ```
   
   In the same way update the `charts/optimize-live/values-dev.yaml`
   files with the new tag:
      
   ```                                                                                                                                                              
   chart-version: &dev-version MY-PR-BRANCH
   ```
   
   Note: Clusters csd-hades82db9 or ngcweb-tests-ogre3ff8d9 can be used for tests.
   **Do not use clusters: electro, loki, or uguisud in pull requests.**
   
4. Commit the above changes to the remote repository and monitor the [jenkins job](https://core.cloudbees.ais.acquia.io/devops-pipeline-2-jenkins/job/DEVOPS-sre-stormforge-PIPELINE)
   that runs for this branch. Make sure from the console logs in this job that the new stormforge image
   version is downloaded successfully.
   
   Once the above job has run successfully create a PR out of this branch to the master branch. This 
   should trigger a new [pull request job run](https://core.cloudbees.ais.acquia.io/devops-pipeline-2-jenkins/job/DEVOPS-sre-stormforge-PIPELINE/view/change-requests/) 
   for the PR and deploy to the PR number specific environment. Ensure that the stormforge app is running properly in the corresponding `dev` environment. 

   Update the PR details in github with the above job link for team to review while approving the PR.
   
   Before merging the PR to main branch revert the comment section in the `platform.yaml` file.

   ```yaml
          # clusterOverrides:
          #   - selectorLabels:
          #     - key: name
          #       value: csd-hades82db9
          #     targetRevision: MY-PR-BRANCH
          #     valuesFiles:
          #       - values.yaml
   ```

   Now the PR can be merged to the main branch before proceeding further. Make sure to rebase this branch from main and use 
   `Squash and Merge` to do the merge.

## Create a new Tag on the main branch

A new tag should now be created for the commit made to the main branch in the above step. For this
go to [release](https://github.com/acquia/sre-stormforge/releases) and click on `Draft a new release`.
Click on `Choose a tag` and create the new tag e.g. `v1.1.0`, make sure the `Target` is selected as 
`main`. Choose a release title according to one of the previous titles updating the version number
in it e.g. `Release v1.1.0 [Stormforge controller 0.0.21-rc4]`. Click on `Generate release notes` and then click `Publish release` button
at the bottom.

The tag creation above should trigger a tag based [jenkins job](https://core.cloudbees.ais.acquia.io/devops-pipeline-2-jenkins/job/DEVOPS-sre-stormforge-PIPELINE/view/tags/). 
Make sure this job succeeds before proceeding further. The job will create the image tags which will
eventually be used in updating the qa, staging and prod environments in the steps below.

## Upgrade qa, staging and prod environments to the new tag.

Create another PR to the main branch this time updating the version in `platform.yaml` for the qa,staging and prod environments. If
using the same branch as before then make sure to rebase the branch from main before making this change and raising the
PR. Merge this PR to the main branch after all approvals. Make sure to use `Squash and Merge` to do the merge.

Eg.

   ```yaml
   - name: qa
     overrides:
       standard:
         values:
           valueFiles:
             - values.yaml
           targetRevision: v1.1.0
   ```

   ```yaml
   - name: staging
     overrides:
       standard:
         values:
           valueFiles:
             - values.yaml
           targetRevision: v1.1.0
   ```   

   ```yaml
   - name: prod
     overrides:
       standard:
         values:
           valueFiles:
             - values.yaml
           targetRevision: v1.1.0
   ```

In the same way update the `charts/optimize-live/values-[qa|staging|prod].yaml` files with the new tag:

   ```
   chart-version: &[qa|staging|prod]-version v1.1.0 

   ```

Ensure that the stormforge app is deployed and running properly in the corresponding `qa`, `staging` and `prod` environments. 

Next, close the release ticket in JIRA.

## Process to Create Clusters Token using stormforge CLI

In case there is a deployment to new clusters there is a need to
generate a new cluster token for each new cluster using the stormforge cli:

   ```
   $ stormforge create cluster <cluster-name> > token.yaml
   ```

The token should be added to the a cluster named key in AWS Secret Manager
in the respective AWS account:
    
   ```
   platform/sre/<cluster-name>-stormforge-<env>
   ```

Eg. `platform/sre/csp-hermes2322-stormforge-staging`


Input the values of secret:

   ```
   STORMFORGE_AUTHORIZATION_CLIENT_ID:	<CLIENT_ID> [From token.yaml]
   STORMFORGE_AUTHORIZATION_CLIENT_SECRET:	<CLIENT_SECRET> [From token.yaml]
   STORMFORGE_SERVER_ISSUER:	https://api.stormforge.io/
   STORMFORGE_SERVER_IDENTIFIER:	https://api.stormforge.io/
   ```

The deployments sync can be confirmed if green in 
[ArgoCd Dev](https://argocd.dev.cloudservices.acquia.io/applications/?labels=app%253Dstormforge)
and in [ArgoCD Prod](https://argocd.cloudservices.acquia.io/applications/?labels=app%253Dstormforge).
