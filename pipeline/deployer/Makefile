ARTIFACT     ?= $(CURATOR_ARTIFACT)
ARTIFACT_URL := $(ARTIFACTORY_URL)/$(ARCHIVE_REPO)/$(ARCHIVE_GROUP_ID)/$(ARCHIVE_BRANCH)/$(ARTIFACT)

.PHONY: retrieve extract print-env

print-env:
	@echo "============== build env =============="
	@echo " BRANCH_NAME       = $(BRANCH_NAME)"
	@echo " CHANGE_ID         = $(CHANGE_ID)"
	@echo " CHANGE_TARGET     = $(CHANGE_TARGET)"
	@echo " TARGET_BRANCH     = $(TARGET_BRANCH)"
	@echo " ARCHIVE_BRANCH    = $(ARCHIVE_BRANCH)"
	@echo " ARCHIVE_REPO      = $(ARCHIVE_REPO)"
	@echo " ARCHIVE_GROUP_ID  = $(ARCHIVE_GROUP_ID)"
	@echo " ARTIFACTORY_URL   = $(ARTIFACTORY_URL)"
	@echo " ARTIFACTORY_TOKEN = $(if $(ARTIFACTORY_TOKEN),(set),(UNSET))"
	@echo " CURATOR_ARTIFACT  = $(CURATOR_ARTIFACT)"
	@echo " ARTIFACT          = $(ARTIFACT)"
	@echo " ARTIFACT_URL      = $(ARTIFACT_URL)"
	@echo " pwd               = $$(pwd)"
	@echo "======================================="

retrieve: print-env
	@: $(if $(ARTIFACT),,$(error Set ARTIFACT=... or export CURATOR_ARTIFACT))
	curl --insecure --fail --show-error -o policies.tar.gz "$(ARTIFACT_URL)"
	$(MAKE) extract ARCHIVE=policies.tar.gz
	@echo "Retrieval of $(ARTIFACT) succesful"

extract: print-env
	@set -e; \
	archive="$(ARCHIVE)"; \
	if [ -z "$$archive" ]; then \
		if [ -f policies.tar.gz ]; then archive=policies.tar.gz; \
		elif [ -f ../$(CURATOR_ARTIFACT) ]; then archive=../$(CURATOR_ARTIFACT); \
		else echo "ERROR: no archive found (policies.tar.gz or ../$(CURATOR_ARTIFACT))"; exit 1; \
		fi; \
	fi; \
	if [ ! -s "$$archive" ]; then echo "ERROR: archive $$archive is missing or empty"; exit 1; fi; \
	case "$$(file -b --mime-type "$$archive" 2>/dev/null)" in \
		application/gzip|application/x-gzip|application/x-tar) ;; \
		*) echo "ERROR: $$archive is not a tar/gzip file (got $$(file -b "$$archive"))"; head -c 200 "$$archive"; echo; exit 1 ;; \
	esac; \
	tar -xf "$$archive"; \
	archived=$$(tar -tf "$$archive" | wc -l); \
	yml_count=$$(find . \( -name '*.yml' -o -name '*.yaml' \) -type f | wc -l); \
	echo "------------------------------------------------------------"; \
	echo " Extraction summary"; \
	echo "   archive        : $$archive ($$(du -h "$$archive" | cut -f1), mtime $$(date -r "$$archive" '+%Y-%m-%d %H:%M:%S'))"; \
	echo "   extracted into : $$(pwd)"; \
	echo "   files in tar   : $$archived"; \
	echo "   yml policies   : $$yml_count"; \
	echo "   top-level      :"; \
	ls -1 | sed 's/^/      /'; \
	echo "------------------------------------------------------------"; \
	if [ "$$yml_count" -eq 0 ]; then echo "ERROR: no yml policy files present after extract — terraform will see no policies and plan to destroy everything"; exit 1; fi