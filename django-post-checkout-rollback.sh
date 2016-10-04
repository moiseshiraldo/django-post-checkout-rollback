#!/bin/bash
# Roll back migrations from the previous branch.

# Use this variable if you want to roll back migrations to a safe branch
MASTER_BRANCH=""

OLD_BRANCH=$1
NEW_BRANCH=$2
IS_BRANCH_CHANGE=$3

rollback () {
    if [ -z "${current_migrations[$app]}" ] && [ $last_migration -gt 0 ]; then
        python manage.py migrate $app zero
    elif [ ${current_migrations[$app]} -lt $last_migration ]; then
        python manage.py migrate $app ${current_migrations[$app]}
    elif [ ${current_migrations[$app]} -gt $last_migration ]; then
        echo "Warning: the previous branch has missing migrations for" $app
    fi
}

if [ $NEW_BRANCH == $OLD_BRANCH ] || [ -n "$SKIP_POST_ROLLBACK" ]; then
    exit 0
fi

if [ $IS_BRANCH_CHANGE -eq 1 ]; then
    declare -A current_migrations
    new_branch="$(git rev-parse --abbrev-ref HEAD)"
    
    # Checkout master branch
    if [ -n "$MASTER_BRANCH" ] && [ "$new_branch" != "$MASTER_BRANCH" ]; then
        SKIP_POST_ROLLBACK=1 git checkout -q $MASTER_BRANCH
    fi
    migrations="$(python -Wi manage.py showmigrations)"
    # Exit if we could not get migrations
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Get last migration on current branch for every app
    last_migration="0000"
    while read -r line; do
        array=( $line )
        if [ "${array[0]}" == "[X]" ]; then
            last_migration=${array[1]:0:4}
        elif [ "${array[0]}" == "[" ]; then
            continue
        elif [ "${array[0]}" == "(no" ]; then
            continue
        else
            if [ -v app ]; then
                current_migrations[$app]=$last_migration
                last_migration="0000"
            fi
            app=${array[0]}
        fi
    done <<< "$migrations"
    current_migrations[$app]=$last_migration
    
    # Checkout old branch
    SKIP_POST_ROLLBACK=1 git checkout -q -b tmp-south-rollback $OLD_BRANCH
    previous_migrations="$(python -Wi manage.py showmigrations)"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    unset app
    
    # Get old migrations and roll back if necessary
    last_migration="0000"
    while read -r line; do
        array=( $line )
        if [ "${array[0]}" == "[X]" ]; then
            last_migration=${array[1]:0:4}
        elif [ "${array[0]}" == "[" ]; then
            continue
        elif [ "${array[0]}" == "(no" ]; then
            continue
        else
            if [ -v app ]; then
                rollback
                last_migration="0000"
            fi
            app=${array[0]}
        fi
    done <<< "$previous_migrations"
    rollback
    
    # Checkout current branch again
    SKIP_POST_ROLLBACK=1 git checkout -q $new_branch
    git branch -D -q tmp-south-rollback
fi
