

SKETCH_DIR="$PROJECT_DIR"/"dcodetools"
IMAGES_ASSETS_DIR="$PROJECT_DIR"/"$PROJECT_NAME"/"Images.xcassets"
ICONS_DIR="$SKETCH_DIR"/"Icons"

APPICON_PATH="$SKETCH_DIR"/"AppIcon.sketch"
ICONS_PATH="$SKETCH_DIR"/"Icons.sketch"


function exportAppIcon()
{
	sketchtool export artboards \
		"$APPICON_PATH" \
		--output="$IMAGES_ASSETS_DIR"/AppIcon.appiconset \
		--formats="png"
}

function exportIcons()
{
	# export icon as pdf vector
	sketchtool export slices "$ICONS_PATH" \
	 	--output="$ICONS_DIR" \
	 	 --formats="pdf"

	# create assets to XCode
	cd $ICONS_DIR

	for file in *.pdf
		do

		fname=${file%%.*}
		
		# create imageset file
		assets_name="$fname".imageset
		icon_assets_dir="$IMAGES_ASSETS_DIR"/"$assets_name"
		createJSONwithAssetsName "$file"
		
		# copy imageset file to XCode
		mkdir -p "$icon_assets_dir"
		/bin/cp "$file" "$icon_assets_dir"/"$file"
		/bin/cp Contents.json "$icon_assets_dir"/Contents.json
	done

	cd $PROJECT_DIR

	# remove unused files
	rm -rf "$ICONS_DIR"
}

function createJSONwithAssetsName() 
{
cat << EOF > Contents.json
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "$1"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF
}


# sketch flow
exportAppIcon
exportIcons

