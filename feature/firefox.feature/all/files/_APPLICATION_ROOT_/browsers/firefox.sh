import git:git/github.sh

BROWSER_CMD=firefox

_browser_new_instance() {
	_info "Copying profile to $_INSTANCE_DIRECTORY"

	mkdir -p $_INSTANCE_DIRECTORY

	tar cp - -C ~/ .mozilla | tar xp - -C $_INSTANCE_DIRECTORY

	_info "Updating conf to use new instance dir"
	local home_directory_sed_safe=$(_sed_safe $HOME)
	local instance_dir_sed_safe=$(_sed_safe $_INSTANCE_DIRECTORY)

	find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_INSTALL_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +

	_QUERY="SELECT url,ROUND(last_visit_date / 1000000) FROM moz_places WHERE VISIT_COUNT > 0 ORDER BY last_visit_date DESC"

	_browser_extensions
}

_history_file() {
	_SQLITE_DATABASE=$(find $_INSTANCE_DIRECTORY -type f -name 'places.sqlite')
	[ $_SQLITE_DATABASE ] || _error "Error locating places database"
}

_browser_remote_debug() {
	if [ $_WEB_BROWSER_REMOTE_DEBUG -gt 0 ]; then
		_browser_add_args --remote-debugging-port=$_WEB_BROWSER_REMOTE_DEBUG
	else
		_browser_add_args --remote-debugging-port
	fi

	[ "$_WEB_BROWSER_HEADLESS" ] && _browser_add_args --headless
}

_browser_private_window() {
	_browser_add_args --private-window
	_browser_add_args "--new-instance"
}

_browser_http_proxy() {
	http_proxy=$_WEB_BROWSER_HTTP_PROXY
	https_proxy=$_WEB_BROWSER_HTTP_PROXY

	_browser_add_args "--new-instance"
}

_browser_socks_proxy() {
	local user_pref_file=$(find $_INSTANCE_DIRECTORY -type f -name prefs.js -print -quit)

	_require_file $user_pref_file 'Firefox user pref.js'

	local socks_host="${_WEB_BROWSER_SOCKS_PROXY%%:*}"
	local socks_port="${_WEB_BROWSER_SOCKS_PROXY#*:}"

	printf 'user_pref("network.proxy.socks", "%s");\n' "$socks_host" >>$user_pref_file
	printf 'user_pref("network.proxy.socks_port", %s);\n' "$socks_port" >>$user_pref_file
	printf 'user_pref("network.proxy.type", 1);\n' >>$user_pref_file

	_browser_add_args "--new-instance"
}

_browser_extensions() {
	_FIREFOX_EXTENSION_PATH=$(find $_INSTANCE_DIRECTORY/.mozilla/firefox -type d -depth 1 -print -quit)/extensions
	rm -rf $_FIREFOX_EXTENSION_PATH && mkdir -p $_FIREFOX_EXTENSION_PATH

	_info "Installing extensions to: $_FIREFOX_EXTENSION_PATH"

	local extension_name
	for extension_name in $(cat $_INSTANCE_DIRECTORY/.mozilla/extensions 2>/dev/null); do
		_browser_extension $extension_name
	done
}

_browser_extension() {
	case $1 in
	browserpass@maximbaz.com)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4187654/browserpass_ce-3.8.0.xpi
		;;
	firefox@ghostery.com)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4207768/ghostery-8.12.5.xpi
		;;
	passff@invicem.pro)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4202971/passff-1.16.xpi
		;;
	uBlock0@raymondhill.net)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4198829/ublock_origin-1.54.0.xpi
		;;
	jid1-ZAdIEUB7XOzOJw@jetpack)
		_browser_extension_load $1 https://addons.mozilla.org/firefox/downloads/file/4205925/duckduckgo_for_firefox-2023.12.6.xpi
		;;
	*)
		_warn "Unsupported extension: $1"
		continue
		;;
	esac
}

_browser_extension_load() {
	_download $2

	_detail "Copying $_DOWNLOADED_FILE -> $_FIREFOX_EXTENSION_PATH/$1.xpi"
	cp $_DOWNLOADED_FILE $_FIREFOX_EXTENSION_PATH/$1.xpi
}
