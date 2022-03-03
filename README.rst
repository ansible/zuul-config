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

- Add to `zuul/tenants.yaml <https://github.com/ansible/zuul-config/blob/master/resources/ansible.yaml>`_

note: Follow up to the merge of the PR, Zuul will refresh it's configuration. The job is called `update-config`. For various reason, the update may fail, you can take a look at the previous runs here: https://ansible.softwarefactory-project.io/zuul/builds?job_name=config-update&project=ansible/zuul-config

PR2
---

- Add to `zuul.d/projects.yaml <https://github.com/ansible/zuul-config/blob/master/zuul.d/projects.yaml>`_

Status
======

`CI Dashboard <https://ansible.softwarefactory-project.io/zuul/status>`_

Talk to us
==========

Matrix Chat Room ``https://matrix.to/#/#zuul:ansible.com``
