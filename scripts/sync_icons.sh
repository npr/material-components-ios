#!/bin/bash
#
# Copyright 2016-present the Material Components for iOS authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Sync icons from the https://github.com/google/material-design-icons.git GitHub repository to the
# components/private/Icons directory.
#
# Expectations:
#
# components/private/Icons/icons/ contains one folder for each icon that is intended to be copied
# from the material-design-icons repository.
#
# Example:
#
#     components/private/Icons/icons/
#       ic_arrow_back/
#       ic_menu/
#
# This script will generate the scaffolding required to add these icons to an app.
#
#     components/private/Icons/icons/ic_arrow_back/
#       src/
#         MaterialIcons_ic_arrow_back.bundle/
#             ic_arrow_back.png
#             ic_arrow_back@2x.png
#             ic_arrow_back@3x.png
#         MaterialIcons+ic_arrow_back.h
#         MaterialIcons+ic_arrow_back.m
#     components/private/Icons/icons/ic_menu/
#       src/
#         MaterialIcons_ic_menu.bundle/
#             ic_menu.png
#             ic_menu@2x.png
#             ic_menu@3x.png
#         MaterialIcons+ic_menu.h
#         MaterialIcons+ic_menu.m
#

# Compute directories relative to the script's known location in scripts/
SCRIPTS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT_PATH="$( cd "$( dirname $SCRIPTS_PATH )" && pwd )"

# Where to install the material-design-icons repo
ICONS_REPO_PATH="$SCRIPTS_PATH/external/material-design-icons"

ICONS_COMPONENT_RELATIVE_PATH="components/private/Icons"
ICONS_COMPONENT_PATH="$REPO_ROOT_PATH/$ICONS_COMPONENT_RELATIVE_PATH"

# Where the generated CocoaPods script lives
GENERATED_SCRIPTS_PATH="$REPO_ROOT_PATH/scripts/generated"
GENERATED_ICONS_SCRIPT_PATH="$GENERATED_SCRIPTS_PATH/icons.rb"

# Runs git commands in the material-design-icons repository directory.
git_icons() {
  pushd $ICONS_REPO_PATH >> /dev/null
  git "$@"
  popd >> /dev/null
}

echo "Fetching material-design-icons..."

if [ ! -d "$ICONS_REPO_PATH" ]; then
  git clone https://github.com/google/material-design-icons.git "$ICONS_REPO_PATH"
else
  git_icons fetch
fi

echo "Checking out origin/master..."
echo

git_icons checkout origin/master || { echo "Failed to update material-design-icons repo."; exit 1; }

mkdir -p "$GENERATED_SCRIPTS_PATH"

echo
echo "Enumerating icons..."

cat > "$GENERATED_ICONS_SCRIPT_PATH" <<EOL
# This file was automatically generated by running $0
# Do not modify directly.
def registerIcons(s)

  s.subspec "Icons" do |iss|
    iss.subspec "Base" do |ss|
      ss.public_header_files = "$ICONS_COMPONENT_RELATIVE_PATH/src/*.h"
      ss.source_files = "$ICONS_COMPONENT_RELATIVE_PATH/src/*.{h,m}"
    end
EOL

# Enumerate all desired icons...
for directory in $ICONS_COMPONENT_PATH/icons/*/; do
  icon_name=$(basename $directory)

  echo
  echo -n "$icon_name..."

  location=$(find "$ICONS_REPO_PATH" -name "$icon_name.imageset")

  if [ ! -d "$location" ]; then
    echo -n "Skipping due to missing $icon_name."
    continue
  fi

  assets_path="$directory/src/MaterialIcons_$icon_name.bundle"

  echo -n "copying..."

  mkdir -p "$assets_path"

  cp "$location"/*.png "$assets_path"

  # TODO(featherless): Simplify this _nx -> @nx remapping.
  for old in $assets_path/*_2x.png; do
    new=$(echo $old | sed -e 's/_2x\.png/@2x.png/')
    mv -v "$old" "$new" >> /dev/null
  done

  for old in $assets_path/*_3x.png; do
    new=$(echo $old | sed -e 's/_3x\.png/@3x.png/')
    mv -v "$old" "$new" >> /dev/null
  done

  echo -n "writing pod entry..."
  cat >> "$GENERATED_ICONS_SCRIPT_PATH" <<EOL

    iss.subspec "$icon_name" do |ss|
      ss.public_header_files = "$ICONS_COMPONENT_RELATIVE_PATH/icons/$icon_name/src/*.h"
      ss.source_files = "$ICONS_COMPONENT_RELATIVE_PATH/icons/$icon_name/src/*.{h,m}"
      ss.resource_bundles = {
        "MaterialIcons_$icon_name" => [
          "$ICONS_COMPONENT_RELATIVE_PATH/icons/$icon_name/src/MaterialIcons_$icon_name.bundle/*.png",
        ]
      }
      ss.dependency "#{Pathname.new(ss.name).dirname}/Base"
    end
EOL

  echo -n "creating source..."

  file="MaterialIcons+$icon_name"
  src_path="$ICONS_COMPONENT_RELATIVE_PATH/icons/$icon_name/src"

  mkdir -p "$src_path"

  header_file="$src_path/$file.h"

  # TODO(featherless): Find a more scalable way to inject these license headers. Possibly store the
  # license in a separate file and inject it here.
  cat > "$header_file" <<EOL
/*
 Copyright 2016-present the Material Components for iOS authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <UIKit/UIKit.h>

#import "MaterialIcons.h"

// This file was automatically generated by running $0
// Do not modify directly.

@interface MDCIcons ($icon_name)

/*
 Returns the path for the $icon_name image contained in
 MaterialIcons_$icon_name.bundle.
 */
+ (nonnull NSString *)pathFor_$icon_name;

@end
EOL

  cat > "$src_path/$file.m" <<EOL
/*
 Copyright 2016-present the Material Components for iOS authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

// This file was automatically generated by running $0
// Do not modify directly.

#import "$file.h"

#import "MDCIcons+BundleLoader.h"

static NSString *const kBundleName = @"MaterialIcons_$icon_name";
static NSString *const kIconName = @"$icon_name";

// Export a nonsense symbol to suppress a libtool warning when this is linked alone in a static lib.
__attribute__((visibility("default")))
    char MDCIconsExportToSuppressLibToolWarning_$icon_name = 0;

@implementation MDCIcons ($icon_name)

+ (nonnull NSString *)pathFor_$icon_name {
  return [self pathForIconName:kIconName withBundleName:kBundleName];
}

@end
EOL

  echo -n "done!"
done

cat >> "$GENERATED_ICONS_SCRIPT_PATH" <<EOL
  end
end
EOL

echo
echo
echo "Done!"

