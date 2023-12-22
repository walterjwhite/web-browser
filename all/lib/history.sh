_export_history() {
	if [ -z "$_SQLITE_DATABASE" ]; then
		return
	fi

	if [ -n "$_ORIGINAL_HOME" ]; then
		HOME=$_ORIGINAL_HOME
	fi

	_HISTORY_FILE=$_CONF_INSTALL_APPLICATION_DATA_PATH/history/$_CONF_WEB_BROWSER_BROWSER-$_CONF_INSTALL_CONTEXT/$(date "+%Y%m%d%H%M%S")
	_info "$_CONF_INSTALL_CONTEXT browser history >$_HISTORY_FILE"

	mkdir -p $(dirname $_HISTORY_FILE)
	sqlite3 -csv $_SQLITE_DATABASE "$_QUERY" | tr -d '"' >$_HISTORY_FILE 2>&1

	if [ $(wc -l $_HISTORY_FILE | awk {'print$1'}) -gt 0 ]; then
		_git_save "$_CONF_INSTALL_CONTEXT" $_HISTORY_FILE
	else
		_warn "Pruning empty history: $_HISTORY_FILE"
		rm -f $_HISTORY_FILE
	fi
}

_save_history() {
	if [ -n "$_SAVE_BROWSER_HISTORY_WITH_PROXY" ]; then
		return
	fi

	_continue_if "Save Browser History?" "N/y" || {
		_SAVE_BROWSER_HISTORY_WITH_PROXY=1
		_warn "Not saving browser history"
		unset _SQLITE_DATABASE
		return
	}

	_info "Saving browser history"
}
