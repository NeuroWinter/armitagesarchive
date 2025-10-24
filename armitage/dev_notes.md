## How to deploy to prod
```
rsync -avz --delete \
  --exclude='_build' \
  --exclude='deps' \
  --exclude='.git' \
  ./ \
  user@prod-server:/mnt/user/appdata/armitage-archive/

# Then on prod
ssh user@prod-server
cd /mnt/user/appdata/armitage-archive
docker compose up -d --build
docker logs -f armitage-archive-app-1
```

### How to run release commands in prod:
```
docker exec -it armitage-archive-app-1 bin/armitage rpc Armitage.Release.FUNC_HERE
```
eg:
```
docker exec -it armitage-archive-app-1 bin/armitage rpc Armitage.Release.sync_new_data
docker exec -it armitage-archive-app-1 bin/armitage rpc Armitage.Release.generate_highlight_images
```

## How to run things in dev:

```
docker compose -f docker-compose.dev.yml exec app iex -S mix
iex> funcions here
```


