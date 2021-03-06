###
#
##

START := mvn clean spring-boot:run

LAB_DIRECTORY = apps-spring-cloud-services-labs
CONFIG_SERVER = $(LAB_DIRECTORY)/config-server
SERVICE_REGISTRY = $(LAB_DIRECTORY)/service-registry
FORTUNE_SERVICE = $(LAB_DIRECTORY)/fortune-service
GREETING_SERVICE = $(LAB_DIRECTORY)/greeting-service

APP_FORTUNE_SERVICE = fortune-service
APP_GREETING_SERVICE = greeting-service
APP_CONFIG_SERVER = config-server
APP_SERVICE_REGISTRY = service-registry

define assertIsStarted =
	until [ $$(cf services | awk '{ if ($$1 == "$(1)") { print $$6; } }') == "started" ]; do sleep 2; done
endef

getGreetingUrl := cf apps | awk '{ if ($$1 == "$(APP_GREETING_SERVICE)") { print $$6; } }'
getFortuneUrl := cf apps | awk '{ if ($$1 == "$(APP_FORTUNE_SERVICE)") { print $$6; } }'

.PHONY: *

# TODO - How to run multiple maven processes in foreground simultaneously
start:
	cd $(PWD)/$(CONFIG_SERVER) && $(START) & cd $(PWD)/$(SERVICE_REGISTRY) && $(START) & cd $(PWD)/$(FORTUNE_SERVICE) && $(START) & cd $(PWD)/$(GREETING_SERVICE) && $(START) && fg && fg && fg && fg
# start

deploy: deploy_service_registry deploy_config_server deploy_fortune_service deploy_greeting_service
# deploy

deploy_fortune_service:
	cd $(FORTUNE_SERVICE) && mvn clean package
	cd $(FORTUNE_SERVICE) && cf push $(APP_FORTUNE_SERVICE) -p target/$(APP_FORTUNE_SERVICE)-0.0.1-SNAPSHOT.jar -m 1G --random-route --no-start
	cf bind-service $(APP_FORTUNE_SERVICE) $(APP_CONFIG_SERVER)
	cf bind-service $(APP_FORTUNE_SERVICE) $(APP_SERVICE_REGISTRY)
	cf set-env $(APP_FORTUNE_SERVICE) TRUST_CERTS $$($(getFortuneUrl))
	cf start $(APP_FORTUNE_SERVICE)
# deploy_fortune_service

deploy_greeting_service:
	cd $(GREETING_SERVICE) && mvn clean package
	cd $(GREETING_SERVICE) && cf push $(APP_GREETING_SERVICE) -p target/$(APP_GREETING_SERVICE)-0.0.1-SNAPSHOT.jar -m 1G --random-route --no-start
	cf bind-service $(APP_GREETING_SERVICE) $(APP_CONFIG_SERVER)
	cf bind-service $(APP_GREETING_SERVICE) $(APP_SERVICE_REGISTRY)
	cf set-env $(APP_GREETING_SERVICE) TRUST_CERTS $$($(getGreetingUrl))
	cf start $(APP_GREETING_SERVICE)
# deploy_greeting_service

deploy_config_server:
	cf create-service p-config-server standard $(APP_CONFIG_SERVER) -c ./app.json
	$(call assertIsStarted,$(APP_CONFIG_SERVER))
# deploy_config_server

deploy_service_registry:
	cf create-service p-service-registry standard $(APP_SERVICE_REGISTRY)
	$(call assertIsStarted,$(APP_SERVICE_REGISTRY))
# deploy_service_registry

cleanup:
	cf delete $(APP_FORTUNE_SERVICE) -f
	cf delete $(APP_GREETING_SERVICE) -f
	cf delete-service $(APP_CONFIG_SERVER) -f
	cf delete-service $(APP_SERVICE_REGISTRY) -f
# cleanup

scale:
	cf scale $(APP_FORTUNE_SERVICE) -i 3
# scale

logs:
	cf logs $(APP_GREETING_SERVICE) | grep GreetingController
# logs

# Makefile
