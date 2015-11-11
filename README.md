A Sketch plugin that adjusts the character spacing on text layers using iOS 9's SF UI Text/Display fonts to what it would be when used in the app.

E.g. If you use SF UI Text at 16pt the script will set this layer's character spacing to -0.32.

### Why

When you use `-[UIFont systemFontOfSize:]` or other system font related API's in iOS, iOS automatically adjusts the font's tracking based on the point size you're using (see Tracking Table: https://developer.apple.com/fonts/ or check out WWDC session 804 "Introducing the New System Fonts"). Since this happens at an API level and not a font level, Sketch has no way of determining its default character spacing. Scripting it is better than doing it manually every time ¯\\_(ツ)_/¯.

Oddly enough official tracking table matches SF UI Text much better than SF UI Display. So SF UI Display's size to character spacing mapping is generated in a small iOS project.

### How

Just select the text layers that have SF UI Text/Display fonts being used and run the script (Plugins > Fix SF UI Font Character Spacing), it will set the correct spacing based on the current font size. If you change that layer's font size you will need to re-run the script on that layer.

### Keyboard Shortcut

`⌃⌘T`. (Ctrl+Cmd+T) If you want it to be something different you can technically edit the `manifest.json` file in the plugin.
