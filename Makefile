clean:
	rm -rf trigger trigger.zip
	rm -rf __pycache__

docker-build:
	docker-compose build

docker-run:
	docker-compose run lambda src.trigger.trigger_func

build-trigger-package: clean
	mkdir trigger
	cp -r src trigger/.
	cd trigger; zip -9qr trigger.zip .
	cp trigger/trigger.zip .
	rm -rf trigger

BUCKET_NAME=<버켓 네임>
PROFILE=<프로필>

make-trigger-s3-upload: build-trigger-package
	aws s3 cp trigger.zip s3://${BUCKET_NAME} --profile=${PROFILE}