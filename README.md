url router proof of concept (open specific url in particular browser)

How to run:

1. build it using xcode
2. export app: Window->Organizer->Archives->Distribute App->Custom->Copy App
3. put config to ~/Library/Containers/jintwo.Router/Data/Documents/router.json (symlinks not supported (yet)) or directly in app bundle (Router.app/Contents/Resources/config.json)

TODO:

1. ~~settings window + serialization~~
2. (!) config in ~/.router.json
3. goal: put in appstore
4. ~~feature: source application matching~~
5. BUG: validate regexp
