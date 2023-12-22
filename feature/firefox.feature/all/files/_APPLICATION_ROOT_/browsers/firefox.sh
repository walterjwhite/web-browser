BROWSER_CMD=firefox

_browser_new_instance() {
	_info "Copying profile to $_INSTANCE_DIRECTORY"

	mkdir -p $_INSTANCE_DIRECTORY

	tar cp - -C ~/ --exclude bookmarkbackups --exclude datareporting --exclude security_state --exclude sessionstore-backups --exclude settings/data.safe.bin --exclude storage --exclude weave --exclude .parentlock --exclude favicons.sqlite --exclude formhistory.sqlite --exclude key4.db --exclude lock --exclude permissions.sqlite --exclude places.sqlite .mozilla | tar xp - -C $_INSTANCE_DIRECTORY

	_info "Updating conf to use new instance dir"
	local home_directory_sed_safe=$(_sed_safe $HOME)
	local instance_dir_sed_safe=$(_sed_safe $_INSTANCE_DIRECTORY)

	find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_INSTALL_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +

	_SQLITE_DATABASE=$_INSTANCE_DIRECTORY/.mozilla/firefox/rcsf1nmn.default-release/places.sqlite
	_QUERY="SELECT url,ROUND(last_visit_date / 1000000) FROM moz_places WHERE VISIT_COUNT > 0 ORDER BY last_visit_date DESC"
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
