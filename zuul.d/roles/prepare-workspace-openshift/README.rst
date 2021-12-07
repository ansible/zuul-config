Prepare remote workspaces

This role can be used instead of the `prepare-workspace` role when the
synchronize module doesn't work with kubectl connection. It copies the
prepared source repos to the pods' cwd using the `oc rsync` command.

This role is intended to run once before any other role in a Zuul job.
This role requires the origin-clients to be installed.

**Role Variables**

.. zuul:rolevar:: openshift_pods
   :default: {{ zuul.resources }}

   The dictionary of pod name, pod information to copy the sources to.
