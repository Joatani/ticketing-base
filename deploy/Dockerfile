# Stock OpenProject release plus only the files dev changed since that release.
# Built by deploy/vm-deploy.sh, which fills overlay/ and deleted.txt.
ARG BASE_TAG
FROM openproject/openproject:${BASE_TAG}

COPY --chown=app:app overlay/ /app/
COPY deleted.txt /tmp/deleted.txt
RUN cd /app && xargs -r -d '\n' rm -f < /tmp/deleted.txt && rm /tmp/deleted.txt
