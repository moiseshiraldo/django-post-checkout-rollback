# Post-checkout Django migrations rollback

Git post-checkout script to roll back Django migrations. The script has been created for development purposes, under no circumstances should be used on a production environment.

## Installation & usage

Download the `django-post-checkout-rollback.sh` script (or `south-post-checkout-rollback.sh` for South migrations), copy it to the `.git/hooks/` directory of your Django project and add it to the `.git/hooks/post-checkout` script:

```bash
#!/bin/sh

$GIT_DIR/hooks/django-post-checkout-rollback "$@"
```

Set the `MASTER_BRANCH` variable if you want the script to always roll back migrations to the master branch (recommended).

If you need to skip the rollback process for a particular checkout, set the `SKIP_POST_ROLLBACK` variable when calling the command:

`SKIP_POST_ROLLBACK=1 git checkout some_branch`

## Limitations

*In this house we obey the laws of thermodynamics*. Specially the second one. That means migrations should only move forwards along with the commit history. The script won't work on branches that don't obey this principle (you'll get a warning message). 
