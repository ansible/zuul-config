zuul-config
==============

This repo contains the configuration of the `Ansible Content CI https://ansible.softwarefactory-project.io/zuul/status`.

Zuul
====

This directory contains the list of projects that are enabled. Edit
these files to add, remove or rename a project in Zuul.

On-board new repo into Zuul
===========================

To add new repos into Zuul, it's a two step process:

Enable the Github Application
=============================

First, you **MUST** enable the `softwarefactory-project-zuul https://github.com/apps/softwarefactory-project-zuul/` application in your Github project.
If the project is in the `ansible-collections/ https://github.com/ansible-collections` namespace, you don't have to do anything. 

PR1
---

- Add to `resources/ansible.yaml <https://github.com/ansible/zuul-config/blob/master/resources/ansible.yaml>`_

note: Follow up to the merge of the PR, Zuul will refresh its configuration. The job is called `update-config`. For various reason, the update may fail, you can take a look at the previous runs here: https://ansible.softwarefactory-project.io/zuul/builds?job_name=config-update&project=ansible/zuul-config

PR2
---

- Add to `zuul.d/projects.yaml <https://github.com/ansible/zuul-config/blob/master/zuul.d/projects.yaml>`_

note: You don't need to do it if the project satisfies the rules specified in the file. For example, `rule 1 <https://github.com/ansible/zuul-config/blob/master/zuul.d/projects.yaml#L4-L6>`_ and `rule 2 <https://github.com/ansible/zuul-config/blob/master/zuul.d/projects.yaml#L20-L23>`_ say that if a collection's repository name starts with ansible-collections/community* or sap-linux/community* and the repository has the `main` branch as default, the repository will be included in the project and published by Zuul on Galaxy automatically when a git tag is created in the collection's repo. In this case, only PR1 above is required.

Status
======

`CI Dashboard <https://ansible.softwarefactory-project.io/zuul/status>`_

Talk to us
==========

Matrix Chat Room ``https://matrix.to/#/#zuul:ansible.com``
