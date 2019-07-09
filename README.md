# mxdbmainte
## Usage
docker run \
-e "POSTGRES_HOST=192.168.0.1" \
-e "POSTGRES_DB=synapse" \
-e "PGPASSWORD=v3rys#curep@ssw0rd" \
-e "POSTGRES_USER=synapse" \
-e "DOMAIN=syapse.matrix.org" \
-e "ADMIN=root" \
-e 'ROOMS_ARRAY=!DgvjtOljKujDBrxyHk:matrix.org' \
-e "TIME=1 day ago" \
mchus/matrix-synapse-cleanup
