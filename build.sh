#!/bin/bash

#############################################################################
# Copyright (c) 2010, 2011 Obeo.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# 
# Contributors:
#     Mikaël Barbero - initial API and implementation
#############################################################################

##
# publish and categorize metadata and artifacts in a single repository of builded set of features/plugins
#
# Usage: publishRepository path/to/builded/feature/and/plugins /absolute/path/to/metadata/and/artifact/repository
#
function publishRepositories {
	EQUINOX_LAUNCHER=tools/p2-publishers-3.6.1/plugins/org.eclipse.equinox.launcher_1.1.0.v20100507.jar
	SOURCE=$1
	REPOSITORY_LOCATION=file:$2

	echo "Publishing features and bundles into repositories $2..."
	# publish features and bundles
	java -jar $EQUINOX_LAUNCHER -application org.eclipse.equinox.p2.publisher.FeaturesAndBundlesPublisher \
	   -metadataRepository $REPOSITORY_LOCATION \
	   -metadataRepositoryName "guava-osgi metadata repository" \
	   -artifactRepository $REPOSITORY_LOCATION \
	   -artifactRepositoryName "guava-osgi artifact repository" \
	   -source $SOURCE \
	   -compress \
	   -publishArtifacts  > /dev/null

	# categorize
	CATEGORY_FILE=/tmp/category.xml

	buildCategoryXML repository/features $CATEGORY_FILE

	echo "Categorizing metadata repository $2..."
	java -jar $EQUINOX_LAUNCHER -application -application org.eclipse.equinox.p2.publisher.CategoryPublisher \
	   -metadataRepository $REPOSITORY_LOCATION \
	   -categoryDefinition file:/$CATEGORY_FILE \
	   -compress > /dev/null

	rm -rf $CATEGORY_FILE
}

##
# Creates a category.xml 
# 
# Usage: buildCategory path/to/features/folder path/to/category.xml
#
function buildCategoryXML {
	FEATURES_FOLDER=$1
	CATEGORY_XML=$2
	
	echo '<?xml version="1.0" encoding="UTF-8"?>' > $CATEGORY_XML
	echo '<site>' >> $CATEGORY_XML

	for feature in `ls $FEATURES_FOLDER`
		do
			featureId=`echo $feature | cut -d _ -f1`
			featureVersion=`echo $feature | cut -d _ -f2 | sed -e "s/.jar//g"`
			echo '  <feature url="features/'$feature'" id="'$featureId'" version="'$featureVersion'">' >> $CATEGORY_XML
			echo '    <category name="com.google.guava"/>' >> $CATEGORY_XML
			echo '  </feature>' >> $CATEGORY_XML
	done

	echo '  <category-def name="com.google.guava" label="Guava: Google Core Libraries for Java 1.5"/>' >> $CATEGORY_XML
	echo '</site>' >> $CATEGORY_XML
}

