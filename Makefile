# Mivio Roku - build and side-load helpers.
#
# Configuration comes from the environment or an optional .env file:
#   ROKU_DEV_TARGET   - IP address of a Roku device in Developer Mode
#   ROKU_DEV_PASSWORD - developer password configured on the device
#
# Usage:
#   make zip       Build out/mivio.zip (manifest at zip root)
#   make install   Zip and side-load onto $(ROKU_DEV_TARGET)
#   make remove    Remove the side-loaded channel from the device
#   make clean     Delete build output

-include .env
export

APP_NAME  ?= mivio
OUT_DIR   ?= out
ZIP_FILE  := $(OUT_DIR)/$(APP_NAME).zip
APP_FILES := manifest source components images

.PHONY: zip install remove clean check-env

zip:
	@mkdir -p $(OUT_DIR)
	@rm -f $(ZIP_FILE)
	zip -9 -r $(ZIP_FILE) $(APP_FILES) -x "*.DS_Store" -x "*/.gitkeep" -x ".gitkeep"
	@echo "Created $(ZIP_FILE)"

install: check-env zip
	@echo "Installing on $(ROKU_DEV_TARGET) ..."
	@curl --user "rokudev:$(ROKU_DEV_PASSWORD)" --digest --silent --show-error \
		--connect-timeout 10 \
		-F "mysubmit=Install" -F "archive=@$(ZIP_FILE)" \
		"http://$(ROKU_DEV_TARGET)/plugin_install" \
		| grep -o "Identical to previous version[^<]*\|Install Success[^<]*\|Install Failure[^<]*\|Compilation Error[^<]*" \
		|| echo "Install request sent (no status text found in device response)."

remove: check-env
	@echo "Removing channel from $(ROKU_DEV_TARGET) ..."
	@curl --user "rokudev:$(ROKU_DEV_PASSWORD)" --digest --silent --show-error \
		--connect-timeout 10 \
		-F "mysubmit=Delete" -F "archive=" \
		"http://$(ROKU_DEV_TARGET)/plugin_install" > /dev/null
	@echo "Done."

clean:
	rm -rf $(OUT_DIR)

check-env:
ifndef ROKU_DEV_TARGET
	$(error ROKU_DEV_TARGET is not set. Export it or add it to a .env file (see .env.example))
endif
ifndef ROKU_DEV_PASSWORD
	$(error ROKU_DEV_PASSWORD is not set. Export it or add it to a .env file (see .env.example))
endif
