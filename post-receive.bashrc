#!/bin/bash

# you might want to change these variables to fit your environment
# DJANGO_PROJECT default value will be changed with djangoAuto script when setting up the project
PROJECT_NAME=$(basename "$PWD")
TARGET_BRANCH="master"
GIT_DIR=/srv/git/$PROJECT_NAME
GIT_REPO=$PROJECT_NAME
DJANGO_PROJECT="default"
GIT_WORK_DIR=/var/pysites/$PROJECT_NAME/$GIT_REPO
VENV_DIR=/var/pysites/$PROJECT_NAME/venv
DJANGO_SETTINGS_MODULE="$DJANGO_PROJECT.settings.production"

while read oldrev newrev ref
do
        if [[ $ref =~ .*/$TARGET_BRANCH$ ]];
        then

                if [ ! -d "$GIT_WORK_DIR" ]; then
                        echo "Creating working directory $GIT_WORK_DIR"
                        mkdir -p $GIT_WORK_DIR
                fi

                if [ ! -d "$VENV_DIR" ]; then
                        echo "Creating virtual env $VENV_DIR"
                        python3 -m venv $VENV_DIR
                        source $VENV_DIR/bin/activate
                        pip install --upgrade pip
                        # python /var/pysites/$PROJECT_NAME/get-pip.py
                        deactivate
                fi

                git --work-tree=$GIT_WORK_DIR --git-dir=$GIT_DIR checkout -f
                
                # move local_settings.py to the right directory
                if [ -f /var/pysites/$PROJECT_NAME/local_settings.py]; then
                        mv /var/pysites/$PROJECT_NAME/local_settings.py $GIT_WORK_DIR/$DJANGO_PROJECT/settings/local_settings.py
                fi

                cd $GIT_WORK_DIR
                source $VENV_DIR/bin/activate

                if [ -f "$GIT_WORK_DIR/requirements.txt" ]; then
                        echo "Installing dependencies"
                        pip install --upgrade pip
                        pip install --upgrade setuptools
                        pip install -r $GIT_WORK_DIR/requirements.txt
                fi

                echo "Starting database migration"
                python manage.py migrate

                echo "Collecting static files"
                rm -rf /srv/media/$PROJECT_NAME/staticcollected
                python manage.py collectstatic --noinput


                echo "Reloading uWSGI"
                touch $GIT_WORK_DIR/$DJANGO_PROJECT/wsgi.py
        else
                echo "Ref $ref successfully received.  Doing nothing: only the $TARGET_BRANCH branch may be deployed on this server."
        fi
done
