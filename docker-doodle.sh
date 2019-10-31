#!/bin/sh

set -e

script_basename="$(basename "${0}")"
plugin_name="${script_basename%.*}"
plugin_image="pdevine/halloween2019:latest"
plugin_ns="com.thajeztah.${plugin_name}"
plugin_usage="$(echo "${plugin_name}" | tr - ' ')"
plugin_description="Docker Doodles  all around! 🐳 🎃"

docker_cli_plugin_metadata() {
	vendor="thaJeztah"
	version="v0.0.1"
	url="https://gist.github.com/thaJeztah/262414a9730271bef76b303ad0463bd0"
	cat <<-EOF
	{"SchemaVersion":"0.1.0","Vendor":"${vendor}","Version":"${version}","ShortDescription":"${plugin_description}","URL":"${url}"}
EOF
}

print_help() {
	cat <<-EOF
Usage:	${plugin_usage} MESSAGE

${plugin_description}

Examples

  \$ ${plugin_usage}

Commands:

  uninstall   Uninstall the ${plugin_usage} plugin

Options

  --help  Print usage information and exit

Special thanks to Patrick Devine for creating the Halloween Doodle!
EOF
}

clean_containers() {
	ids=$(docker container ls -aq --filter label="${plugin_ns}")
	if [ -n "${ids}" ]; then
		# shellcheck disable=SC2086
		docker container rm -f ${ids} > /dev/null
	fi
}

clean_images() {
	ids=$(docker image ls -aq --filter label="${plugin_ns}")
	if [ -n "${ids}" ]; then
		# shellcheck disable=SC2086
		docker image rm -f ${ids} > /dev/null
	fi
}

imageid() {
	: "${1?USAGE: imageid IMAGE}"
	docker image inspect --format '{{ .Id }}' "${1}" 2> /dev/null
}

ensure_image() {
	[ -n "$(imageid "${plugin_image}")" ] && return
	docker pull -q "${plugin_image}" > /dev/null
}

install_plugin() {
	printf "Install plugin '%s' ? [Y/n] " "${plugin_usage}"
	read -r say_yes
	[ "${say_yes}" = "n" ] && exit 0
	mkdir -p ~/.docker/cli-plugins
	abs_path="$(cd "$(dirname "${0}")" && pwd)/$(basename "${0}")"
	cp "${abs_path}" ~/.docker/cli-plugins/"${plugin_name}"
	chmod +x ~/.docker/cli-plugins/"${plugin_name}"
}

uninstall_plugin() {
	printf "Uninstall plugin '%s' ? [y/N] " "${plugin_usage}"
	read -r say_yes
	[ "${say_yes}" = "" ] && exit 0
	clean_containers
	clean_images
	rm ~/.docker/cli-plugins/"${plugin_name}"
	echo "Successfully uninstalled plugin"
}

install_doodle() {
	install_plugin
	ensure_image
	print_help
}

doodle() {
	ensure_image
	exec docker container run \
		-it \
		--rm \
		--label "${plugin_ns}"=container \
		"${plugin_image}"
}

case "$1" in
	docker-cli-plugin-metadata)
		docker_cli_plugin_metadata
		;;
	doodle)
		shift
		case "$1" in
			uninstall)
				uninstall_plugin
				;;
			--help)
				print_help
				exit 0
				;;
			*)
				doodle
				;;
		esac
		;;
	*)
		install_doodle
		;;
esac
