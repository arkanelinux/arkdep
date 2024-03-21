# Add plank to system-wide autostart, it is done system-wide to ensure Plank starts
# in case the user switches between variants
cp -v $workdir/usr/share/applications/plank.desktop \
	$workdir/etc/xdg/autostart \
	|| cleanup_and_quit 'Failed to copy plank.desktop to xdg autostart'
