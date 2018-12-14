# Provisioning Zuul nodes

In order to provision zuul nodes few steps are required:

  1. Clone the Software Factory config repo `git clone ssh://<username>@softwarefactory-project.io:29418/config` (Note: username represents your SoftwareFactory username)
  2. Clone the Github zuul-config repo `git@github.com:ansible/zuul-config.git`
  3. From within the config folder, retrieve the list of nodepool nodes: `cat /path/to/config/nodepool/ansible.yaml | grep name | tail -n +4 | awk '{print $3}' > /path/to/myinventory`
  4. From within the zuul-config folder, run the following command `ansible-playbook -i /path/to/my/inventory -u <username> -b playbooks/staticnodes/configure.yaml` (Note: username represents the username associated to you private key in GCE -> Metadata -> SSH Keys)

After that all the zuul nodes in our GCP tenant should be updated.
