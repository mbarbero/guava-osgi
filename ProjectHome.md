## This project is no longer updated now that the Guava's Team has taken responsibility for releasing an OSGi bundle since 12.0.0. For versions later than 12, go to https://code.google.com/p/guava-libraries/ ##

Update Site URL: http://guava-osgi.googlecode.com/svn/trunk/repository/

This is a repackaging of the [Guava](http://guava-libraries.googlecode.com) project, which hosts some of Google's core Java libraries, as an OSGi bundle for you to use in your Eclipse projects!

The update site provides SDK (with sources and Javadoc) and Runtime (binary only) features for the following releases:
  * [guava-r11.0.1](http://code.google.com/p/guava-libraries/wiki/Release11)
  * [guava-r11](http://code.google.com/p/guava-libraries/wiki/Release11)
  * [guava-r10.0.1](http://code.google.com/p/guava-libraries/wiki/Release10)
  * [guava-r10](http://code.google.com/p/guava-libraries/wiki/Release10)
  * [guava-r09](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r09.zip)
  * [guava-r08](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r08.zip)
  * [guava-r07](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r07.zip)
  * [guava-r06](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r06.zip)
  * [guava-r05](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r05.zip)
  * [guava-r04](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r04.zip)
  * [guava-r03](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r03.zip)

The bundles are available within the p2 repository linked above and from the [Sonatype OSS Maven repository](https://oss.sonatype.org/content/repositories/releases/):

```
  <groupId>com.googlecode.guava-osgi</groupId>
  <artifactId>guava-osgi</artifactId>
  <name>Guava-OSGi</name>
  <version>X.0.0</version>
```

### News ###
  * **2012-02-04**: added guava-[r11](https://code.google.com/p/guava-osgi/source/detail?r=11).0.1 release. Available from Maven central and p2 repository.
  * **2011-12-28**: added guava-[r10](https://code.google.com/p/guava-osgi/source/detail?r=10).0.1 and guava-[r11](https://code.google.com/p/guava-osgi/source/detail?r=11) releases available from Maven central and p2 repository.
  * **2011-10-05**: added guava-[r10](https://code.google.com/p/guava-osgi/source/detail?r=10) release. Available from Sonatype OSS Maven repo and p2 repository.
  * **2011-04-22**: OSGi bundles has been deployed to [Sonatype OSS Maven repository](https://oss.sonatype.org/content/repositories/releases/).
  * **2011-04-09**: added guava-[r09](https://code.google.com/p/guava-osgi/source/detail?r=09) release.
  * **2011-01-28**: added guava-[r08](https://code.google.com/p/guava-osgi/source/detail?r=08) release.
  * **2011-01-25**: fresh new start of the project. Bundles are now automatically build from Guava releases. Build scripts come from the **deprecated** [guava-bundle](http://code.google.com/a/eclipselabs.org/p/guava-bundle/) project.

### Note ###

Guava follows a simple incremental numbering scheme for its release versionning. As OSGi needs a finest level of details for versionning, guava-bundle mapped this scheme as follow:

  * A Guava release **rX** where X is the integral version number of the release will be available in guava-bundle **X.0.0**

For instance, the **[r05](http://code.google.com/p/guava-libraries/downloads/detail?name=guava-r05.zip)** release is available in the bundle with version number **5.0.0**.

All OSGi metadata are synchronized with this version number mapping:

  * Bundles (aka plugins) versions,
  * Exported packages versions,
  * Features versions.