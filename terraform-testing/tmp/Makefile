retrieve:
	@if [ -z "$(ARTIFACT)" ]; then \
		if [ -z "$(CURATOR_ARTIFACT)" ]; then \
			echo "Please provide ARTIFACT=value or set CURATOR_ARTIFACT environment variable"; \
			exit 1; \
		else \
			TARGET_ARTIFACT="$$CURATOR_ARTIFACT"; \
		fi; \
	else \
		TARGET_ARTIFACT="$(ARTIFACT)"; \
	fi; \
	echo "Retrieving Artifact: $$TARGET_ARTIFACT"; \
	curl -o policies.tar.gz "$(ARTIFACTORY_URL)/$(ARCHIVE_REPO)/$(ARCHIVE_GROUP_ID)/$(ARCHIVE_BRANCH)/$$TARGET_ARTIFACT" --insecure
	$(MAKE) extract
	@echo "Retrieval of $(TARGET_ARTIFACT) successful"

extract:
	tar -xvf policies.tar.gz || tar -xvf ../$(CURATOR_ARTIFACT)

plan:
	terraform init
	terraform validate
	terraform show
	terraform plan -var-file=${TARGET_ENV}/terraform.tfvars.json -out tf.plan -no-color
	terraform show -json tf.plan > tfplan.json

apply:
	terraform apply -auto-approve tf.plan

destroy:
	terraform destroy -var-file=${TARGET_ENV}/terraform.tfvars.json -auto-approve

clean:
	rm -rf .terraform tf.plan tfplan.json policies.tar.gz
