BROWSER_CMD=ungoogled-chromium

case $_PLATFORM in
Linux | FreeBSD)
	_CONFIGURATION_DIRECTORY=~/.config/ungoogled-chromium
	;;
*)
	_error "Unsupported platform: $_PLATFORM"
	;;
esac

_CONFIGURATION_DIRECTORY=~/.config/ungoogled-chromium

_browser_new_instance() {
	local chromium_instance_dir=$_INSTANCE_DIRECTORY/.config/ungoogled-chromium

	mkdir -p $chromium_instance_dir/Default

	if [ ! -e $_CONFIGURATION_DIRECTORY/Default/Preferences ]; then
		_error "$_CONFIGURATION_DIRECTORY/Default/Preferences does not exist" 1
	fi

	cp -R $_CONFIGURATION_DIRECTORY/Default/Preferences "$chromium_instance_dir/Default/"
	cp -R $_CONFIGURATION_DIRECTORY/Default/Extensions "$chromium_instance_dir/Default/" 2>/dev/null

	_info "Updating conf to use new instance dir"
	local home_directory_sed_safe=$(_sed_safe $HOME)
	local instance_dir_sed_safe=$(_sed_safe $chromium_instance_dir)

	find $_INSTANCE_DIRECTORY -type f ! -name '*.sqlite' -exec $_CONF_INSTALL_GNU_SED -i "s/$home_directory_sed_safe/$instance_dir_sed_safe/g" {} +

	mkdir -p $_INSTANCE_DIRECTORY/Downloads

	_SQLITE_DATABASE=$chromium_instance_dir/Default/History
	_QUERY="SELECT url,ROUND(LAST_VISIT_TIME/1000000) FROM urls WHERE url NOT LIKE 'chrome-extension://%' ORDER BY last_visit_time DESC"
}

_browser_remote_debug() {
	local remote_debug
	if [ $_WEB_BROWSER_REMOTE_DEBUG -gt 0 ]; then
		remote_debug="=$_WEB_BROWSER_REMOTE_DEBUG"
	fi

	_browser_add_args "--remote-debugging-port${remote_debug}"

	[ "$_WEB_BROWSER_HEADLESS" ] && _browser_add_args --headless
}

_browser_private_window() {
	_browser_add_args --incognito
}

_browser_http_proxy() {
	_browser_add_args "--proxy-server=http://${_WEB_BROWSER_HTTP_PROXY}"
}

_browser_socks_proxy() {
	_browser_add_args "--proxy-server=socks${_CONF_WEB_BROWSER_SOCKS_PROXY_VERSION}://$_WEB_BROWSER_SOCKS_PROXY"
}
