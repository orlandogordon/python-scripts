-include .env
export

CURATOR_ARTIFACT ?=
ARCHIVE_BRANCH   ?= $(TARGET_BRANCH)
TARGET_BRANCH    ?= $(BRANCH_NAME)

DEPLOYER_DIR := deployer 

deployer-retrieve:
ifndef SKIP_RETRIEVE
	$(MAKE) -C $(DEPLOYER_DIR) retrieve
else
	@echo skipping retrieval of curator object 
	$(MAKE) -C $(DEPLOYER_DIR) extract
endif

ci-publish:
	@set -e; \
	code = $$($(CURL) -w "%{http_code}" -o response.json -T $(CURATOR_ARTIFACT) \
	-k \
	-H "Authorization: Bearer $(ARTIFACTORY_TOKEN)" \
	-v $(ARTIFACTORY_URL)/$(ARCHIVE_REPO)/$(ARCHIVE_GROUP_ID)/$(ARCHIVE_BRANCH)/$(CURATOR_ARTIFACT)); \
	if ["$$code" -ge 200 ] && ["$$code" -lt 400]; then \
		echo "Publishing of $(CURATOR_ARTIFACT) succesful"; \
	elif [ "$$code" -eq 403 ]; then \
		echo "WARNING: Publishing shows error 403. This is likely due to the artifact already existing!"; \
		echo "SKIP_RETRIEVE=true" >> .env; \
	else \
		echo "Publishing of artifact failed with status $$code"; \
		exit 1; \
	fi