##
# checks that new downloads are necessary (by checking $1 file)
#
# Usage: downloadLatestReleases path/to/SHA1SUM path/to/urls/list path/to/prefix/download/folder
#
function downloadLatestReleases {
	SUMFILE=$1
	URLS_LIST=$2
	PREFIX_FOLDER=$3
	sha1sum --status -c $SUMFILE 2> /dev/null
	if [ $? -ne 0 ]; then
		echo "Downloading all guava releases..."
		rm -f $PREFIX_FOLDER/*
		wget -U "Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.215 Safari/534.10" -nv -P guava-releases -i guava-releases.list
		echo "Checking downloaded files..."
		sha1sum --quiet -c $SUMFILE
		if [ $? -ne 0 ]; then
			exit -1
		fi
	else
		echo "Folder $PREFIX_FOLDER contains all guava releases as listed in $SUMFILE"
	fi
}

function replace {
	FILE=$1
	FROM=$2
	TO=$3
	sed -i "s/$FROM/$TO/g" $FILE
}

##
# Build a release from a given release archive
# 
# Usage: buildRelease guava-release/guava-r05.zip path/to/plugins/and/features/folder
#
function buildRelease {
	ZIP_FILE=$1
	VERSION_RAW=`basename $1 | sed -e "s/guava-r\([0-9]*\).zip/\1/g"`
	VERSION_ZERO_TRIMMED=`echo $VERSION_RAW | sed -e "s/^0*//g"`
	VERSION=$VERSION_ZERO_TRIMMED.0.0
	RELEASE_TAG=release$VERSION_RAW
	RELEASE_NAME=guava-r$VERSION_RAW
	BUNDLE_TARGET_BUILD_PATH=/tmp/bundle_guava-r$VERSION_RAW
	UNZIP_FOLDER=/tmp/$RELEASE_NAME
	BUILD_PATH=$2

	echo -n "Building OSGi bundle of $RELEASE_NAME..."

	rm -rf $BUNDLE_TARGET_BUILD_PATH
	mkdir $BUNDLE_TARGET_BUILD_PATH

	cp -Rf templates/* $BUNDLE_TARGET_BUILD_PATH
	find $BUNDLE_TARGET_BUILD_PATH/ -name .svn  | xargs rm -rf

	unzip -qq -o $ZIP_FILE -d /tmp
	unzip -qq -o $UNZIP_FOLDER/guava-r$VERSION_RAW.jar -d $UNZIP_FOLDER/bin
	unzip -qq -o $UNZIP_FOLDER/guava-src-r$VERSION_RAW.zip -d $UNZIP_FOLDER/src

	cp -Rf $UNZIP_FOLDER/bin/com $BUNDLE_TARGET_BUILD_PATH/com.google.guava/
	cp -Rf $UNZIP_FOLDER/src/com $BUNDLE_TARGET_BUILD_PATH/com.google.guava.source/
	cp -Rf $UNZIP_FOLDER/javadoc $BUNDLE_TARGET_BUILD_PATH/com.google.guava.source/
	cp $UNZIP_FOLDER/README $BUNDLE_TARGET_BUILD_PATH/com.google.guava.source/about_files
	cp $UNZIP_FOLDER/README $BUNDLE_TARGET_BUILD_PATH/com.google.guava/about_files

	declare -a allExternalPackages
	declare -a allInternalPackages

	allExternalPackages=(`find $UNZIP_FOLDER/ -name "*.java" -exec grep "^package.*" {} \; | sort | uniq | sed 's/package //' | sed 's/;//' | grep -v internal`)
	allInternalPackages=(`find $UNZIP_FOLDER/ -name "*.java" -exec grep "^package.*" {} \; | sort | uniq | sed 's/package //' | sed 's/;//' | grep internal`)

	MANIFEST=$BUNDLE_TARGET_BUILD_PATH/com.google.guava/META-INF/MANIFEST.MF
	replace $MANIFEST "#VERSION#" $VERSION
	echo -n "Export-Package:" >> $MANIFEST
	for element in $(seq 0 $((${#allExternalPackages[@]} - 1)))
		do                
		echo -n " ${allExternalPackages[$element]};version=\"$VERSION\"" >> $MANIFEST
		if [ $element -lt $((${#allExternalPackages[@]} - 1)) ]; then
			echo "," >> $MANIFEST
		fi
	done
	if [ ${#allExternalPackages[@]} -gt 0 ]; then
		if [ ${#allInternalPackages[@]} -gt 0 ]; then
			echo "," >> $MANIFEST
		fi
	fi
	for element in $(seq 0 $((${#allInternalPackages[@]} - 1)))
		do
		echo -n " ${allInternalPackages[$element]};version=\"$VERSION\";x-internal:=true" >> $MANIFEST
		if [ $element -lt $((${#allInternalPackages[@]} - 1)) ]; then
			echo "," >> $MANIFEST
		fi
	done
	echo "" >> $MANIFEST
	echo "" >> $MANIFEST

	replace $BUNDLE_TARGET_BUILD_PATH/com.google.guava.source/META-INF/MANIFEST.MF "#VERSION#" $VERSION
	replace $BUNDLE_TARGET_BUILD_PATH/com.google.guava.source/about.html "#VERSION#" $VERSION_RAW
	replace $BUNDLE_TARGET_BUILD_PATH/com.google.guava/about.html "#VERSION#" $VERSION_RAW
	replace $BUNDLE_TARGET_BUILD_PATH/com.google.guava.runtime.feature/feature.xml "#VERSION#" $VERSION
	replace $BUNDLE_TARGET_BUILD_PATH/com.google.guava.runtime.feature/feature.xml "#RELEASE_TAG#" $RELEASE_TAG
	replace $BUNDLE_TARGET_BUILD_PATH/com.google.guava.sdk.feature/feature.xml "#VERSION#" $VERSION
	replace $BUNDLE_TARGET_BUILD_PATH/com.google.guava.sdk.feature/feature.xml "#RELEASE_TAG#" $RELEASE_TAG

	rm -rf $UNZIP_FOLDER

	jar -cmf $BUNDLE_TARGET_BUILD_PATH/com.google.guava/META-INF/MANIFEST.MF $BUILD_PATH/plugins/com.google.guava_$VERSION.jar -C $BUNDLE_TARGET_BUILD_PATH/com.google.guava .
	jar -cmf $BUNDLE_TARGET_BUILD_PATH/com.google.guava.source/META-INF/MANIFEST.MF $BUILD_PATH/plugins/com.google.guava.source_$VERSION.jar -C $BUNDLE_TARGET_BUILD_PATH/com.google.guava.source .

	cp -Rf $BUNDLE_TARGET_BUILD_PATH/com.google.guava.runtime.feature $BUILD_PATH/features/com.google.guava.runtime.feature_$VERSION
	cp -Rf $BUNDLE_TARGET_BUILD_PATH/com.google.guava.sdk.feature $BUILD_PATH/features/com.google.guava.sdk.feature_$VERSION

	cp templates/pom.xml $BUNDLE_TARGET_BUILD_PATH/pom-$VERSION.xml
	replace $BUNDLE_TARGET_BUILD_PATH/pom-$VERSION.xml "#VERSION#" $VERSION

	gpg -ab $BUNDLE_TARGET_BUILD_PATH/pom-$VERSION.xml
	gpg -ab $BUILD_PATH/plugins/com.google.guava_$VERSION.jar

	mvn deploy:deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-snapshots -Dfile=$BUILD_PATH/plugins/com.google.guava_$VERSION.jar -DpomFile=$BUNDLE_TARGET_BUILD_PATH/pom-$VERSION.xml

	mvn deploy:deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-snapshots -Dpackaging=pom.asc -Dfile=$BUNDLE_TARGET_BUILD_PATH/pom-$VERSION.xml.asc -DpomFile=$BUNDLE_TARGET_BUILD_PATH/pom-$VERSION.xml

	mvn deploy:deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-snapshots -Dpackaging=jar.asc -Dfile=$BUILD_PATH/plugins/com.google.guava_$VERSION.jar.asc -DpomFile=$BUNDLE_TARGET_BUILD_PATH/pom-$VERSION.xml

	rm -rf $BUNDLE_TARGET_BUILD_PATH

	echo ""
}

####################################################################
# Main part
####################################################################

# configurable part
GUAVA_RELEASES_FOLDER=guava-releases
TEMPORARY_BUILD_FOLDER=/tmp/buildedRepository
TARGET_REPOSITORY_PATH=repository

mkdir -p $GUAVA_RELEASES_FOLDER
downloadLatestReleases ./SHA1SUM ./guava-releases.list $GUAVA_RELEASES_FOLDER

mkdir -p $TEMPORARY_BUILD_FOLDER/features
mkdir -p $TEMPORARY_BUILD_FOLDER/plugins

for releaseFile in `ls $GUAVA_RELEASES_FOLDER`
	do  
		buildRelease "$GUAVA_RELEASES_FOLDER/$releaseFile" $TEMPORARY_BUILD_FOLDER
done

rm -rf $TARGET_REPOSITORY_PATH/*.jar
rm -rf $TARGET_REPOSITORY_PATH/plugins/*.jar
rm -rf $TARGET_REPOSITORY_PATH/features/*.jar

publishRepositories $TEMPORARY_BUILD_FOLDER `readlink -f $TARGET_REPOSITORY_PATH`

rm -rf $TEMPORARY_BUILD_FOLDER

echo "Done."
exit 0

