# ansible-collection-devenv

Clone the project into
`ansible-collection-devenv/ansible_collections/avinode/devenv`.  *Ansible*
collections need to exist in a spcific directory structure while working on
them:

```bash
git clone git@github.com:Avinode/ansible-collection-devenv.git \
    ansible-collection-devenv/ansible_collections/avinode/devenv
```
    

The set up the project environment:

```bash
cd ansible-collection-devenv/ansible_collections/avinode/devenv
./scripts/setup-local-ansible.sh
```

Run tests:

```bash
cd ansible-collection-devenv/ansible_collections/avinode/devenv

ansible-test sanity --docker default \
    --exclude scripts/setup-local-ansible.sh \
    --exclude scripts/setup-macports.sh \
    --exclude .gitignore

ansible-test units --docker default

ansible-test integration --docker ubuntu2004 \
    --python-interpreter /usr/bin/python3

ansible-test integration \
    --docker geerlingguy/docker-debian10-ansible:latest \
    --python-interpreter /usr/bin/python3
```
